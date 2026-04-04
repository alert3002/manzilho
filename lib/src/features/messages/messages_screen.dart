import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/unread_messages_provider.dart';
import '../../core/api_client.dart';
import '../../core/post_auth_redirect.dart';

/// Саҳифаи «Сообщения» — рӯйхати чатҳо + чат; дар мобил рӯйхат пурра, чат алоҳида бо «назад».
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key, this.initialConversationId});

  final int? initialConversationId;

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _conversationsLoading = true;
  int? _selectedId;
  List<Map<String, dynamic>> _messages = [];
  bool _messagesLoading = false;
  final _sendController = TextEditingController();
  bool _sending = false;
  int? _currentUserId;
  bool _unauthorized = false;

  static const double _wideBreakpoint = 820;

  static int? _parseUserId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  bool _isOwnMessage(Map<String, dynamic> m) {
    final sid = _parseUserId(m['sender_id']);
    final uid = _currentUserId;
    if (sid == null || uid == null) return false;
    return sid == uid;
  }

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didUpdateWidget(MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialConversationId != oldWidget.initialConversationId &&
        widget.initialConversationId != null &&
        _conversations.any((c) => c['id'] == widget.initialConversationId)) {
      setState(() => _selectedId = widget.initialConversationId);
      _loadMessages(_selectedId!);
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _conversationsLoading = true;
      _unauthorized = false;
    });
    try {
      final r = await dio.get('/api/listings/conversations/');
      final list = r.data is List ? r.data as List : [];
      final maps = list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      setState(() {
        _conversations = maps;
        _conversationsLoading = false;
        if (widget.initialConversationId != null && maps.any((c) => c['id'] == widget.initialConversationId)) {
          _selectedId = widget.initialConversationId;
          _loadMessages(_selectedId!);
        }
      });
      ref.invalidate(unreadMessagesCountProvider);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        setState(() {
          _conversations = [];
          _conversationsLoading = false;
          _unauthorized = true;
        });
      } else {
        setState(() {
          _conversations = [];
          _conversationsLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _conversations = [];
        _conversationsLoading = false;
      });
    }
  }

  Future<void> _loadMessages(int convId) async {
    setState(() => _messagesLoading = true);
    try {
      final r = await dio.get('/api/listings/conversations/$convId/messages/');
      final data = r.data is Map ? r.data as Map : <String, dynamic>{};
      final list = data['messages'] is List ? data['messages'] as List : [];
      final msgs = list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      final userId = data['current_user_id'];
      setState(() {
        _messages = msgs;
        _currentUserId = _parseUserId(userId);
        _messagesLoading = false;
      });
      ref.invalidate(unreadMessagesCountProvider);
    } catch (_) {
      setState(() {
        _messages = [];
        _messagesLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _sendController.text.trim();
    if (text.isEmpty || _selectedId == null || _sending) return;
    setState(() => _sending = true);
    try {
      final r = await dio.post(
        '/api/listings/conversations/$_selectedId/messages/send/',
        data: {'text': text},
      );
      final msg = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      setState(() {
        _messages = [..._messages, msg];
        _sendController.clear();
        _sending = false;
      });
      ref.invalidate(unreadMessagesCountProvider);
      _loadConversations();
    } catch (_) {
      setState(() => _sending = false);
    }
  }

  Map<String, dynamic>? get _selectedConv =>
      _conversations.isEmpty ? null : _conversations.cast<Map<String, dynamic>?>().firstWhere((c) => c!['id'] == _selectedId, orElse: () => null);

  void _closeChat() {
    setState(() => _selectedId = null);
    ref.invalidate(unreadMessagesCountProvider);
    _loadConversations();
  }

  @override
  void dispose() {
    ref.invalidate(unreadMessagesCountProvider);
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf5f5f7);
    final surface = isDark ? const Color(0xFF141414) : Colors.white;
    final surface2 = isDark ? const Color(0xFF1c1c1e) : const Color(0xFFf0f0f2);
    final border = isDark ? const Color(0xFF38383a) : const Color(0xFFe5e5ea);
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);
    const accent = Color(0xFF2563eb);
    const accentDeep = Color(0xFF1d4ed8);

    if (_unauthorized) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 56, color: muted),
                  const SizedBox(height: 16),
                  Text('Сообщения', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 8),
                  Text('Войдите в аккаунт, чтобы видеть чаты с продавцами и покупателями.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 15)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go(profilePathForLogin(returnTo: loginReturnPathFromContext(context))),
                    style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final showSplit = wide;
    final inChat = _selectedId != null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!inChat || showSplit)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  'Сообщения',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5),
                ),
              ),
            Expanded(
              child: showSplit
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 300,
                            child: _conversationListCard(surface, border, text, muted, accent, isDark, fullBleed: false),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _chatPanel(
                              surface, surface2, border, text, muted, accent, accentDeep, isDark,
                              showBack: false,
                              emptyHintWide: true,
                            ),
                          ),
                        ],
                      ),
                    )
                  : inChat
                      ? _chatPanel(surface, surface2, border, text, muted, accent, accentDeep, isDark, showBack: true, emptyHintWide: false)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: _conversationListCard(surface, border, text, muted, accent, isDark, fullBleed: true),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationListCard(
    Color surface,
    Color border,
    Color text,
    Color muted,
    Color accent,
    bool isDark, {
    bool fullBleed = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.forum_rounded, size: 20, color: accent),
                const SizedBox(width: 8),
                Text('Чаты', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          Expanded(
            child: _conversationsLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Пока нет чатов. Нажмите «Написать» в объявлении.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 14, height: 1.4)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => Divider(height: 1, indent: 68, color: border.withValues(alpha: 0.5)),
                          itemBuilder: (_, i) {
                            final c = _conversations[i];
                            final id = c['id'];
                            final unread = (c['unread_count'] as num?)?.toInt() ?? 0;
                            final active = _selectedId == id;
                            final name = c['other_user_name']?.toString() ?? 'Пользователь';
                            final trimmed = name.trim();
                            final initial = trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : '?';
                            return Material(
                              color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final convId = _parseUserId(id) ?? (id is int ? id : int.tryParse(id.toString()));
                                  if (convId == null) return;
                                  setState(() => _selectedId = convId);
                                  _loadMessages(convId);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: accent.withValues(alpha: 0.2),
                                        child: Text(initial, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 18)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(c['listing_title']?.toString() ?? 'Объявление', style: TextStyle(fontSize: 12, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (c['last_message'] != null && (c['last_message'] as String).isNotEmpty)
                                              Text(c['last_message'].toString(), style: TextStyle(fontSize: 12, color: muted.withValues(alpha: 0.9)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      if (unread > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFff3b30),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('${unread > 99 ? "99+" : unread}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chatPanel(
    Color surface,
    Color surface2,
    Color border,
    Color text,
    Color muted,
    Color accent,
    Color accentDeep,
    bool isDark, {
    required bool showBack,
    required bool emptyHintWide,
  }) {
    if (_selectedId == null) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 56, color: muted.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text(
                  emptyHintWide ? 'Выберите чат слева' : 'Выберите чат из списка',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text('Или начните переписку из объявления.', textAlign: TextAlign.center, style: TextStyle(color: muted.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(showBack ? 4 : 14, 10, 14, 10),
            decoration: BoxDecoration(
              color: surface2,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    onPressed: _closeChat,
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: text),
                    tooltip: 'Назад',
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: showBack ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                    children: [
                      Text(_selectedConv?['other_user_name']?.toString() ?? 'Чат', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () {
                          final lid = _selectedConv?['listing_id'];
                          if (lid != null) context.push('/listings/$lid');
                        },
                        child: Text(
                          _selectedConv?['listing_title']?.toString() ?? 'Объявление',
                          style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_messagesLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _messageBubble(_messages[i], text, muted, accent, accentDeep, isDark, border),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(color: surface2, border: Border(top: BorderSide(color: border))),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sendController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Сообщение…',
                        hintStyle: TextStyle(color: muted, fontSize: 15),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2c2c2e) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: accent, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: TextStyle(color: text, fontSize: 15),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _sendController.text.trim().isEmpty ? muted.withValues(alpha: 0.35) : accent,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: accent.withValues(alpha: 0.45),
                    child: InkWell(
                      onTap: (_sending || _sendController.text.trim().isEmpty) ? null : _sendMessage,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _sending
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(
    Map<String, dynamic> m,
    Color text,
    Color muted,
    Color accent,
    Color accentDeep,
    bool isDark,
    Color border,
  ) {
    final isOwn = _isOwnMessage(m);
    final name = m['sender_name']?.toString() ?? '';
    final body = m['text']?.toString() ?? '';
    final time = _formatTimeShort(m['created_at']);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isOwn ? LinearGradient(colors: [accent, accentDeep], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isOwn ? null : (isDark ? const Color(0xFF2c2c2e) : const Color(0xFFf2f2f7)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isOwn ? 18 : 5),
          bottomRight: Radius.circular(isOwn ? 5 : 18),
        ),
        border: isOwn ? null : Border.all(color: border.withValues(alpha: 0.85)),
        boxShadow: isOwn
            ? [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))]
            : [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOwn && name.isNotEmpty) ...[
            Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
            const SizedBox(height: 4),
          ],
          Text(
            body,
            style: TextStyle(fontSize: 15, height: 1.35, color: isOwn ? Colors.white : text, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: isOwn ? Colors.white.withValues(alpha: 0.75) : muted),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 10, left: isOwn ? 36 : 0, right: isOwn ? 0 : 36),
      child: Align(alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft, child: bubble),
    );
  }

  String _formatTimeShort(dynamic v) {
    if (v == null) return '';
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return v.toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return 'сегодня, $t';
    if (d == today.subtract(const Duration(days: 1))) return 'вчера, $t';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} $t';
  }
}
