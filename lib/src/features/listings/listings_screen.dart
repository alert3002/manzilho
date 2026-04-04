import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_footer_info.dart';
import '../../widgets/shimmer.dart';
import '../home/widgets/listing_card.dart';

/// Саҳифаи рӯйхат + ҷустуҷӯ (`?search=`) — API `/api/listings/list/`
class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _lastRouteKey;

  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = GoRouterState.of(context).uri.toString();
    if (_lastRouteKey != key) {
      _lastRouteKey = key;
      final q = GoRouterState.of(context).uri.queryParameters['search'] ?? '';
      if (_searchCtrl.text != q) {
        _searchCtrl.text = q;
      }
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = GoRouterState.of(context);
      final ownerId = state.uri.queryParameters['owner_id'];
      final search = state.uri.queryParameters['search']?.trim();
      final qp = <String, dynamic>{};
      if (ownerId != null && ownerId.isNotEmpty) qp['owner_id'] = ownerId;
      if (search != null && search.isNotEmpty) qp['search'] = search;

      final r = await dio.get(
        '/api/listings/list/',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final raw = r.data;
      final list = ensureArray<dynamic>(raw);
      final maps = list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();

      if (!mounted) return;
      setState(() {
        _listings = maps;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _listings = [];
        _loading = false;
        _error = e.message ?? 'Ошибка сети';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listings = [];
        _loading = false;
        _error = 'Не удалось загрузить';
      });
    }
  }

  void _applySearch() {
    final t = _searchCtrl.text.trim();
    final state = GoRouterState.of(context);
    final ownerId = state.uri.queryParameters['owner_id'];
    if (t.isEmpty) {
      if (ownerId != null && ownerId.isNotEmpty) {
        context.go(Uri(path: '/listings', queryParameters: {'owner_id': ownerId}).toString());
      } else {
        context.go('/listings');
      }
      return;
    }
    final qp = <String, String>{'search': t};
    if (ownerId != null && ownerId.isNotEmpty) qp['owner_id'] = ownerId;
    context.go(Uri(path: '/listings', queryParameters: qp).toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa);
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);
    final state = GoRouterState.of(context);
    final ownerId = state.uri.queryParameters['owner_id'];
    final searchQ = state.uri.queryParameters['search']?.trim();
    final hasSearch = searchQ != null && searchQ.isNotEmpty;

    final title = ownerId != null
        ? 'Объявления автора'
        : (hasSearch ? 'Поиск' : 'Объявления');
    final subtitle = ownerId != null
        ? 'Все предложения выбранного риелтора / агентства / застройщика'
        : (hasSearch ? 'Результаты по запросу «$searchQ»' : 'Обычные объявления');

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: manzilhoOrange,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: text,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: muted,
                        height: 1.3,
                      ),
                    ),
                    if (ownerId != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.go('/listings'),
                        child: const Text('Показать объявления всех авторов'),
                      ),
                    ],
                    if (ownerId == null) ...[
                      const SizedBox(height: 14),
                      Material(
                        color: isDark ? const Color(0xFF1c1c1e) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: manzilhoOrange.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: TextStyle(color: text, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Город, адрес, описание…',
                                    hintStyle: TextStyle(color: muted, fontSize: 15),
                                    prefixIcon: Icon(Icons.search_rounded, color: muted),
                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear_rounded, color: muted),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() {});
                                              context.go('/listings');
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _applySearch(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilledButton(
                                  onPressed: _applySearch,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: manzilhoOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Найти', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF111111) : Colors.white),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: ShimmerBox(radius: 14),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(10, 0, 10, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(height: 14, radius: 10),
                                  SizedBox(height: 8),
                                  ShimmerBox(height: 12, width: 120, radius: 10),
                                  SizedBox(height: 10),
                                  ShimmerBox(height: 12, width: 80, radius: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    childCount: 8,
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 56, color: muted),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 15)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(backgroundColor: manzilhoOrange, foregroundColor: Colors.white),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_listings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 72, color: muted.withValues(alpha: 0.85)),
                        const SizedBox(height: 20),
                        Text(
                          hasSearch ? 'Ничего не найдено.' : 'Объявлений пока нет.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                        if (!hasSearch && ownerId == null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Загляните позже или введите запрос выше.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: muted.withValues(alpha: 0.85), height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ListingCard(listing: _listings[i]),
                    childCount: _listings.length,
                  ),
                ),
              ),
            if (!_loading && _error == null && _listings.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: AppFooterInfo(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
