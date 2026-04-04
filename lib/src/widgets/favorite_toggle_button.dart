import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/favorites_count_provider.dart';
import '../core/api_client.dart';
import '../core/auth_storage.dart';

/// Тугмаи сердсача: POST/DELETE `/api/listings/:id/favorite/`, invalidate шумораи избранного.
class FavoriteToggleButton extends ConsumerStatefulWidget {
  const FavoriteToggleButton({
    super.key,
    required this.listingId,
    required this.initialFavorited,
    this.circularBackground = true,
    this.iconSize = 18,
    this.compactSize = 30,
    this.iconColorWhenOutline,
    this.onFavoritedChanged,
  });

  final int? listingId;
  final bool initialFavorited;
  final bool circularBackground;
  final double iconSize;
  final double compactSize;
  /// Ранги иконка ҳангоми outline (масалан дар саҳифаи тафсилот — `muted`).
  final Color? iconColorWhenOutline;
  /// Баъд аз муваффақияти API — барои аз рӯйхат баровардан дар саҳифаи избранное.
  final void Function(int? listingId, bool isFavorited)? onFavoritedChanged;

  @override
  ConsumerState<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends ConsumerState<FavoriteToggleButton> {
  late bool _favorited;
  bool _busy = false;

  static const _accentOrange = Color(0xFFe79a3e);
  static const _mutedIcon = Color(0xFF555555);

  @override
  void initState() {
    super.initState();
    _favorited = widget.initialFavorited;
  }

  @override
  void didUpdateWidget(FavoriteToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId || oldWidget.initialFavorited != widget.initialFavorited) {
      _favorited = widget.initialFavorited;
    }
  }

  Future<void> _onTap() async {
    final id = widget.listingId;
    if (id == null || _busy) return;
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Войдите в аккаунт, чтобы добавить в избранное.')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      if (_favorited) {
        await dio.delete('/api/listings/$id/favorite/');
        if (mounted) setState(() => _favorited = false);
      } else {
        await dio.post('/api/listings/$id/favorite/');
        if (mounted) setState(() => _favorited = true);
      }
      ref.invalidate(favoritesCountProvider);
      widget.onFavoritedChanged?.call(id, _favorited);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Войдите в аккаунт.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?.toString() ?? 'Не удалось обновить избранное')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка сети')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outlineColor = widget.iconColorWhenOutline ?? _mutedIcon;
    final icon = Icon(
      _favorited ? Icons.favorite : Icons.favorite_border,
      size: widget.iconSize,
      color: _favorited ? _accentOrange : outlineColor,
    );
    if (!widget.circularBackground) {
      return InkWell(
        onTap: _busy ? null : _onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: _busy ? SizedBox(width: widget.iconSize, height: widget.iconSize, child: const CircularProgressIndicator(strokeWidth: 2)) : icon,
        ),
      );
    }
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _busy ? null : _onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: widget.compactSize,
          height: widget.compactSize,
          child: Center(
            child: _busy
                ? SizedBox(width: widget.iconSize - 4, height: widget.iconSize - 4, child: const CircularProgressIndicator(strokeWidth: 2))
                : icon,
          ),
        ),
      ),
    );
  }
}
