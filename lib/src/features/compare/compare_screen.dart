import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/compare_provider.dart';
import '../../core/api_client.dart';
import '../../core/compare_storage.dart';

/// Паҳноии сутунҳо
const double _kCompareLabelColWidth = 150;
const double _kCompareListingColWidth = 200;
/// Баландии яксон барои сатри сарлавҳа (чап + ҳар объявление)
const double _kCompareHeaderMinHeight = 248;
const double _kCompareDataRowMinHeight = 52;

String _val(dynamic v) {
  if (v == null || v == '') return '—';
  if (v is Map) {
    final n = v['name'];
    final val = v['value'];
    if (n != null) return n.toString();
    if (val != null) return val.toString();
    return '—';
  }
  return v.toString();
}

String _formatPrice(dynamic v) {
  if (v == null || v == '') return '—';
  final n = v is num ? v.toInt() : int.tryParse(v.toString());
  if (n == null) return v.toString();
  return NumberFormat.decimalPattern('ru_RU').format(n);
}

String _formatDeal(Map<String, dynamic> l) {
  final v = l['deal_type'];
  if (v is Map) return _val(v);
  if (v == 1) return 'Продаётся';
  return 'Аренда';
}

typedef _RowFmt = String Function(Map<String, dynamic> l);

final List<({String label, _RowFmt format})> _kCompareRows = [
  (label: 'Цена (сомони)', format: (l) => _formatPrice(l['price'])),
  (label: 'Сделка', format: _formatDeal),
  (label: 'Тип недвижимости', format: (l) => _val(l['property_type'])),
  (label: 'Комнаты', format: (l) => _val(l['rooms'] is Map ? (l['rooms']['value'] ?? l['rooms']['name']) : l['rooms'])),
  (label: 'Этаж', format: (l) => _val(l['floor'] is Map ? (l['floor']['value'] ?? l['floor']['name']) : l['floor'])),
  (label: 'Этажей в доме', format: (l) => _val(l['floors_in_building'] is Map ? (l['floors_in_building']['value'] ?? l['floors_in_building']['name']) : l['floors_in_building'])),
  (label: 'Площадь общая (м²)', format: (l) => l['area_total'] != null ? '${l['area_total']}' : '—'),
  (label: 'Площадь жилая (м²)', format: (l) => l['area_living'] != null ? '${l['area_living']}' : '—'),
  (label: 'Участок (сот.)', format: (l) => l['area_land'] != null ? '${l['area_land']}' : '—'),
  (label: 'Город', format: (l) => _val(l['city'])),
  (label: 'Махалла', format: (l) => _val(l['mahalla'])),
  (label: 'Ремонт', format: (l) => _val(l['repair'])),
  (label: 'Состояние дома', format: (l) => _val(l['condition'])),
  (label: 'Год постройки', format: (l) => l['construction_year'] != null ? '${l['construction_year']}' : '—'),
  (label: 'Документы', format: (l) => _val(l['document_type'])),
  (label: 'Санузел', format: (l) => _val(l['bathroom'])),
  (label: 'Балкон', format: (l) => _val(l['balcony'])),
  (label: 'Лифт', format: (l) => _val(l['elevator'])),
];

String? _firstImageUrl(Map<String, dynamic> listing) {
  final images = listing['images'];
  if (images is! List || images.isEmpty) return null;
  for (final e in images) {
    if (e is Map && e['image'] != null) {
      final u = getImageUrl(e['image']?.toString());
      if (u.isNotEmpty) return u;
    }
  }
  return null;
}

String _listingTitle(Map<String, dynamic> listing) {
  final r = listing['rooms'];
  final rooms = r is Map ? (r['value'] ?? r['name']) : r;
  final f = listing['floor'];
  final floor = f is Map ? (f['value'] ?? f['name']) : f;
  final a = listing['area_total'];
  final parts = <String>[];
  if (rooms != null) parts.add('$rooms комн.');
  if (floor != null) parts.add('$floor эт.');
  if (a != null) parts.add('$a м²');
  return parts.isNotEmpty ? parts.join(', ') : 'Объявление #${listing['id']}';
}

/// Саҳифаи сравнение — монанди `Compare.jsx`.
class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(compareIdsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa);
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF1a1a1a);
    final muted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    const orange = Color(0xFFe79a3e);

    if (ids == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (ids.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.balance_rounded, size: 64, color: orange.withValues(alpha: 0.9)),
                  const SizedBox(height: 20),
                  Text('Сравнение объявлений', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 12),
                  Text(
                    'Добавьте до $kMaxCompareListings объявлений с карточки или страницы объявления (кнопка весов), чтобы сравнить их здесь.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.5, color: muted),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      context.go('/listings');
                    },
                    style: FilledButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                    child: const Text('Перейти к объявлениям'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _CompareLoadedBody(ids: ids, bg: bg, text: text, muted: muted, orange: orange, isDark: isDark),
      ),
    );
  }
}

