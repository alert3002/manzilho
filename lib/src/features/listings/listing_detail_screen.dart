import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/compare_provider.dart';
import '../../app/theme.dart';
import '../../core/compare_storage.dart';
import '../../widgets/drawer_header_logo.dart';
import '../../widgets/favorite_toggle_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../home/widgets/listing_card.dart';

/// Саҳифаи тафсилоти объявление — маълумот аз API /api/listings/:id/
class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _listing;
  List<Map<String, dynamic>> _similar = [];
  bool _loading = true;
  int _currentImage = 0;

  Drawer _buildDrawer() {
    final compareIds = ref.watch(compareIdsProvider);
    final compareCount = compareIds?.length ?? 0;
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeaderLogo(),
          ListTile(
            title: const Text('Главная'),
            leading: const Icon(Icons.home_outlined),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            title: const Text('Поиск'),
            leading: const Icon(Icons.search),
            onTap: () {
              Navigator.pop(context);
              context.go('/listings');
            },
          ),
          ListTile(
            title: const Text('Сравнение'),
            leading: const Icon(Icons.balance),
            trailing: compareCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: manzilhoOrange, borderRadius: BorderRadius.circular(12)),
                    child: Text('$compareCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              context.go('/compare');
            },
          ),
          ListTile(
            title: const Text('Умный помощник'),
            leading: const Icon(Icons.smart_toy),
            onTap: () {
              Navigator.pop(context);
              context.go('/assistant');
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Профиль'),
            leading: const Icon(Icons.person_outline),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          ListTile(
            title: const Text('Настройка'),
            leading: const Icon(Icons.settings_outlined),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          ListTile(
            title: const Text('Push-уведомления'),
            leading: const Icon(Icons.notifications_active_outlined),
            onTap: () {
              Navigator.pop(context);
              context.go('/push-notifications');
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.id.isEmpty) {
      setState(() { _loading = false; _listing = null; });
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await dio.get('/api/listings/${widget.id}/');
      final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : null;
      setState(() {
        _listing = data;
        _loading = false;
      });
      if (data != null) _loadSimilar();
    } catch (_) {
      setState(() { _listing = null; _loading = false; });
    }
  }

  Future<void> _loadSimilar() async {
    try {
      final r = await dio.get('/api/listings/list/');
      final list = r.data is List ? r.data as List : [];
      final maps = list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      final id = _listing?['id'];
      final filtered = maps.where((m) => m['id'] != id).take(4).toList();
      setState(() => _similar = filtered);
    } catch (_) {}
  }

  List<String> _imageUrls() {
    final images = _listing?['images'];
    if (images is! List || images.isEmpty) return [];
    final urls = <String>[];
    for (final e in images) {
      if (e is Map && e['image'] != null) {
        final u = getImageUrl(e['image']?.toString());
        if (u.isNotEmpty) urls.add(u);
      }
    }
    return urls;
  }

  String _title() {
    final l = _listing;
    if (l == null) return 'Объявление';
    final parts = <String>[];
    final rooms = l['rooms'];
    if (rooms is Map && rooms['value'] != null) parts.add('${rooms['value']} комн.');
    parts.add(_name(l['property_type']) ?? 'квартира');
    if (rooms is! Map && rooms != null) parts.add('$rooms комн.');
    final floor = l['floor'];
    if (floor is Map && floor['value'] != null) parts.add('${floor['value']} этаж');
    if (l['area_total'] != null) parts.add('${l['area_total']} м²');
    parts.add(_name(l['mahalla']) ?? _name(l['city']) ?? '');
    return parts.where((s) => s.isNotEmpty).join(', ');
  }

  String? _name(dynamic o) {
    if (o is Map && o['name'] != null) return o['name'].toString();
    return null;
  }

  String _price() {
    final p = _listing?['price'];
    if (p == null) return '—';
    final n = p is num ? p.toInt() : int.tryParse(p.toString());
    if (n == null) return p.toString();
    return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  String _phoneNumber() {
    final s = _listing?['contact_phone_secondary']?.toString();
    if (s != null && s.trim().isNotEmpty) return s.trim();
    final u = _listing?['owner_username']?.toString();
    if (u != null && RegExp(r'[\d+]').hasMatch(u)) return u;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa);
    final card = isDark ? const Color(0xFF171717) : Colors.white;
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF1a1a1a);
    final muted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final accent = const Color(0xFF2563eb);
    final accentDark = const Color(0xFF1e40af);

    if (_loading) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: bg,
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2c2c2c),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          actions: [
            IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_listing == null) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: bg,
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2c2c2c),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          actions: [
            IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          ],
        ),
        body: Center(child: Text('Объявление не найдено.', style: TextStyle(color: muted))),
      );
    }

    final images = _imageUrls();
    final mainImage = images.isNotEmpty ? images[_currentImage.clamp(0, images.length - 1)] : null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c2c2c),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: const Text('Объявление', style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
              final title = _title();
              final url = 'https://manzilho.tj/listings/${widget.id}';
              try {
                await Share.share('$title\n$url');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Поделиться'), duration: Duration(seconds: 2)),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Поделиться'), duration: Duration(seconds: 2)),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_title(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('L#${_listing!['id']}', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                      if (images.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.camera_alt, size: 14, color: muted), const SizedBox(width: 4), Text('${images.length} фото', style: TextStyle(fontSize: 13, color: muted))]),
                      if (_listing!['view_count'] != null && (_listing!['view_count'] as num) > 0) Text('${_listing!['view_count']} просмотров', style: TextStyle(fontSize: 13, color: muted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
                        child: Text(_listing!['deal_type'] == 1 || _name(_listing!['deal_type']) == 'Продам' ? 'Продаётся' : 'Аренда', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final ids = ref.watch(compareIdsProvider);
                    final lidRaw = _listing!['id'];
                    final lid = lidRaw is int ? lidRaw : int.tryParse(lidRaw?.toString() ?? '');
                    if (lid == null) return const SizedBox.shrink();
                    final inCompare = ids?.contains(lid) ?? false;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(Icons.balance, size: 22, color: inCompare ? const Color(0xFFe79a3e) : muted),
                      onPressed: () async {
                        final ok = await ref.read(compareIdsProvider.notifier).toggle(lid);
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('В сравнении уже $kMaxCompareListings объявлений')),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 4),
                FavoriteToggleButton(
                  listingId: _listing!['id'] is int ? _listing!['id'] as int : int.tryParse(_listing!['id']?.toString() ?? ''),
                  initialFavorited: _listing!['is_favorited'] == true,
                  circularBackground: false,
                  iconSize: 22,
                  iconColorWhenOutline: muted,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gallery
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb))),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mainImage != null)
                      Image.network(mainImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1f2937), child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54)))),
                    if (mainImage == null) Container(color: const Color(0xFF1f2937), child: Center(child: Text('Нет фото', style: TextStyle(color: muted)))),
                    if (images.length > 1) ...[
                      Positioned(left: 12, top: 0, bottom: 0, child: Center(child: _NavBtn(icon: Icons.chevron_left, onTap: () => setState(() => _currentImage = (_currentImage - 1 + images.length) % images.length)))),
                      Positioned(right: 12, top: 0, bottom: 0, child: Center(child: _NavBtn(icon: Icons.chevron_right, onTap: () => setState(() => _currentImage = (_currentImage + 1) % images.length)))),
                    ]
                  ],
                ),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length > 5 ? 5 : images.length,
                  itemBuilder: (_, i) {
                    final active = i == _currentImage;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _currentImage = i),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: active ? accent : Colors.transparent, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(images[i], fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Price — камонанд расм: кабуд камар, матни сафед, «Торг уместен» зери нарх
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent, width: 2)),
              child: Column(
                children: [
                  Text('${_price()} с.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: text)),
                  if (_listing!['negotiation_status'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _listing!['negotiation_status'] == 'fixed' ? 'Не подлежит торгу' : 'Торг уместен',
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // О объекте
            _Block(
              title: 'О объекте',
              child: _SpecGrid(listing: _listing!, name: _name, text: text, muted: muted),
            ),

            // Description
            if (_listing!['description'] != null && (_listing!['description'] as String).trim().isNotEmpty)
              _Block(title: 'Описание', child: Text(_listing!['description'].toString(), style: TextStyle(fontSize: 14, height: 1.65, color: text))),

            // Контакт: рақам бо tel: кликабел, фақат тугмаи Написать
            _Block(
              title: 'Контакт',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: accent,
                        backgroundImage: _listing!['owner_avatar'] != null && getImageUrl(_listing!['owner_avatar']?.toString()).isNotEmpty
                            ? NetworkImage(getImageUrl(_listing!['owner_avatar']?.toString()))
                            : null,
                        child: _listing!['owner_avatar'] == null ? Text((_listing!['owner_name'] ?? _listing!['owner_username'] ?? 'А').toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_listing!['owner_organization'] ?? _listing!['owner_name'] ?? _listing!['owner_username'] ?? 'Агент', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accent))),
                    ],
                  ),
                  if (_phoneNumber().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final phone = _phoneNumber().replaceAll(RegExp(r'[\s\-\(\)]'), '');
                        final uri = Uri(scheme: 'tel', path: phone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: accent),
                            const SizedBox(width: 10),
                            Text(_phoneNumber(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accent, decoration: TextDecoration.underline, decorationColor: accent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final token = await getAccessToken();
                        if (token == null || token.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Войдите в аккаунт, чтобы написать продавцу.')),
                            );
                          }
                          return;
                        }
                        final listingId = _listing!['id'];
                        if (listingId == null) return;
                        try {
                          final r = await dio.post(
                            '/api/listings/conversations/create/',
                            data: {'listing_id': listingId is int ? listingId : int.tryParse(listingId.toString())},
                          );
                          final data = r.data is Map ? r.data as Map : <String, dynamic>{};
                          final convId = data['id'];
                          if (mounted && convId != null) {
                            context.go('/messages?conversation=$convId');
                          }
                        } on DioException catch (e) {
                          if (mounted) {
                            final msg = e.response?.data is Map ? (e.response!.data as Map)['error']?.toString() : null;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg ?? 'Не удалось начать чат.')),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Не удалось начать чат.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Написать'),
                      style: ElevatedButton.styleFrom(backgroundColor: accentDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),

            // Similar
            if (_similar.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Похожие объявления', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _similar.length,
                  itemBuilder: (_, i) {
                    return SizedBox(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ListingCard(listing: _similar[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 44, height: 44, child: Center(child: Icon(icon, color: Colors.white, size: 28)))),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF171717) : Colors.white;
    final border = isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF1a1a1a);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.listing, required this.name, required this.text, required this.muted});
  final Map<String, dynamic> listing;
  final String? Function(dynamic) name;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final specs = <_Spec>[];
    if (name(listing['property_type']) != null) specs.add(_Spec('Тип', name(listing['property_type'])!));
    if (listing['area_total'] != null) specs.add(_Spec('Площадь общая', '${listing['area_total']} м²'));
    if (listing['area_living'] != null) specs.add(_Spec('Площадь жилая', '${listing['area_living']} м²'));
    if (listing['rooms'] != null) {
      final r = listing['rooms'];
      specs.add(_Spec('Комнат', (r is Map && r['value'] != null) ? r['value'].toString() : r.toString()));
    }
    if (listing['floor'] != null) {
      final f = listing['floor'];
      specs.add(_Spec('Этаж', (f is Map && f['value'] != null) ? f['value'].toString() : f.toString()));
    }
    if (listing['floors_in_building'] != null) {
      final fb = listing['floors_in_building'];
      specs.add(_Spec('Этажей в доме', (fb is Map && fb['value'] != null) ? fb['value'].toString() : fb.toString()));
    }
    if (listing['construction_year'] != null) specs.add(_Spec('Год постройки', listing['construction_year'].toString()));
    if (name(listing['repair']) != null) specs.add(_Spec('Ремонт', name(listing['repair'])!));
    if (name(listing['condition']) != null) specs.add(_Spec('Состояние', name(listing['condition'])!));

    if (specs.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 24,
      runSpacing: 14,
      children: specs.map((s) => SizedBox(width: 160, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(s.label.toUpperCase(), style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w500, letterSpacing: 0.5)), const SizedBox(height: 2), Text(s.value, style: TextStyle(fontSize: 13, color: text))]))).toList(),
    );
  }
}

class _Spec {
  _Spec(this.label, this.value);
  final String label;
  final String value;
}
