import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../widgets/shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _err;
  List<Map<String, dynamic>> _news = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      // если токен есть — будет фильтр по роли; иначе вернём общие новости
      final t = await getAccessToken();
      if (t == null || t.isEmpty) {
        // no-op: interceptor сам добавит header только если есть токен
      }
      final r = await dio.get('/api/listings/push-news/');
      final raw = r.data;
      final list = raw is List ? raw : <dynamic>[];
      final out = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is Map) out.add(Map<String, dynamic>.from(e));
      }
      if (!mounted) return;
      setState(() {
        _news = out;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _err = messageFromDioException(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa);
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);
    final card = isDark ? const Color(0xFF1c1c1e) : Colors.white;
    final border = isDark ? const Color(0xFF3a3a3c) : const Color(0xFFe5e5ea);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Уведомления', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: _loading
            ? ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const ShimmerBox(height: 96, radius: 16),
              )
            : _err != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(_err!, style: TextStyle(color: text)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadNews, child: const Text('Повторить')),
                    ],
                  )
                : _news.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text('Пока нет новостей.', style: TextStyle(color: muted)),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _news.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final n = _news[i];
                          final title = (n['title'] ?? '').toString();
                          final body = (n['body'] ?? '').toString();
                          final img = (n['image_url'] ?? '').toString().trim();
                          final dt = DateTime.tryParse((n['created_at'] ?? '').toString());
                          final time = dt == null
                              ? ''
                              : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          return _NewsCard(
                            card: card,
                            border: border,
                            text: text,
                            muted: muted,
                            title: title,
                            body: body,
                            imageUrl: img,
                            time: time,
                          );
                        },
                      ),
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  const _NewsCard({
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.time,
  });

  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final String title;
  final String body;
  final String imageUrl;
  final String time;

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final showExpand = widget.body.length > 110;
    final preview = showExpand && !_expanded ? '${widget.body.substring(0, 110)}…' : widget.body;

    return Container(
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(color: widget.text, fontWeight: FontWeight.w900, fontSize: 16, height: 1.2),
                  ),
                ),
                if (widget.time.isNotEmpty)
                  Text(widget.time, style: TextStyle(color: widget.muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (preview.isNotEmpty)
              Text(
                preview,
                style: TextStyle(color: widget.muted, fontSize: 14, height: 1.35),
              ),
            if (showExpand) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Развернуть', style: TextStyle(color: const Color(0xFF22c55e), fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF22c55e)),
                  ],
                ),
              ),
            ],
            if (widget.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported, color: widget.muted),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

