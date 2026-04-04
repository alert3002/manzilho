import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/compare_provider.dart';
import '../../../core/api_client.dart';
import '../../../core/compare_storage.dart';
import '../../../widgets/favorite_toggle_button.dart';

/// Карточка объявления — ба монанди веб ва расм: тема торик, таг, слайдер расм, нарх, маълумот, макон, агент.
class ListingCard extends ConsumerStatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onFavoriteChanged,
  });

  final Map<String, dynamic> listing;
  /// Баъд аз иваз кардани избранное (масалан барои аз рӯйхат баровардан дар `/favorites`).
  final void Function(int listingId, bool isFavorited)? onFavoriteChanged;

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _imageUrls() {
    final images = widget.listing['images'];
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

  String _price() {
    final p = widget.listing['price'];
    if (p == null) return '—';
    final n = p is num ? p.toInt() : int.tryParse(p.toString());
    if (n == null) return p.toString();
    return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  String _dealTag() {
    final deal = widget.listing['deal_type'];
    if (deal == 1) return 'Продаётся';
    return 'Аренда';
  }

  String _details() {
    final r = widget.listing['rooms'];
    final rooms = r is Map ? r['value'] ?? r : r;
    final f = widget.listing['floor'];
    final floor = f is Map ? f['value'] ?? f : f;
    final area = widget.listing['area_total'];
    final parts = <String>[];
    if (rooms != null && rooms.toString().isNotEmpty) parts.add('${rooms} комн. кв');
    if (floor != null && floor.toString().isNotEmpty) parts.add('$floor эт');
    if (area != null && area.toString().isNotEmpty) parts.add('$area м²');
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String _city() {
    final c = widget.listing['city'];
    if (c is Map) return c['name']?.toString() ?? '';
    return c?.toString() ?? '';
  }

  String _mahalla() {
    final m = widget.listing['mahalla'];
    if (m is Map) return m['name']?.toString() ?? '';
    return m?.toString() ?? '';
  }

  String _ownerName() {
    return widget.listing['owner_organization']?.toString() ??
        widget.listing['owner_name']?.toString() ??
        widget.listing['owner_username']?.toString() ??
        'Агентство';
  }

  String? _ownerAvatarUrl() {
    final a = widget.listing['owner_avatar']?.toString();
    return a != null && a.isNotEmpty ? getImageUrl(a) : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2c2c2c) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final secondaryColor = isDark ? const Color(0xFF9ca3af) : const Color(0xFF888888);
    final borderColor = isDark ? const Color(0xFF404040) : const Color(0xFFe0e0e0);

    final images = _imageUrls();
    final hasImages = images.isNotEmpty;
    final listingIdRaw = widget.listing['id'];
    final listingId = listingIdRaw is int ? listingIdRaw : int.tryParse(listingIdRaw?.toString() ?? '');
    final isFavorited = widget.listing['is_favorited'] == true;
    final compareIds = ref.watch(compareIdsProvider);
    final inCompare = listingId != null && (compareIds?.contains(listingId) ?? false);
    const compareOrange = Color(0xFFe79a3e);

    void openListing() {
      final id = widget.listing['id'];
      if (id != null) {
        context.push('/listings/$id');
      } else {
        context.push('/listings');
      }
    }

    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Расмҳо: PageView бояд берун аз InkWell бошад, вагарна слайдер кор намекунад.
          AspectRatio(
            aspectRatio: 1.2,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImages)
                    PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _currentImageIndex = i),
                      itemCount: images.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: openListing,
                        behavior: HitTestBehavior.opaque,
                        child: Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1f2937), child: const Icon(Icons.image_not_supported, color: Colors.white54)),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: openListing,
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: const Color(0xFF1f2937), child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54))),
                    ),
                  // таг: Аренда / Продаётся
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0066ff), borderRadius: BorderRadius.circular(4)),
                      child: Text(_dealTag(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // тугмаҳо: муқоиса + избранное
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: listingId == null
                                ? null
                                : () async {
                                    final ok = await ref.read(compareIdsProvider.notifier).toggle(listingId);
                                    if (!mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('В сравнении уже $kMaxCompareListings объявлений')),
                                      );
                                    }
                                  },
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Center(child: Icon(Icons.balance, size: 16, color: inCompare ? compareOrange : const Color(0xFF555555))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FavoriteToggleButton(
                          listingId: listingId,
                          initialFavorited: isFavorited,
                          circularBackground: true,
                          iconSize: 18,
                          compactSize: 30,
                          onFavoritedChanged: (id, favorited) {
                            if (id != null) widget.onFavoriteChanged?.call(id, favorited);
                          },
                        ),
                      ],
                    ),
                  ),
                  // шумораи расмҳо
                  if (images.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.camera_alt, size: 12, color: Colors.white), const SizedBox(width: 4), Text('${images.length}', style: const TextStyle(color: Colors.white, fontSize: 10))]),
                      ),
                    ),
                  // нуқтаҳои слайдер
                  if (images.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length > 10 ? 10 : images.length, (i) {
                          final activeIndex = images.length > 10 ? _currentImageIndex.clamp(0, 9) : _currentImageIndex;
                          final active = i == activeIndex;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 8 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: active ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: active ? BorderRadius.circular(3) : null,
                              color: Colors.white.withValues(alpha: active ? 1 : 0.6),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Қисми матн — InkWell (тап ба тафсилот), бе таъсир ба слайдери расм.
          Material(
            color: cardBg,
            child: InkWell(
              onTap: openListing,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('${_price()} с.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0066ff))),
                  const SizedBox(height: 4),
                  Text(_details(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_city()}${_mahalla().isNotEmpty ? ', ${_mahalla()}' : ''}',
                          style: TextStyle(fontSize: 11, color: secondaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF0066ff),
                        backgroundImage: _ownerAvatarUrl() != null ? NetworkImage(_ownerAvatarUrl()!) : null,
                        child: _ownerAvatarUrl() == null ? Text(_ownerName().isNotEmpty ? _ownerName()[0].toUpperCase() : 'А', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)) : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_ownerName(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
