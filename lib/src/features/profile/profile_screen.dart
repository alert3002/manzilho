import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/favorites_count_provider.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/post_auth_redirect.dart';
import '../../core/push_notifications.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  // auth flow
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _sendingCode = false;
  bool _verifying = false;
  bool _codeSent = false;
  bool _needsRegistration = false;
  String _normalizedPhone = '';
  Timer? _resendCooldownTimer;
  int _resendSecondsLeft = 0;

  // registration
  final _fullNameCtrl = TextEditingController();
  String _role = 'user';
  DateTime? _birthDate;
  final _agencyCodeCtrl = TextEditingController();
  bool _registering = false;

  // profile
  bool _loading = true;
  Map<String, dynamic>? _me;
  int _favoritesCount = 0;
  String _activeTab = 'overview'; // overview|settings
  bool _savingProfile = false;
  final _settingsFullNameCtrl = TextEditingController();
  DateTime? _settingsBirthDate;
  final _settingsAgencyCodeCtrl = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _myListingsKey = GlobalKey();
  List<Map<String, dynamic>> _myListings = [];
  bool _myListingsLoading = false;
  bool _myListingsTrashView = false;
  final Set<int> _selectedMyListingIds = {};
  int? _myListingBumpLoadingId;
  int? _myListingTopLoadingId;
  bool _myListingsBulkBumpBusy = false;
  bool _myListingsBulkArchiveBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _reloadMeIfLoggedIn();
  }

  Future<void> _reloadMeIfLoggedIn() async {
    final t = await getAccessToken();
    if (t == null || t.isEmpty || !mounted) return;
    await _loadMe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab == 'settings' && _me != null && _activeTab != 'settings') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeTab = 'settings');
      });
    }
  }

  Future<void> _boot() async {
    setState(() => _loading = true);
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _me = null;
        _loading = false;
        _myListings = [];
        _myListingsLoading = false;
      });
      return;
    }
    await _loadMe();
    if (mounted && _me != null) {
      await syncFcmTokenAfterLogin();
      _redirectAfterAuthIfNeeded();
    }
  }

  void _redirectAfterAuthIfNeeded() {
    if (!mounted) return;
    final ret = GoRouterState.of(context).uri.queryParameters[kPostAuthReturnToParam];
    if (ret == null || ret.isEmpty || !isSafeAppReturnPath(ret)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(ret);
    });
  }

  Future<void> _loadMe() async {
    try {
      final r = await dio.get('/api/auth/me/');
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      setState(() {
        _me = data;
        _loading = false;
      });
      _settingsFullNameCtrl.text = (data['full_name'] ?? '').toString();
      _settingsBirthDate = DateTime.tryParse((data['birth_date'] ?? '').toString());
      _settingsAgencyCodeCtrl.clear();
      await _loadMyListings();
      await _loadFavoritesCount();
      if (mounted) {
        ProviderScope.containerOf(context, listen: false).invalidate(favoritesCountProvider);
        final tab = GoRouterState.of(context).uri.queryParameters['tab'];
        if (tab == 'settings') setState(() => _activeTab = 'settings');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await setAccessToken(null);
      }
      setState(() {
        _me = null;
        _loading = false;
        _myListings = [];
        _myListingsLoading = false;
      });
      if (mounted) {
        ProviderScope.containerOf(context, listen: false).invalidate(favoritesCountProvider);
      }
    } catch (_) {
      setState(() {
        _me = null;
        _loading = false;
        _myListings = [];
        _myListingsLoading = false;
      });
    }
  }

  Future<void> _loadMyListings() async {
    final uid = _me?['user_id'];
    if (uid == null) {
      if (mounted) setState(() => _myListings = []);
      return;
    }
    if (!mounted) return;
    setState(() => _myListingsLoading = true);
    try {
      final r = await dio.get('/api/listings/list/', queryParameters: {'owner_id': uid.toString()});
      final raw = r.data;
      final list = raw is List ? raw : <dynamic>[];
      final maps = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is Map) maps.add(Map<String, dynamic>.from(e));
      }
      if (!mounted) return;
      setState(() {
        _myListings = maps;
        _myListingsLoading = false;
        final validIds = maps.map((m) => _parseListingId(m['id'])).whereType<int>().toSet();
        _selectedMyListingIds.removeWhere((id) => !validIds.contains(id));
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _myListings = [];
          _myListingsLoading = false;
          _selectedMyListingIds.clear();
        });
      }
    }
  }

  int? _parseListingId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  List<Map<String, dynamic>> _visibleMyListingsForDashboard() {
    if (_myListingsTrashView) {
      return _myListings.where((m) => (m['status']?.toString() == 'archived')).toList();
    }
    return _myListings.where((m) => m['status']?.toString() != 'archived').toList();
  }

  int _archivedMyListingsCount() => _myListings.where((m) => m['status']?.toString() == 'archived').length;

  String _formatDateRu(dynamic d) {
    if (d == null) return '—';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '—';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd.$mm.${dt.year}';
  }

  Map<String, dynamic> _bumpInfoForListing(Map<String, dynamic> listing) {
    const cooldownDays = 14;
    final last = listing['bumped_at'] ?? listing['updated_at'];
    if (last == null) return {'canBump': true, 'daysLeft': 0};
    final lastDt = DateTime.tryParse(last.toString());
    if (lastDt == null) return {'canBump': true, 'daysLeft': 0};
    final nextAt = lastDt.add(const Duration(days: cooldownDays));
    final msLeft = nextAt.difference(DateTime.now()).inMilliseconds;
    final daysLeft = msLeft > 0 ? (msLeft / (24 * 60 * 60 * 1000)).ceil() : 0;
    return {'canBump': daysLeft <= 0, 'daysLeft': daysLeft};
  }

  bool _isListingTopActive(Map<String, dynamic> listing) {
    if (listing['top_tariff'] == null) return false;
    final until = listing['top_paid_until'];
    if (until == null) return true;
    final dt = DateTime.tryParse(until.toString());
    if (dt == null) return true;
    return dt.isAfter(DateTime.now());
  }

  String _dashboardListingTitle(Map<String, dynamic> l) {
    final rooms = l['rooms'];
    final rv = rooms is Map ? rooms['value'] : rooms;
    final pt = l['property_type'];
    final ptn = pt is Map ? pt['name']?.toString() : pt?.toString();
    final area = l['area_total'];
    final floor = l['floor'];
    final fv = floor is Map ? floor['value'] : floor;
    final parts = <String>[];
    if (rv != null && rv.toString().isNotEmpty) parts.add('$rv комн.');
    if (ptn != null && ptn.isNotEmpty) parts.add(ptn);
    if (area != null && area.toString().isNotEmpty) parts.add('$area м²');
    if (fv != null && fv.toString().isNotEmpty) parts.add('$fv эт.');
    if (parts.isEmpty) {
      final desc = l['description']?.toString() ?? '';
      if (desc.length > 40) return '${desc.substring(0, 40)}…';
      if (desc.isNotEmpty) return desc;
      return 'L#${_parseListingId(l['id']) ?? '—'}';
    }
    return parts.join(', ');
  }

  String _formatPriceSom(dynamic p) {
    if (p == null) return '—';
    final n = p is num ? p.toInt() : int.tryParse(p.toString());
    if (n == null) return p.toString();
    return '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} с.';
  }

  String? _dashboardListingThumbUrl(Map<String, dynamic> l) {
    final images = l['images'];
    if (images is! List || images.isEmpty) return null;
    final first = images.first;
    if (first is! Map) return null;
    return getImageUrl(first['image']?.toString());
  }

  String _dashboardStatusLabel(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'active':
        return 'Активно';
      case 'draft':
        return 'Черновик';
      case 'hidden':
        return 'Скрыто';
      case 'sold':
        return 'Продано/Сдано';
      case 'archived':
        return 'В архиве';
      default:
        return s ?? '—';
    }
  }

  (Color bg, Color fg) _dashboardStatusBadgeColors(String? status, bool isDark) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return (const Color(0xFF064e3b).withValues(alpha: 0.5), const Color(0xFFa7f3d0));
      case 'hidden':
        return (const Color(0xFF78350f).withValues(alpha: 0.45), const Color(0xFFfde68a));
      case 'archived':
        return (const Color(0xFF374151).withValues(alpha: 0.4), const Color(0xFFe5e7eb));
      case 'draft':
        return (const Color(0xFF1e3a5f).withValues(alpha: 0.5), const Color(0xFFbfdbfe));
      case 'sold':
        return (const Color(0xFF7f1d1d).withValues(alpha: 0.4), const Color(0xFFfecaca));
      default:
        return (isDark ? const Color(0xFF374151).withValues(alpha: 0.35) : const Color(0xFFe5e7eb), isDark ? const Color(0xFFe5e7eb) : const Color(0xFF111827));
    }
  }

  Future<void> _myListingPatchStatus(int id, String status, {String? successMsg}) async {
    try {
      await dio.patch('/api/listings/$id/update/', data: {'status': status});
      await _loadMyListings();
      if (mounted && successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? e.message ?? 'Ошибка')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _myListingBump(int id) async {
    setState(() => _myListingBumpLoadingId = id);
    try {
      await dio.post('/api/listings/$id/bump/');
      await _loadMyListings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дата обновлена')));
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.data is Map ? (e.response!.data as Map)['code']?.toString() : null;
      if (code == 'bump_cooldown') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Обновление раз в 14 дней')));
      } else {
        final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
      }
    } finally {
      if (mounted) setState(() => _myListingBumpLoadingId = null);
    }
  }

  Future<void> _myListingAddToTop(int id) async {
    setState(() => _myListingTopLoadingId = id);
    try {
      await dio.post('/api/listings/$id/add-to-top/');
      await _loadMyListings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ТОП оформлен')));
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
    } finally {
      if (mounted) setState(() => _myListingTopLoadingId = null);
    }
  }

  Future<void> _myListingDeleteForever(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: const Text('Это действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete('/api/listings/$id/update/');
      await _loadMyListings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено')));
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
    }
  }

  Future<void> _bulkBumpSelectedMyListings() async {
    if (_selectedMyListingIds.isEmpty) return;
    setState(() => _myListingsBulkBumpBusy = true);
    var blocked = 0;
    try {
      for (final id in _selectedMyListingIds.toList()) {
        try {
          await dio.post('/api/listings/$id/bump/');
        } on DioException catch (e) {
          final code = e.response?.data is Map ? (e.response!.data as Map)['code']?.toString() : null;
          if (code == 'bump_cooldown') {
            blocked++;
          } else {
            rethrow;
          }
        }
      }
      await _loadMyListings();
      if (mounted && blocked > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Часть объявлений нельзя обновить (14 дней): $blocked')));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
    } finally {
      if (mounted) setState(() => _myListingsBulkBumpBusy = false);
    }
  }

  Future<void> _bulkArchiveSelectedMyListings() async {
    if (_selectedMyListingIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('В архив'),
        content: Text('Переместить в корзину выбранные объявления (${_selectedMyListingIds.length})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('В архив')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _myListingsBulkArchiveBusy = true);
    try {
      for (final id in _selectedMyListingIds.toList()) {
        await dio.patch('/api/listings/$id/update/', data: {'status': 'archived'});
      }
      setState(() => _selectedMyListingIds.clear());
      await _loadMyListings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Перемещено в корзину')));
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
    } finally {
      if (mounted) setState(() => _myListingsBulkArchiveBusy = false);
    }
  }

  Future<void> _bulkRestoreSelectedTrash() async {
    if (_selectedMyListingIds.isEmpty) return;
    setState(() => _myListingsBulkBumpBusy = true);
    try {
      for (final id in _selectedMyListingIds.toList()) {
        await dio.patch('/api/listings/$id/update/', data: {'status': 'active'});
      }
      setState(() => _selectedMyListingIds.clear());
      await _loadMyListings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Восстановлено')));
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
    } finally {
      if (mounted) setState(() => _myListingsBulkBumpBusy = false);
    }
  }

  Future<void> _bulkDeleteForeverSelected() async {
    if (_selectedMyListingIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда'),
        content: Text('Удалить безвозвратно ${_selectedMyListingIds.length} объявлений?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _myListingsBulkArchiveBusy = true);
    try {
      for (final id in _selectedMyListingIds.toList()) {
        await dio.delete('/api/listings/$id/update/');
      }
      setState(() => _selectedMyListingIds.clear());
      await _loadMyListings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено')));
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Ошибка')));
    } finally {
      if (mounted) setState(() => _myListingsBulkArchiveBusy = false);
    }
  }

  Future<void> _loadFavoritesCount() async {
    try {
      final r = await dio.get('/api/listings/favorites/count/');
      final c = r.data is Map ? r.data['count'] : null;
      setState(() => _favoritesCount = c is num ? c.toInt() : 0);
    } catch (_) {
      setState(() => _favoritesCount = 0);
    }
  }

  String _normalizePhone(String raw) {
    var s = raw.replaceAll(RegExp(r'[^\d+]'), '').replaceAll('+', '');
    if (s.isEmpty) return '';
    if (!s.startsWith('992')) {
      s = '992${s.replaceFirst(RegExp(r'^0+'), '')}';
    }
    return s;
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() => _resendSecondsLeft = 60);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSecondsLeft <= 1) {
        t.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  Future<void> _sendCode() async {
    final digits = _digitsOnly(_phoneCtrl.text);
    if (digits.length != 9 || _sendingCode) {
      if (digits.length != 9 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите 9 цифр номера (например 921234567).')));
      }
      return;
    }
    if (_codeSent && _resendSecondsLeft > 0) return;

    final phone = _normalizePhone(_phoneCtrl.text);
    if (phone.isEmpty || _sendingCode) return;
    setState(() {
      _sendingCode = true;
      _normalizedPhone = phone;
    });
    try {
      await dio.post('/api/auth/send-code/', data: {'phone': phone});
      setState(() {
        _codeSent = true;
        _sendingCode = false;
      });
      _startResendCooldown();
    } on DioException catch (e) {
      setState(() => _sendingCode = false);
      if (!mounted) return;
      var msg = 'Не удалось отправить код.';
      final data = e.response?.data;
      if (data is Map) {
        final err = data['error'] ?? data['detail'];
        if (err != null) {
          msg = err.toString();
          if (msg.length > 160) msg = '${msg.substring(0, 157)}…';
        }
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        msg = 'Таймаут: проверьте интернет или попробуйте позже.';
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'Нет связи с сервером. Интернет выключен или API недоступен (debug → нужен запущенный backend).';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      setState(() => _sendingCode = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось отправить код.')));
      }
    }
  }

  Future<void> _verifyCode() async {
    final phone = _normalizedPhone.isNotEmpty ? _normalizedPhone : _normalizePhone(_phoneCtrl.text);
    final code = _codeCtrl.text.trim();
    if (phone.isEmpty || _verifying) return;
    if (code.length != 4) {
      if (code.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите 4 цифры кода из SMS.')));
      }
      return;
    }
    setState(() => _verifying = true);
    try {
      final r = await dio.post('/api/auth/verify-code/', data: {'phone': phone, 'code': code});
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final access = (data['access'] ?? '').toString();
      final isRegistered = data['is_registered'] == true;
      if (access.isNotEmpty) {
        await setAccessToken(access);
      }
      setState(() {
        _verifying = false;
        _needsRegistration = !isRegistered;
        _normalizedPhone = phone;
      });
      if (isRegistered) {
        await _loadMe();
        if (mounted && _me != null) {
          await syncFcmTokenAfterLogin();
          _redirectAfterAuthIfNeeded();
        }
      }
    } catch (e) {
      setState(() => _verifying = false);
      _codeCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный код.')));
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (_registering) return;
    final fullName = _fullNameCtrl.text.trim();
    if (fullName.isEmpty) return;
    setState(() => _registering = true);
    try {
      final body = <String, dynamic>{
        'phone': _normalizedPhone,
        'role': _role,
        'full_name': fullName,
      };
      if (_birthDate != null) {
        body['birth_date'] = _birthDate!.toIso8601String().split('T').first;
      }
      if (_role == 'agent' && _agencyCodeCtrl.text.trim().isNotEmpty) {
        body['agency_code'] = _agencyCodeCtrl.text.trim();
      }
      final r = await dio.post('/api/auth/complete-registration/', data: FormData.fromMap(body));
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final access = (data['access'] ?? '').toString();
      if (access.isNotEmpty) await setAccessToken(access);
      setState(() {
        _registering = false;
        _needsRegistration = false;
      });
      await _loadMe();
      if (mounted && _me != null) {
        await syncFcmTokenAfterLogin();
        _redirectAfterAuthIfNeeded();
      }
    } on DioException catch (e) {
      setState(() => _registering = false);
      final msg = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Ошибка регистрации.')));
      }
    } catch (_) {
      setState(() => _registering = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка регистрации.')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      final m = <String, dynamic>{
        'full_name': _settingsFullNameCtrl.text.trim(),
      };
      m['birth_date'] = _settingsBirthDate != null ? _settingsBirthDate!.toIso8601String().split('T').first : '';
      final role = (_me?['role'] ?? '').toString().toLowerCase();
      if (role == 'agent') {
        m['agency_code'] = _settingsAgencyCodeCtrl.text.trim();
      }
      final r = await dio.patch('/api/auth/profile/', data: FormData.fromMap(m));
      setState(() {
        _savingProfile = false;
        _me = {
          ...?_me,
          'full_name': (r.data is Map && (r.data as Map)['full_name'] != null) ? (r.data as Map)['full_name'] : _settingsFullNameCtrl.text.trim(),
          'birth_date': (r.data is Map) ? (r.data as Map)['birth_date'] : (_settingsBirthDate?.toIso8601String()),
          'avatar': (r.data is Map) ? (r.data as Map)['avatar'] : _me?['avatar'],
          'agency_id': (r.data is Map) ? (r.data as Map)['agency_id'] : _me?['agency_id'],
          'agency_name': (r.data is Map) ? (r.data as Map)['agency_name'] : _me?['agency_name'],
        };
      });
      await _loadMyListings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
      }
    } catch (_) {
      setState(() => _savingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка сохранения')));
      }
    }
  }

  Future<void> _logout() async {
    await setAccessToken(null);
    _resendCooldownTimer?.cancel();
    setState(() {
      _me = null;
      _myListings = [];
      _myListingsTrashView = false;
      _selectedMyListingIds.clear();
      _activeTab = 'overview';
      _codeSent = false;
      _needsRegistration = false;
      _resendSecondsLeft = 0;
      _phoneCtrl.clear();
      _codeCtrl.clear();
    });
    if (mounted) {
      ProviderScope.containerOf(context, listen: false).invalidate(favoritesCountProvider);
    }
  }

  void _onProfileBack() {
    if (_activeTab == 'settings') {
      setState(() => _activeTab = 'overview');
      return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Widget _dashActionChip(
    String label, {
    required VoidCallback? onTap,
    Color? fg,
    Color? bg,
    Color? outline,
    required Color defaultBorder,
    required Color defaultFg,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 4),
      child: Material(
        color: bg ?? Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: outline ?? defaultBorder),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg ?? defaultFg),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _dashboardRowActions(
    Map<String, dynamic> l, {
    required Color text,
    required Color muted,
    required Color border,
    required Color accentBlue,
    required Color accentOrange,
    required Color green,
    required Color gold,
    required bool isDark,
  }) {
    final id = _parseListingId(l['id']);
    if (id == null) return [];
    final status = l['status']?.toString() ?? '';
    final bump = _bumpInfoForListing(l);
    final canBump = bump['canBump'] == true;
    final daysLeft = bump['daysLeft'] is int ? bump['daysLeft'] as int : (bump['daysLeft'] as num?)?.toInt() ?? 0;
    final topActive = _isListingTopActive(l);
    final bumpBusy = _myListingBumpLoadingId == id;
    final topBusy = _myListingTopLoadingId == id;

    if (status == 'archived') {
      return [
        _dashActionChip(
          'Восстановить',
          onTap: () => _myListingPatchStatus(id, 'active', successMsg: 'Объявление активировано'),
          fg: Colors.white,
          bg: green.withValues(alpha: 0.85),
          outline: green,
          defaultBorder: border,
          defaultFg: text,
        ),
        _dashActionChip(
          'Удалить навсегда',
          onTap: () => _myListingDeleteForever(id),
          fg: Colors.white,
          bg: const Color(0xFF7f1d1d),
          outline: const Color(0xFFef4444),
          defaultBorder: border,
          defaultFg: text,
        ),
      ];
    }

    return [
      _dashActionChip(
        'Изменить',
        onTap: () => context.push('/add?edit=$id'),
        fg: accentBlue,
        outline: accentBlue.withValues(alpha: 0.45),
        defaultBorder: border,
        defaultFg: text,
      ),
      _dashActionChip(
        status == 'hidden' ? 'Активировать' : 'Скрыть',
        onTap: () async {
          final next = status == 'hidden' ? 'active' : 'hidden';
          await _myListingPatchStatus(
            id,
            next,
            successMsg: next == 'hidden' ? 'Объявление скрыто' : 'Объявление активировано',
          );
        },
        fg: status == 'hidden' ? Colors.white : null,
        bg: status == 'hidden' ? const Color(0xFF065f46) : null,
        outline: status == 'hidden' ? const Color(0xFF10b981) : null,
        defaultBorder: border,
        defaultFg: text,
      ),
      _dashActionChip(
        bumpBusy ? '...' : (canBump ? 'Обновить дату' : 'До обновить $daysLeft дн.'),
        onTap: (!canBump || bumpBusy) ? null : () => _myListingBump(id),
        fg: canBump ? Colors.white : muted,
        bg: canBump ? green.withValues(alpha: 0.9) : (isDark ? const Color(0xFF262626) : const Color(0xFFf3f4f6)),
        outline: canBump ? green : border,
        defaultBorder: border,
        defaultFg: text,
      ),
      _dashActionChip(
        topBusy ? '...' : (topActive ? 'Уже в ТОП' : 'В ТОП'),
        onTap: (topActive || topBusy) ? null : () => _myListingAddToTop(id),
        fg: topActive ? Colors.white : const Color(0xFF111827),
        bg: topActive ? const Color(0xFF7f1d1d) : gold.withValues(alpha: 0.35),
        outline: topActive ? const Color(0xFFef4444) : gold,
        defaultBorder: border,
        defaultFg: text,
      ),
      _dashActionChip(
        'В архив',
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('В архив'),
              content: const Text('Переместить объявление в корзину?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('В архив')),
              ],
            ),
          );
          if (ok == true) await _myListingPatchStatus(id, 'archived', successMsg: 'В корзине');
        },
        defaultBorder: border,
        defaultFg: text,
      ),
      _dashActionChip(
        'Открыть',
        onTap: () => context.push('/listings/$id'),
        fg: accentOrange,
        outline: accentOrange.withValues(alpha: 0.45),
        defaultBorder: border,
        defaultFg: text,
      ),
    ];
  }

  Widget _buildDashboardListingCard(
    Map<String, dynamic> l, {
    required Color card,
    required Color border,
    required Color text,
    required Color muted,
    required bool isDark,
    required Color accentBlue,
    required Color accentOrange,
    required Color green,
    required Color gold,
  }) {
    final id = _parseListingId(l['id']);
    final status = l['status']?.toString();
    final thumb = _dashboardListingThumbUrl(l);
    final badge = _dashboardStatusBadgeColors(status, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (id != null)
                Checkbox(
                  value: _selectedMyListingIds.contains(id),
                  onChanged: (_) {
                    setState(() {
                      if (_selectedMyListingIds.contains(id)) {
                        _selectedMyListingIds.remove(id);
                      } else {
                        _selectedMyListingIds.add(id);
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
              else
                const SizedBox(width: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: thumb != null && thumb.isNotEmpty
                      ? Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: border.withValues(alpha: 0.35),
                              child: Icon(Icons.broken_image_outlined, color: muted, size: 28),
                            );
                          },
                        )
                      : ColoredBox(
                          color: border.withValues(alpha: 0.35),
                          child: Icon(Icons.image_not_supported_outlined, color: muted, size: 28),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('L#$id', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                    Text(
                      _dashboardListingTitle(l),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatPriceSom(l['price']), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accentBlue)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Последнее: ${_formatDateRu(l['updated_at'] ?? l['bumped_at'] ?? l['submission_date'])} · Добавлено: ${_formatDateRu(l['submission_date'])} · Просмотры: ${l['view_count'] ?? 0}',
            style: TextStyle(fontSize: 11, color: muted, height: 1.35),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badge.$1,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border.withValues(alpha: 0.35)),
              ),
              child: Text(_dashboardStatusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badge.$2)),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _dashboardRowActions(
                l,
                text: text,
                muted: muted,
                border: border,
                accentBlue: accentBlue,
                accentOrange: accentOrange,
                green: green,
                gold: gold,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendCooldownTimer?.cancel();
    _scrollController.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _fullNameCtrl.dispose();
    _agencyCodeCtrl.dispose();
    _settingsFullNameCtrl.dispose();
    _settingsAgencyCodeCtrl.dispose();
    super.dispose();
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
    final accent = const Color(0xFFE79A3E);

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));
    }

    // --- AUTH UI (like web prompt) ---
    if (_me == null) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo512.png',
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.person, size: 56, color: accent),
                      ),
                      const SizedBox(height: 14),
                      Text(_needsRegistration ? 'Регистрация' : 'Вход', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text)),
                      const SizedBox(height: 8),
                      Text(
                        _needsRegistration
                            ? 'Заполните данные профиля.'
                            : 'Введите телефон и код из SMS, чтобы войти.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      if (!_needsRegistration) ...[
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 9,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Телефон',
                            hintText: '921234567',
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_codeSent) ...[
                          TextField(
                            controller: _codeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Код',
                              hintText: 'Код из SMS',
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) {
                              if (v.length == 4) {
                                _verifyCode();
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!_codeSent)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _sendingCode ? null : _sendCode,
                              style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                              child: Text(_sendingCode ? '...' : 'Получить код'),
                            ),
                          ),
                        if (_codeSent) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _verifying ? null : _verifyCode,
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563eb), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                              child: Text(_verifying ? '...' : 'Войти'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: (_sendingCode || _resendSecondsLeft > 0) ? null : _sendCode,
                              child: Text(
                                _sendingCode
                                    ? 'Отправка…'
                                    : (_resendSecondsLeft > 0 ? 'Отправить код ещё раз ($_resendSecondsLeft с)' : 'Отправить код ещё раз'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: (_sendingCode || _resendSecondsLeft > 0) ? muted : accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        TextField(
                          controller: _fullNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Имя и фамилия',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: InputDecoration(
                            labelText: 'Роль',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('Пользователь')),
                            DropdownMenuItem(value: 'owner', child: Text('Собственник')),
                            DropdownMenuItem(value: 'agent', child: Text('Агент')),
                            DropdownMenuItem(value: 'agency', child: Text('Агентство')),
                            DropdownMenuItem(value: 'developer', child: Text('Застройщик')),
                          ],
                          onChanged: (v) => setState(() => _role = v ?? 'user'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1950, 1, 1),
                              lastDate: DateTime(now.year - 18, now.month, now.day),
                              initialDate: _birthDate ?? DateTime(now.year - 18, 1, 1),
                            );
                            if (picked != null) setState(() => _birthDate = picked);
                          },
                          child: Text(_birthDate == null ? 'Дата рождения' : 'Дата рождения: ${_birthDate!.toIso8601String().split('T').first}'),
                        ),
                        const SizedBox(height: 12),
                        if (_role == 'agent')
                          TextField(
                            controller: _agencyCodeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Код агентства (если есть)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _registering ? null : _completeRegistration,
                            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(_registering ? '...' : 'Завершить регистрацию'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // --- PROFILE UI (dashboard-style) ---
    final role = (_me?['role'] ?? '').toString();
    final fullName = (_me?['full_name'] ?? '').toString();
    final balance = _me?['balance'];
    final listingCount = _me?['listing_count'];
    final listingLimit = _me?['listing_limit'];
    final agencyName = (_me?['agency_name'] ?? '').toString();

    Widget content() {
      switch (_activeTab) {
        case 'settings':
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Личные данные', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _settingsFullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Имя и фамилия'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1950, 1, 1),
                          lastDate: DateTime(now.year - 18, now.month, now.day),
                          initialDate: _settingsBirthDate ?? DateTime(now.year - 18, 1, 1),
                        );
                        if (picked != null) setState(() => _settingsBirthDate = picked);
                      },
                      child: Text(_settingsBirthDate == null ? 'Дата рождения' : 'Дата рождения: ${_settingsBirthDate!.toIso8601String().split('T').first}'),
                    ),
                    if (role.toLowerCase() == 'agent') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _settingsAgencyCodeCtrl,
                        decoration: InputDecoration(
                          labelText: agencyName.isNotEmpty ? 'Код агентства (сейчас: $agencyName)' : 'Код агентства',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Оставьте пустым, чтобы отвязать.', style: TextStyle(color: muted, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _savingProfile ? null : _saveProfile,
                            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(_savingProfile ? '...' : 'Сохранить', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: accent),
                            child: const Text('Выйти', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        case 'overview':
        default:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Кабинет', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text)),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await context.push('/balance');
                        if (!mounted) return;
                        await _loadMe();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet, size: 20, color: Color(0xFF2563eb)),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.36),
                              child: Text(
                                balance != null ? '${(balance as num).toStringAsFixed(2)} с.' : '—',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563eb)),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF2563eb)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'В избранном',
                      value: '$_favoritesCount',
                      icon: Icons.favorite,
                      color: accent,
                      onTap: () => context.go('/favorites'),
                      card: card,
                      border: border,
                      text: text,
                      muted: muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Объявления',
                      value: listingCount != null ? '$listingCount' : '—',
                      icon: Icons.list,
                      color: const Color(0xFF22c55e),
                      onTap: () {
                        final ctx = _myListingsKey.currentContext;
                        if (ctx != null) {
                          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
                        }
                      },
                      card: card,
                      border: border,
                      text: text,
                      muted: muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName.isNotEmpty ? fullName : _normalizedPhone, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 6),
                    Text('Роль: $role', style: TextStyle(color: muted, fontSize: 13)),
                    if (listingLimit != null && listingCount != null) ...[
                      const SizedBox(height: 6),
                      Text('Лимит объявлений: $listingCount / $listingLimit', style: TextStyle(color: muted, fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.go('/messages'),
                            icon: const Icon(Icons.chat_bubble),
                            label: const Text('Сообщения'),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563eb), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.go('/settings'),
                            icon: const Icon(Icons.settings),
                            label: const Text('Настройки'),
                            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final canManageMyListings = role.toLowerCase() == 'owner' || role.toLowerCase() == 'agent';
                  const blue = Color(0xFF2563eb);
                  const green = Color(0xFF22c55e);
                  const gold = Color(0xFFeab308);
                  final visible = _visibleMyListingsForDashboard();
                  final archivedN = _archivedMyListingsCount();
                  return Column(
                    key: _myListingsKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Мои объявления', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
                          ),
                          if (_myListingsLoading)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              onPressed: _loadMyListings,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Обновить список',
                              color: text,
                            ),
                        ],
                      ),
                      if (canManageMyListings) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Действия: Изменить · Скрыть/Активировать · Обновить (раз в 14 дней) · В ТОП · В архив · Открыть',
                          style: TextStyle(fontSize: 12, color: muted, height: 1.45),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (!canManageMyListings)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Управление объявлениями доступно собственникам и агентам.',
                            style: TextStyle(color: muted, fontSize: 14),
                          ),
                        )
                      else if (_myListingsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (!_myListingsTrashView) ...[
                                FilledButton(
                                  onPressed: _myListingsBulkBumpBusy || _selectedMyListingIds.isEmpty ? null : _bulkBumpSelectedMyListings,
                                  style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
                                  child: Text(_myListingsBulkBumpBusy ? '...' : 'Обновить выбранные (${_selectedMyListingIds.length})'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _myListingsBulkArchiveBusy || _selectedMyListingIds.isEmpty ? null : _bulkArchiveSelectedMyListings,
                                  child: Text(_myListingsBulkArchiveBusy ? '...' : 'В архив выбранные (${_selectedMyListingIds.length})'),
                                ),
                              ] else ...[
                                FilledButton(
                                  onPressed: _myListingsBulkBumpBusy || _selectedMyListingIds.isEmpty ? null : _bulkRestoreSelectedTrash,
                                  style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
                                  child: Text(_myListingsBulkBumpBusy ? '...' : 'Восстановить (${_selectedMyListingIds.length})'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _myListingsBulkArchiveBusy || _selectedMyListingIds.isEmpty ? null : _bulkDeleteForeverSelected,
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7f1d1d), foregroundColor: Colors.white),
                                  child: Text(_myListingsBulkArchiveBusy ? '...' : 'Удалить навсегда (${_selectedMyListingIds.length})'),
                                ),
                              ],
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _myListingsTrashView = !_myListingsTrashView;
                                  _selectedMyListingIds.clear();
                                }),
                                child: Text(_myListingsTrashView ? 'Вернуться' : 'Корзина ($archivedN)'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                Text(
                                  _myListingsTrashView ? 'Корзина пуста.' : 'Нет объявлений.',
                                  style: TextStyle(color: muted, fontSize: 15),
                                ),
                                if (!_myListingsTrashView && _myListings.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: () => context.push('/add'),
                                    child: const Text('Добавить объявление'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Checkbox(
                                  tristate: true,
                                  value: _selectedMyListingIds.isEmpty
                                      ? false
                                      : (_selectedMyListingIds.length == visible.length ? true : null),
                                  onChanged: (_) {
                                    setState(() {
                                      final ids = visible.map((m) => _parseListingId(m['id'])).whereType<int>().toList();
                                      if (_selectedMyListingIds.length == ids.length) {
                                        _selectedMyListingIds.clear();
                                      } else {
                                        _selectedMyListingIds
                                          ..clear()
                                          ..addAll(ids);
                                      }
                                    });
                                  },
                                ),
                              ),
                              Text('Выбрать все', style: TextStyle(fontSize: 13, color: muted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visible.length,
                            itemBuilder: (ctx, i) {
                              final m = visible[i];
                              return _buildDashboardListingCard(
                                m,
                                card: card,
                                border: border,
                                text: text,
                                muted: muted,
                                isDark: isDark,
                                accentBlue: blue,
                                accentOrange: accent,
                                green: green,
                                gold: gold,
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ],
          );
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _onProfileBack,
                    icon: Icon(Icons.arrow_back, color: text),
                    tooltip: 'Назад',
                  ),
                  Expanded(
                    child: Text(fullName.isNotEmpty ? fullName : 'Профиль', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _activeTab = 'overview'),
                    icon: Icon(Icons.dashboard, color: _activeTab == 'overview' ? accent : muted),
                    tooltip: 'Кабинет',
                  ),
                  IconButton(
                    onPressed: () => context.go('/settings'),
                    icon: Icon(Icons.settings, color: muted),
                    tooltip: 'Настройки приложения',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(controller: _scrollController, child: content())),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
                  const SizedBox(height: 2),
                  Text(title, style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