class _CompareLoadedBody extends ConsumerStatefulWidget {
  const _CompareLoadedBody({
    required this.ids,
    required this.bg,
    required this.text,
    required this.muted,
    required this.orange,
    required this.isDark,
  });

  final List<int> ids;
  final Color bg;
  final Color text;
  final Color muted;
  final Color orange;
  final bool isDark;

  @override
  ConsumerState<_CompareLoadedBody> createState() => _CompareLoadedBodyState();
}

class _CompareLoadedBodyState extends ConsumerState<_CompareLoadedBody> {
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CompareLoadedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ids.join(',') != widget.ids.join(',')) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final out = <Map<String, dynamic>>[];
    for (final id in widget.ids) {
      try {
        final r = await dio.get('/api/listings/$id/');
        if (r.data is Map) {
          out.add(Map<String, dynamic>.from(r.data as Map));
        }
      } on DioException catch (_) {
        // пропуск
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _listings = out;
      _loading = false;
    });
  }

  Future<void> _remove(int id) async {
    if (id <= 0) return;
    await ref.read(compareIdsProvider.notifier).remove(id);
    setState(() {
      _listings = _listings.where((l) {
        final lid = l['id'];
        final i = lid is int ? lid : int.tryParse(lid?.toString() ?? '');
        return i != id;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.isDark ? const Color(0xFF171717) : Colors.white;
    final border = widget.isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final labelBg = widget.isDark ? const Color(0xFF121212) : const Color(0xFFf0f0f2);

    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Сравнение объявлений', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: widget.text)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Не удалось загрузить объявления.', style: TextStyle(color: widget.muted)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.balance_rounded, color: widget.orange, size: 28),
                  const SizedBox(width: 10),
                  Text('Сравнение', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: widget.text)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Сравните выбранные объявления по основным параметрам', style: TextStyle(fontSize: 14, color: widget.muted)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Сутуни параметрҳо — ҷойгир, скроли амудӣ бо ҳамон `SingleChildScrollView`-и берун
                    ColoredBox(
                      color: labelBg,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: border.withValues(alpha: 0.7))),
                        ),
                        child: SizedBox(
                          width: _kCompareLabelColWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _compareLabelHeader(border, widget.text),
                              ..._kCompareRows.map((row) => _compareLabelRow(row.label, border, widget.text)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Фақат ин ҷо скроли чап/рост — бе `Table` + nested scroll
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: _listings.length > 1,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _listings.map((l) {
                              final rid = l['id'];
                              final iid = rid is int ? rid : int.tryParse(rid?.toString() ?? '') ?? 0;
                              return _compareListingColumn(
                                context,
                                l,
                                card,
                                border,
                                widget.text,
                                widget.muted,
                                widget.orange,
                                () => _remove(iid),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Center(
            child: OutlinedButton(
              onPressed: () => context.go('/listings'),
              style: OutlinedButton.styleFrom(foregroundColor: widget.text, side: BorderSide(color: border)),
              child: const Text('Добавить ещё объявления'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compareLabelHeader(Color border, Color text) {
    return SizedBox(
      height: _kCompareHeaderMinHeight,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.7))),
        ),
        alignment: Alignment.topLeft,
        child: Text('Параметр', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: text)),
      ),
    );
  }

  Widget _compareLabelRow(String label, Color border, Color text) {
    return SizedBox(
      height: _kCompareDataRowMinHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.7))),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: text, height: 1.2),
        ),
      ),
    );
  }

  Widget _compareListingColumn(
    BuildContext context,
    Map<String, dynamic> listing,
    Color card,
    Color border,
    Color text,
    Color muted,
    Color orange,
    VoidCallback onRemove,
  ) {
    final id = listing['id'];
    final url = _firstImageUrl(listing);
    return SizedBox(
      width: _kCompareListingColWidth,
      child: ColoredBox(
        color: card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _kCompareHeaderMinHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: border.withValues(alpha: 0.7)),
                    bottom: BorderSide(color: border.withValues(alpha: 0.7)),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () => context.push('/listings/$id'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: url != null
                                  ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph(muted))
                                  : _ph(muted),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _listingTitle(listing),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatPrice(listing['price'])} с.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: orange),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onRemove,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(width: 28, height: 28, child: Icon(Icons.close, color: Colors.white, size: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ..._kCompareRows.map((row) {
              return SizedBox(
                height: _kCompareDataRowMinHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: border.withValues(alpha: 0.7)),
                      bottom: BorderSide(color: border.withValues(alpha: 0.7)),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    row.format(listing),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: text, fontSize: 13, height: 1.2),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _ph(Color muted) {
    return Container(
      color: const Color(0xFF1f2937),
      alignment: Alignment.center,
      child: Text('Нет фото', style: TextStyle(fontSize: 12, color: muted)),
    );
  }
}
