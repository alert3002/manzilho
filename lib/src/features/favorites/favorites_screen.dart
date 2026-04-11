import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/favorites_count_provider.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/post_auth_redirect.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../../widgets/shimmer.dart';
import '../home/widgets/listing_card.dart';

/// Саҳифаи алоҳидаи избранное: рӯйхати объявлений аз API, ё паём барои бе логин.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _checking = true;
  bool _loggedIn = false;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await getAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _checking = false;
        _loggedIn = false;
      });
      return;
    }
    setState(() {
      _checking = false;
      _loggedIn = true;
      _loading = true;
    });
    await _loadList();
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await dio.get('/api/listings/favorites/');
      final raw = r.data;
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['results'] is List) {
        list = raw['results'] as List;
      } else {
        list = [];
      }
      final maps = list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      if (!mounted) return;
      setState(() {
        _items = maps;
        _loading = false;
      });
      ref.invalidate(favoritesCountProvider);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (!mounted) return;
        setState(() {
          _loggedIn = false;
          _loading = false;
          _items = [];
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context).favoritesLoadError;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).networkError;
        _loading = false;
      });
    }
  }

  void _onFavoriteChanged(int listingId, bool isFavorited) {
    if (!isFavorited) {
      setState(() {
        _items = _items.where((m) => m['id'] != listingId).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa);
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF1a1a1a);
    final muted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final accent = const Color(0xFF2563eb);

    if (_checking) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(height: 22, width: 140, radius: 12),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    children: const [
                      ShimmerBox(radius: 16),
                      ShimmerBox(radius: 16),
                      ShimmerBox(radius: 16),
                      ShimmerBox(radius: 16),
                      ShimmerBox(radius: 16),
                      ShimmerBox(radius: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_loggedIn) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('❤️ ${l10n.titleFavorites}', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 12),
                Text(
                  l10n.favoritesLoginPrompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: muted),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
                  style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
                  child: Text(l10n.btnLogin),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(l10n.titleFavorites, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text)),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadList,
                child: _loading && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && _items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(child: Text(_error!, style: TextStyle(color: muted))),
                              const SizedBox(height: 16),
                              TextButton(onPressed: _loadList, child: Text(l10n.btnRetry)),
                            ],
                          )
                        : _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                  Icon(Icons.favorite_border, size: 56, color: muted),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.favoritesEmpty,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: muted, fontSize: 14),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                physics: const AlwaysScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.62,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                ),
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final listing = _items[i];
                                  final map = Map<String, dynamic>.from(listing);
                                  map['is_favorited'] = true;
                                  return ListingCard(
                                    listing: map,
                                    onFavoriteChanged: _onFavoriteChanged,
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
