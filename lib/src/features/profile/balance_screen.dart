import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/post_auth_redirect.dart';

/// Саҳифаи баланс — монанди веб: нишон додани маблағ, пополнение SmartPay.
class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> with WidgetsBindingObserver {
  final _amountCtrl = TextEditingController();
  bool _loadingMe = true;
  bool _unauthorized = false;
  num? _balance;
  bool _paymentBusy = false;
  String _paymentError = '';
  String? _pendingOrderId;
  Timer? _pollTimer;

  static final _moneyFmt = NumberFormat('#,##0.00', 'ru_RU');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Deep link: /balance?payment=return&order_id=...
    final qp = GoRouterState.of(context).uri.queryParameters;
    final payment = qp['payment'];
    final oid = qp['order_id'];
    if (payment == 'return' && oid != null && oid.isNotEmpty && _pendingOrderId != oid) {
      setState(() => _pendingOrderId = oid);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPolling();
        _pollOrderStatus();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingOrderId != null) {
      _pollOrderStatus();
    }
  }

  Future<void> _loadMe() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _unauthorized = true;
        _loadingMe = false;
      });
      return;
    }
    setState(() {
      _loadingMe = true;
      _unauthorized = false;
    });
    try {
      final r = await dio.get('/api/auth/me/');
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final b = data['balance'];
      setState(() {
        _balance = b is num ? b : num.tryParse(b?.toString() ?? '');
        _loadingMe = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await setAccessToken(null);
      }
      setState(() {
        _unauthorized = e.response?.statusCode == 401;
        _loadingMe = false;
      });
    } catch (_) {
      setState(() => _loadingMe = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    var ticks = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      ticks++;
      if (ticks > 45 || _pendingOrderId == null) {
        t.cancel();
        return;
      }
      _pollOrderStatus();
    });
  }

  Future<void> _pollOrderStatus() async {
    final oid = _pendingOrderId;
    if (oid == null) return;
    try {
      final r = await dio.get('/api/auth/order/status/${Uri.encodeComponent(oid)}/');
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final status = (data['status'] ?? '').toString();
      final b = data['balance'];
      if (b is num) {
        setState(() => _balance = b);
      } else if (b != null) {
        final n = num.tryParse(b.toString());
        if (n != null) setState(() => _balance = n);
      }
      if (status == 'Charged' && mounted) {
        _pollTimer?.cancel();
        setState(() => _pendingOrderId = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Баланс пополнен')));
      }
    } catch (_) {
      // игнорируем временные сетевые ошибки при опросе
    }
  }

  Future<void> _goPay() async {
    // Не создаём новый инвойс, если есть незавершённая оплата.
    if (_pendingOrderId != null && _pendingOrderId!.trim().isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас уже есть незавершённая оплата. Ожидаем подтверждение…')),
        );
      }
      _startPolling();
      _pollOrderStatus();
      return;
    }
    final raw = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);
    if (amount == null || amount < 2) {
      setState(() => _paymentError = 'Минимум 2 сомони');
      return;
    }
    setState(() {
      _paymentError = '';
      _paymentBusy = true;
    });
    try {
      final r = await dio.post('/api/auth/payment/create/', data: {'amount': amount});
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final link = data['payment_link']?.toString();
      final orderId = data['order_id']?.toString();
      if (link == null || link.isEmpty) {
        setState(() => _paymentError = 'Ссылка на оплату не получена');
        return;
      }
      setState(() => _pendingOrderId = orderId);
      final uri = Uri.tryParse(link);
      if (uri == null) {
        setState(() => _paymentError = 'Некорректная ссылка');
        return;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        setState(() => _paymentError = 'Не удалось открыть оплату');
        return;
      }
      _startPolling();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Завершите оплату во внешнем окне. Баланс обновится автоматически.')),
        );
      }
    } on DioException catch (e) {
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      setState(() => _paymentError = err ?? 'Ошибка создания платежа');
    } catch (_) {
      setState(() => _paymentError = 'Ошибка создания платежа');
    } finally {
      if (mounted) setState(() => _paymentBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF171717) : Colors.white;
    final border = isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    const blue = Color(0xFF2563eb);
    const accent = Color(0xFFE79A3E);

    if (_unauthorized && !_loadingMe) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          title: const Text('Баланс'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 56, color: muted),
                const SizedBox(height: 16),
                Text('Войдите в профиль, чтобы видеть баланс и пополнять его.', textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 16)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
                  style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
                  child: const Text('Перейти в кабинет'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Баланс аккаунта'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _loadingMe ? null : _loadMe,
          ),
        ],
      ),
      body: _loadingMe
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pendingOrderId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Проверяем оплату…',
                              style: TextStyle(color: muted, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: blue, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _balance != null ? '${_moneyFmt.format(_balance)} с.' : '—',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text),
                              ),
                              const SizedBox(height: 4),
                              Text('Доступный баланс', style: TextStyle(fontSize: 13, color: muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Пополнить баланс (SmartPay)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
                        const SizedBox(height: 8),
                        Text(
                          'Минимум 2 сомони. Оплата картой или кошельком',
                          style: TextStyle(fontSize: 13, color: muted, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !_paymentBusy,
                          decoration: InputDecoration(
                            labelText: 'Сумма (сомони)',
                            hintText: 'Например, 50',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) {
                            if (_paymentError.isNotEmpty) setState(() => _paymentError = '');
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _paymentBusy ? null : _goPay,
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_paymentBusy ? '…' : 'Перейти к оплате'),
                          ),
                        ),
                        if (_paymentError.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(_paymentError, style: const TextStyle(color: Color(0xFFef4444), fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пополнение баланса и списания за услуги будут отображаться здесь (история операций добавим позже).',
                    style: TextStyle(fontSize: 13, color: muted, height: 1.45),
                  ),
                ],
              ),
            ),
    );
  }
}
