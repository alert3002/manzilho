import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/post_auth_redirect.dart';
import '../../../gen_l10n/app_localizations.dart';

/// Монанди SmartAssistant.jsx — заявки, форма, полигон, совпадения.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.initialRequestId});

  final int? initialRequestId;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _scrollController = ScrollController();
  /// Скролли уфуқии ҷадвали «натиҷаҳо» (вариантҳо аз рост).
  final _resultsHScroll = ScrollController();
  final _resultsKey = GlobalKey();

  static const double _kResultLeftCol = 172;
  static const double _kResultVarCol = 156;

  bool _loading = true;
  bool _refsLoading = true;
  bool _saving = false;
  bool _running = false;
  /// Токен дар SharedPreferences (барои пешгирӣ аз 401 бе паёми возеҳ).
  bool _hasToken = false;

  List<Map<String, dynamic>> _requests = [];
  int? _activeRequestId;

  List<Map<String, dynamic>> _dealTypes = [];
  List<Map<String, dynamic>> _propertyTypes = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _roomOptions = [];
  List<Map<String, dynamic>> _landCategories = [];
  List<Map<String, dynamic>> _commercialCategories = [];
  List<Map<String, dynamic>> _rentalTerms = [];

  List<Map<String, dynamic>> _matches = [];

  String _intent = 'buy';
  int? _dealTypeId;
  int? _propertyTypeId;
  int? _cityId;
  int? _roomsId;
  final _priceMinCtrl = TextEditingController();
  final _priceMaxCtrl = TextEditingController();
  final _areaTotalMinCtrl = TextEditingController();
  final _areaTotalMaxCtrl = TextEditingController();
  final _areaLandMinCtrl = TextEditingController();
  final _areaLandMaxCtrl = TextEditingController();
  String? _landTypeKey;
  String? _commercialKey;
  String? _rentalTermKey;
  bool _isActive = true;

  final List<LatLng> _polygon = [];
  List<LatLng> _polygonBeforeDraw = [];
  bool _isDrawing = false;
  int? _selectedPointIdx;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _resultsHScroll.dispose();
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    _areaTotalMinCtrl.dispose();
    _areaTotalMaxCtrl.dispose();
    _areaLandMinCtrl.dispose();
    _areaLandMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshAuthFlag() async {
    final t = await getAccessToken();
    if (mounted) setState(() => _hasToken = t != null && t.isNotEmpty);
  }

  /// Агар токен набошад — паём + тугмаи «Профиль». false = амалиётро қатъ кунед.
  Future<bool> _ensureLoggedIn() async {
    await _refreshAuthFlag();
    if (!mounted) return false;
    if (_hasToken) return true;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.assistantLoginFirstSnack),
        action: SnackBarAction(
          label: loc.navProfile,
          onPressed: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    return false;
  }

  void _showDioError(DioException e) {
    if (!mounted) return;
    if (e.response?.statusCode == 401) setState(() => _hasToken = false);
    final msg = messageFromDioException(e);
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: e.response?.statusCode == 401
            ? SnackBarAction(
                label: loc.navProfile,
                onPressed: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _refsLoading = true;
    });
    await _refreshAuthFlag();
    await _loadRefs();
    await _loadRequests();
    if (mounted) {
      setState(() {
        _loading = false;
        _refsLoading = false;
        if (widget.initialRequestId != null &&
            _requests.any((r) => _idOf(r) == widget.initialRequestId)) {
          _activeRequestId = widget.initialRequestId;
        }
        if (_activeRequestId == null && _requests.isNotEmpty) {
          _activeRequestId = _idOf(_requests.first);
        }
      });
      _applyActiveRequest();
    }
  }

  int? _idOf(Map<String, dynamic> m) => int.tryParse(m['id']?.toString() ?? '');

  int? _parseFk(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is Map) return int.tryParse(v['id']?.toString() ?? '');
    return int.tryParse(v.toString());
  }

  List<LatLng> _polygonFromApi(dynamic poly) {
    if (poly is! List) return [];
    final out = <LatLng>[];
    for (final p in poly) {
      if (p is List && p.length >= 2) {
        final lng = double.tryParse(p[0].toString());
        final lat = double.tryParse(p[1].toString());
        if (lng != null && lat != null) out.add(LatLng(lat, lng));
      }
    }
    return out;
  }

  List<List<double>> _polygonToApi(List<LatLng> pts) =>
      pts.map((e) => [e.longitude, e.latitude]).toList();

  Future<void> _loadRefs() async {
    try {
      final results = await Future.wait([
        dio.get('/api/listings/deal-types/'),
        dio.get('/api/listings/property-types/'),
        dio.get('/api/listings/cities/'),
        dio.get('/api/listings/room-options/'),
        dio.get('/api/listings/land-categories/'),
        dio.get('/api/listings/commercial-categories/'),
        dio.get('/api/listings/rental-terms/'),
      ]);
      if (!mounted) return;
      setState(() {
        _dealTypes = ensureArray<Map<String, dynamic>>(results[0].data);
        _propertyTypes = ensureArray<Map<String, dynamic>>(results[1].data);
        _cities = ensureArray<Map<String, dynamic>>(results[2].data);
        _roomOptions = ensureArray<Map<String, dynamic>>(results[3].data);
        _landCategories = ensureArray<Map<String, dynamic>>(results[4].data);
        _commercialCategories = ensureArray<Map<String, dynamic>>(results[5].data);
        _rentalTerms = ensureArray<Map<String, dynamic>>(results[6].data);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).assistantRefsLoadError)),
        );
      }
    }
  }

  Future<void> _loadRequests() async {
    try {
      final res = await dio.get('/api/listings/assistant/requests/');
      if (!mounted) return;
      final list = ensureArray<Map<String, dynamic>>(res.data);
      setState(() {
        _requests = list;
        _hasToken = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        setState(() {
          _requests = [];
          _hasToken = false;
        });
        return;
      }
      setState(() => _requests = []);
    } catch (_) {
      if (!mounted) return;
      setState(() => _requests = []);
    }
  }

  Future<void> _loadMatches(int? reqId) async {
    if (reqId == null) {
      setState(() => _matches = []);
      return;
    }
    try {
      final res = await dio.get('/api/listings/assistant/requests/$reqId/matches/');
      if (!mounted) return;
      setState(() => _matches = ensureArray<Map<String, dynamic>>(res.data));
    } catch (_) {
      if (!mounted) return;
      setState(() => _matches = []);
    }
  }

  Map<String, dynamic>? get _activeReq {
    if (_activeRequestId == null) return null;
    for (final r in _requests) {
      if (_idOf(r) == _activeRequestId) return r;
    }
    return null;
  }

  void _applyActiveRequest() {
    final req = _activeReq;
    if (req == null) {
      setState(() => _matches = []);
      return;
    }
    String? strOrNull(dynamic v) {
      final s = v?.toString() ?? '';
      return s.isEmpty ? null : s;
    }

    setState(() {
      _intent = req['intent']?.toString() ?? 'buy';
      _dealTypeId = _parseFk(req['deal_type']);
      _propertyTypeId = _parseFk(req['property_type']);
      _cityId = _parseFk(req['city']);
      _roomsId = _parseFk(req['rooms']);
      _priceMinCtrl.text = req['price_min']?.toString() ?? '';
      _priceMaxCtrl.text = req['price_max']?.toString() ?? '';
      _areaTotalMinCtrl.text = req['area_total_min']?.toString() ?? '';
      _areaTotalMaxCtrl.text = req['area_total_max']?.toString() ?? '';
      _areaLandMinCtrl.text = req['area_land_min']?.toString() ?? '';
      _areaLandMaxCtrl.text = req['area_land_max']?.toString() ?? '';
      _landTypeKey = strOrNull(req['land_type']);
      _commercialKey = strOrNull(req['commercial_type']);
      _rentalTermKey = strOrNull(req['rental_term']);
      _isActive = req['is_active'] == true || req['is_active'] == null;
      _polygon
        ..clear()
        ..addAll(_polygonFromApi(req['polygon']));
      _isDrawing = false;
      _selectedPointIdx = null;
    });
    _loadMatches(_activeRequestId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _resultsKey.currentContext == null) return;
      Scrollable.ensureVisible(
        _resultsKey.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startNewRequest() async {
    await _refreshAuthFlag();
    if (!mounted) return;
    if (!_hasToken) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.assistantLoginFirstSnack),
          action: SnackBarAction(
            label: loc.navProfile,
            onPressed: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    setState(() {
      _activeRequestId = null;
      _matches = [];
      _selectedPointIdx = null;
      _polygon.clear();
      _isDrawing = false;
      _intent = 'buy';
      _dealTypeId = null;
      _propertyTypeId = null;
      _cityId = null;
      _roomsId = null;
      _priceMinCtrl.clear();
      _priceMaxCtrl.clear();
      _areaTotalMinCtrl.clear();
      _areaTotalMaxCtrl.clear();
      _areaLandMinCtrl.clear();
      _areaLandMaxCtrl.clear();
      _landTypeKey = null;
      _commercialKey = null;
      _rentalTermKey = null;
      _isActive = true;
    });
  }

  void _selectRequest(int id) {
    setState(() => _activeRequestId = id);
    _applyActiveRequest();
  }

  num? _toNum(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t.replaceAll(',', '.'));
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'intent': _intent,
      'deal_type': _dealTypeId,
      'property_type': _propertyTypeId,
      'city': _cityId,
      'rooms': _roomsId,
      'price_min': _toNum(_priceMinCtrl.text),
      'price_max': _toNum(_priceMaxCtrl.text),
      'area_total_min': _toNum(_areaTotalMinCtrl.text),
      'area_total_max': _toNum(_areaTotalMaxCtrl.text),
      'area_land_min': _toNum(_areaLandMinCtrl.text),
      'area_land_max': _toNum(_areaLandMaxCtrl.text),
      'land_type': _landTypeKey,
      'commercial_type': _commercialKey,
      'rental_term': _rentalTermKey,
      'polygon': _polygon.length >= 3 ? _polygonToApi(_polygon) : null,
      'is_active': _isActive,
    };
  }

  Future<void> _onSave() async {
    if (!await _ensureLoggedIn()) return;
    if (!mounted) return;
    if (_polygon.isNotEmpty && _polygon.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).assistantPolygonMinPoints)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = _buildPayload();
      if (_activeRequestId != null) {
        await dio.put('/api/listings/assistant/requests/$_activeRequestId/', data: payload);
      } else {
        final res = await dio.post('/api/listings/assistant/requests/', data: payload);
        final newId = res.data is Map ? int.tryParse((res.data as Map)['id']?.toString() ?? '') : null;
        if (newId != null && mounted) setState(() => _activeRequestId = newId);
      }
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).assistantSaved)));
      }
    } on DioException catch (e) {
      _showDioError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onRun() async {
    if (_activeRequestId == null) return;
    if (!await _ensureLoggedIn()) return;
    if (!mounted) return;
    setState(() => _running = true);
    try {
      await dio.post('/api/listings/assistant/requests/$_activeRequestId/run-match/');
      await _loadMatches(_activeRequestId);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_resultsKey.currentContext != null) {
          Scrollable.ensureVisible(
            _resultsKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    } on DioException catch (e) {
      _showDioError(e);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _onDelete() async {
    if (_activeRequestId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.assistantDeleteRequestTitle),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.btnNo)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.btnYes)),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    if (!await _ensureLoggedIn()) return;
    if (!mounted) return;
    try {
      await dio.delete('/api/listings/assistant/requests/$_activeRequestId/');
      if (!mounted) return;
      _startNewRequest();
      await _loadRequests();
    } on DioException catch (e) {
      _showDioError(e);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).assistantDeleteFailed)));
      }
    }
  }

  void _toggleDrawing() {
    if (_isDrawing) {
      setState(() => _isDrawing = false);
    } else {
      setState(() {
        _polygonBeforeDraw = List<LatLng>.from(_polygon);
        _polygon.clear();
        _selectedPointIdx = null;
        _isDrawing = true;
      });
    }
  }

  void _cancelDrawing() {
    setState(() {
      _polygon
        ..clear()
        ..addAll(_polygonBeforeDraw);
      _selectedPointIdx = null;
      _isDrawing = false;
    });
  }

  void _finishDrawing() => setState(() => _isDrawing = false);

  void _onTapMap(TapPosition _, LatLng latLng) {
    if (!_isDrawing) return;
    setState(() => _polygon.add(latLng));
  }

  String _nameById(List<Map<String, dynamic>> list, int? id, {String nameKey = 'name', String idKey = 'id'}) {
    if (id == null) return '—';
    for (final x in list) {
      if (int.tryParse(x[idKey]?.toString() ?? '') == id) {
        return x[nameKey]?.toString() ?? '#$id';
      }
    }
    return '#$id';
  }

  String _roomLabel(int? id) {
    if (id == null) return '—';
    for (final x in _roomOptions) {
      if (int.tryParse(x['id']?.toString() ?? '') == id) {
        return x['value']?.toString() ?? x['name']?.toString() ?? '#$id';
      }
    }
    return '#$id';
  }

  String _fmtRange(AppLocalizations l10n, dynamic min, dynamic max, [String suffix = '']) {
    final a = min?.toString() ?? '';
    final b = max?.toString() ?? '';
    if (a.isNotEmpty && b.isNotEmpty) return '$a–$b$suffix';
    if (a.isNotEmpty) return '${l10n.assistantRangeFrom} $a$suffix';
    if (b.isNotEmpty) return '${l10n.assistantRangeTo} $b$suffix';
    return '—';
  }

  Widget _scoreBadge(num score) {
    final s = score.toInt();
    Color bg;
    Color fg;
    if (s >= 80) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF065F46);
    } else if (s >= 50) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1D4ED8);
    } else {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFF9A3412);
    }
    return Container(
      width: 72,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Text('$s%', style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardColor;
    final border = theme.dividerColor.withValues(alpha: 0.25);
    final muted = theme.textTheme.bodySmall?.color ?? Colors.grey;

    if (_loading || _refsLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.menuSmartAssistant)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final active = _activeReq;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.menuSmartAssistant),
            Text(
              l10n.assistantSubtitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshAuthFlag();
          await _loadRequests();
          if (_activeRequestId != null) await _loadMatches(_activeRequestId);
        },
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            children: [
            if (!_hasToken)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: isDark ? const Color(0xFF3D2E1F) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.login,
                            color: isDark ? const Color(0xFFFDBA74) : Colors.orange.shade800,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.assistantNotLoggedTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? const Color(0xFFFED7AA) : Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.assistantNotLoggedBody,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: isDark ? const Color(0xFFE7E5E4) : Colors.brown.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.assistantGoProfile,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            _section(
              l10n.assistantMyRequests,
              isDark,
              cardBg,
              border,
              [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _startNewRequest(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.assistantNewRequest),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_requests.isEmpty)
                  Text(l10n.assistantNoRequestsYet, style: TextStyle(color: muted))
                else
                  ..._requests.map((r) {
                    final id = _idOf(r)!;
                    final active = id == _activeRequestId;
                    final city = _parseFk(r['city']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: active
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _selectRequest(id),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(l10n.assistantRequestTitle(id), style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: border),
                                        color: r['is_active'] == true
                                            ? Colors.green.withValues(alpha: 0.12)
                                            : Colors.orange.withValues(alpha: 0.12),
                                      ),
                                      child: Text(
                                        r['is_active'] == true ? l10n.assistantStatusActive : l10n.assistantStatusPaused,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${city != null ? '${l10n.assistantCityPrefix} ${_nameById(_cities, city)}' : l10n.assistantNoCity} · '
                                  '${l10n.assistantPointsLabel} ${_polygonFromApi(r['polygon']).length}',
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                                Text(l10n.assistantOpenArrow, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 12),
            _section(l10n.assistantFormSection, isDark, cardBg, border, [
              _dropdown<String>(
                l10n.assistantFieldAction,
                _intent,
                [
                  DropdownMenuItem(value: 'buy', child: Text(l10n.assistantIntentBuy)),
                  DropdownMenuItem(value: 'rent', child: Text(l10n.assistantIntentRent)),
                  DropdownMenuItem(value: 'daily', child: Text(l10n.assistantIntentDaily)),
                ],
                (v) => setState(() => _intent = v ?? 'buy'),
              ),
              _dropdownIntNullable(l10n.assistantLabelDealType, _dealTypeId, _dealTypes, (v) => setState(() => _dealTypeId = v)),
              _dropdownIntNullable(l10n.assistantLabelPropertyType, _propertyTypeId, _propertyTypes, (v) => setState(() => _propertyTypeId = v)),
              _dropdownIntNullable(l10n.assistantLabelCity, _cityId, _cities, (v) => setState(() => _cityId = v)),
              _dropdownIntNullable(l10n.assistantLabelRooms, _roomsId, _roomOptions, (v) => setState(() => _roomsId = v), labelKey: 'value'),
              Row(
                children: [
                  Expanded(child: _textField(_priceMinCtrl, l10n.assistantLabelPriceMin)),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_priceMaxCtrl, l10n.assistantLabelPriceMax)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _textField(_areaTotalMinCtrl, l10n.assistantLabelAreaMin)),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_areaTotalMaxCtrl, l10n.assistantLabelAreaMax)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _textField(_areaLandMinCtrl, l10n.assistantLabelLandMin)),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_areaLandMaxCtrl, l10n.assistantLabelLandMax)),
                ],
              ),
              _dropdownStrNullable(l10n.assistantLabelLandType, _landTypeKey, _landCategories, (v) => setState(() => _landTypeKey = v)),
              _dropdownStrNullable(l10n.assistantLabelCommercial, _commercialKey, _commercialCategories, (v) => setState(() => _commercialKey = v)),
              _dropdownStrNullable(l10n.assistantLabelRentalTerm, _rentalTermKey, _rentalTerms, (v) => setState(() => _rentalTermKey = v)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.assistantSearchDaily, style: const TextStyle(fontWeight: FontWeight.w700)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ]),
            const SizedBox(height: 12),
            _section(l10n.assistantMapSection, isDark, cardBg, border, [
              Text(
                l10n.assistantMapHint,
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: const LatLng(38.5598, 68.7870),
                          initialZoom: 12,
                          onTap: _onTapMap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'tj.manzilho.mobile',
                          ),
                          if (_polygon.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _polygon,
                                  strokeWidth: 4,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ],
                            ),
                          if (_polygon.length >= 3)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: _polygon,
                                  borderColor: const Color(0xFF3B82F6),
                                  borderStrokeWidth: 4,
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              for (int i = 0; i < _polygon.length; i++)
                                Marker(
                                  point: _polygon[i],
                                  width: 20,
                                  height: 20,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedPointIdx = i),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: i == _selectedPointIdx
                                            ? const Color(0xFFF97316)
                                            : const Color(0xFF3B82F6),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Material(
                          color: _isDrawing ? const Color(0xFFF97316) : const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: _toggleDrawing,
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      if (_isDrawing)
                        Positioned(
                          top: 8,
                          left: 56,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _miniAct(l10n.assistantDrawingFinish, _finishDrawing),
                                _miniAct(
                                  l10n.assistantDeleteLastPoint,
                                  _polygon.isEmpty ? null : () => setState(() => _polygon.removeLast()),
                                ),
                                _miniAct(l10n.assistantDrawingCancel, _cancelDrawing, danger: true),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_selectedPointIdx != null && _selectedPointIdx! < _polygon.length)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l10n.assistantMapPoint(
                      _selectedPointIdx! + 1,
                      _polygon[_selectedPointIdx!].latitude.toStringAsFixed(6),
                      _polygon[_selectedPointIdx!].longitude.toStringAsFixed(6),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _polygon.isEmpty ? null : () => setState(() => _polygon.removeLast()),
                    child: Text(l10n.assistantUndoPoint),
                  ),
                  OutlinedButton(
                    onPressed: _polygon.isEmpty ? null : () => setState(() => _polygon.clear()),
                    child: Text(l10n.assistantClearPolygon),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _saving ? null : _onSave,
                  child: Text(_saving ? l10n.assistantSaving : l10n.btnSave),
                ),
                FilledButton.tonal(
                  onPressed: (_activeRequestId == null || _running) ? null : _onRun,
                  child: Text(_running ? l10n.assistantSearching : l10n.assistantSearchMatches),
                ),
                TextButton(
                  onPressed: _activeRequestId == null ? null : _onDelete,
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  child: Text(l10n.btnDelete),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildResultsTable(theme, isDark, active, l10n),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildResultsTable(ThemeData theme, bool isDark, Map<String, dynamic>? activeReq, AppLocalizations l10n) {
    final slice = _matches.take(4).toList();
    final rows = _wantRows(activeReq, l10n);
    final borderCol = theme.dividerColor.withValues(alpha: 0.22);
    final wantTh = isDark ? const Color(0xFF14532D).withValues(alpha: 0.4) : const Color(0xFFDCFCE7);
    final wantTd = isDark ? const Color(0xFF166534).withValues(alpha: 0.14) : const Color(0xFFF0FDF4);
    final varTh = isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFF8FAFC);

    final n = slice.length;
    final colW = <int, TableColumnWidth>{
      0: const FixedColumnWidth(_kResultLeftCol),
    };
    for (var i = 0; i < n; i++) {
      colW[i + 1] = const FixedColumnWidth(_kResultVarCol);
    }
    final tableW = _kResultLeftCol + n * _kResultVarCol;

    return KeyedSubtree(
      key: _resultsKey,
      child: _section(
        _activeRequestId != null ? l10n.assistantMatchResultsForRequest(_activeRequestId!) : l10n.assistantMatchResults,
        isDark,
        theme.cardColor,
        theme.dividerColor.withValues(alpha: 0.25),
        [
          if (slice.isEmpty)
            Text(
              l10n.assistantNoMatchResults,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            )
          else ...[
            Text(
              l10n.assistantTableScrollHint,
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, height: 1.3),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scrollbar(
                controller: _resultsHScroll,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  controller: _resultsHScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: SizedBox(
                    width: tableW,
                    child: Table(
                      columnWidths: colW,
                      border: TableBorder.all(color: borderCol),
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: varTh),
                          children: [
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Container(
                                color: wantTh,
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  l10n.assistantCompareHeader,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF064E3B),
                                  ),
                                ),
                              ),
                            ),
                            for (var e in slice.asMap().entries) _variantHeaderTableCell(theme, e.value, e.key, l10n),
                          ],
                        ),
                        ...rows.map((row) {
                          return TableRow(
                            children: [
                              TableCell(
                                child: ColoredBox(
                                  color: wantTd,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(row.label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(
                                          row.want(),
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFFA7F3D0) : Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              for (final m in slice)
                                _variantDataTableCell(row, m, isDark, theme),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 72),
          ],
        ],
      ),
    );
  }

  TableCell _variantHeaderTableCell(ThemeData theme, Map<String, dynamic> m, int idx, AppLocalizations l10n) {
    final listing = m['listing'] as Map<String, dynamic>?;
    final imgs = listing?['images'] as List?;
    String? first;
    if (imgs != null && imgs.isNotEmpty) {
      final im = imgs.first;
      if (im is Map) first = im['image']?.toString();
    }
    final url = first != null ? getImageUrl(first) : '';
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(l10n.assistantVariantNumber(idx + 1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      width: 120,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _ph(l10n),
                    )
                  : _ph(l10n),
            ),
            const SizedBox(height: 6),
            _scoreBadge(num.tryParse(m['score']?.toString() ?? '0') ?? 0),
            if (listing?['id'] != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.push('/listings/${listing!['id']}'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.btnOpen),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TableCell _variantDataTableCell(_WantRow row, Map<String, dynamic> m, bool isDark, ThemeData theme) {
    final listing = m['listing'] as Map<String, dynamic>?;
    final details = m['details'] as Map<String, dynamic>?;
    final det = details?[row.criteriaKey];
    bool? ok;
    if (det is Map) ok = det['ok'] == true ? true : (det['ok'] == false ? false : null);
    final cellBg = isDark ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface;
    return TableCell(
      child: ColoredBox(
        color: cellBg,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _okCell(ok, isDark: isDark),
              Text(
                row.got(listing),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph(AppLocalizations l10n) => Container(
        width: 120,
        height: 84,
        alignment: Alignment.center,
        color: Colors.black12,
        child: Text(l10n.assistantNoPhoto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      );

  Widget _okCell(bool? ok, {required bool isDark}) {
    Color bg;
    Color fg;
    String ch;
    if (ok == true) {
      bg = isDark ? const Color(0xFF14532D).withValues(alpha: 0.5) : const Color(0xFFECFDF5);
      fg = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46);
      ch = '✓';
    } else if (ok == false) {
      bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.45) : const Color(0xFFFEE2E2);
      fg = isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B);
      ch = '✗';
    } else {
      bg = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
      fg = isDark ? const Color(0xFFE7E5E4) : const Color(0xFF334155);
      ch = '—';
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Text(ch, style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
    );
  }

  List<_WantRow> _wantRows(Map<String, dynamic>? ar, AppLocalizations l10n) {
    return [
      _WantRow(
        'deal_type',
        l10n.assistantLabelDealType,
        () => ar != null && _parseFk(ar['deal_type']) != null
            ? _nameById(_dealTypes, _parseFk(ar['deal_type']))
            : '—',
        (l) => l?['deal_type_name']?.toString() ??
            (l != null && _parseFk(l['deal_type']) != null ? _nameById(_dealTypes, _parseFk(l['deal_type'])) : '—'),
      ),
      _WantRow(
        'property_type',
        l10n.assistantLabelPropertyType,
        () => ar != null && _parseFk(ar['property_type']) != null
            ? _nameById(_propertyTypes, _parseFk(ar['property_type']))
            : '—',
        (l) => l?['property_type_name']?.toString() ??
            (l != null && _parseFk(l['property_type']) != null
                ? _nameById(_propertyTypes, _parseFk(l['property_type']))
                : '—'),
      ),
      _WantRow(
        'city',
        l10n.assistantLabelCity,
        () => ar != null && _parseFk(ar['city']) != null ? _nameById(_cities, _parseFk(ar['city'])) : '—',
        (l) => l != null && _parseFk(l['city']) != null ? _nameById(_cities, _parseFk(l['city'])) : '—',
      ),
      _WantRow(
        'rooms',
        l10n.assistantLabelRoomCount,
        () => ar != null && _parseFk(ar['rooms']) != null ? _roomLabel(_parseFk(ar['rooms'])) : '—',
        (l) => l != null && _parseFk(l['rooms']) != null ? _roomLabel(_parseFk(l['rooms'])) : '—',
      ),
      _WantRow(
        'price',
        l10n.assistantLabelPriceSom,
        () => _fmtRange(l10n, ar?['price_min'], ar?['price_max'], ''),
        (l) {
          final p = l?['price'];
          if (p == null || '$p'.isEmpty) return '—';
          return NumberFormat.decimalPattern('ru_RU').format(num.tryParse(p.toString()) ?? 0);
        },
      ),
      _WantRow(
        'area_total',
        l10n.assistantLabelAreaM2,
        () => _fmtRange(l10n, ar?['area_total_min'], ar?['area_total_max'], ''),
        (l) {
          final v = l?['area_total'];
          return v != null && '$v'.isNotEmpty ? '$v' : '—';
        },
      ),
      _WantRow(
        'area_land',
        l10n.assistantLabelLandSot,
        () => _fmtRange(l10n, ar?['area_land_min'], ar?['area_land_max'], ''),
        (l) {
          final v = l?['area_land'];
          return v != null && '$v'.isNotEmpty ? '$v' : '—';
        },
      ),
      _WantRow(
        'land_type',
        l10n.assistantLabelLandType,
        () => ar?['land_type'] != null && '${ar!['land_type']}'.isNotEmpty ? '${ar['land_type']}' : '—',
        (l) => l?['land_type'] != null && '${l!['land_type']}'.isNotEmpty ? '${l['land_type']}' : '—',
      ),
      _WantRow(
        'commercial_type',
        l10n.assistantLabelCommercial,
        () => ar?['commercial_type'] != null && '${ar!['commercial_type']}'.isNotEmpty ? '${ar['commercial_type']}' : '—',
        (l) => l?['commercial_type'] != null && '${l!['commercial_type']}'.isNotEmpty ? '${l['commercial_type']}' : '—',
      ),
      _WantRow(
        'rental_term',
        l10n.assistantLabelRentalTerm,
        () => ar?['rental_term'] != null && '${ar!['rental_term']}'.isNotEmpty ? '${ar['rental_term']}' : '—',
        (l) => l?['rental_term'] != null && '${l!['rental_term']}'.isNotEmpty ? '${l['rental_term']}' : '—',
      ),
      _WantRow(
        'polygon',
        l10n.assistantLabelGeo,
        () {
          final poly = ar?['polygon'];
          final n = poly is List ? poly.length : 0;
          return n >= 3 ? l10n.assistantPolygonSelected(n) : '—';
        },
        (l) {
          final lat = l?['latitude'];
          final lng = l?['longitude'];
          if (lat != null && lng != null) {
            return 'lat ${double.tryParse(lat.toString())?.toStringAsFixed(4)}, lng ${double.tryParse(lng.toString())?.toStringAsFixed(4)}';
          }
          return '—';
        },
      ),
    ];
  }

  Widget _section(String title, bool isDark, Color cardBg, Color border, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: const Color(0xFFE79A3E), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownIntNullable(
    String label,
    int? val,
    List<Map<String, dynamic>> opts,
    ValueChanged<int?> onChanged, {
    String labelKey = 'name',
  }) {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('—')),
      ...opts.map((d) {
        final id = int.tryParse(d['id']?.toString() ?? '');
        return DropdownMenuItem<int?>(
          value: id,
          child: Text(d[labelKey]?.toString() ?? '#$id'),
        );
      }),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<int?>(
        key: ValueKey('$label-$val-${opts.length}'),
        initialValue: val,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownStrNullable(
    String label,
    String? val,
    List<Map<String, dynamic>> opts,
    ValueChanged<String?> onChanged,
  ) {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('—')),
      ...opts.map((d) {
        final id = d['id']?.toString();
        return DropdownMenuItem<String?>(
          value: id,
          child: Text(d['name']?.toString() ?? id ?? ''),
        );
      }),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String?>(
        key: ValueKey('$label-$val-${opts.length}'),
        initialValue: val,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _miniAct(String t, VoidCallback? onTap, {bool danger = false}) {
    return Material(
      color: danger ? const Color(0xFF7F1D1D) : const Color(0xFF334155),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      ),
    );
  }
}

class _WantRow {
  _WantRow(this.criteriaKey, this.label, this.want, this.got);
  final String criteriaKey;
  final String label;
  final String Function() want;
  final String Function(Map<String, dynamic>?) got;
}
