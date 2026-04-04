import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// Шумораи пайғомҳои нахондашуда барои badge дар навбари поён.
/// Агар 401 шавад ё хатогӣ — 0 бармегардонад.
final unreadMessagesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final r = await dio.get('/api/listings/conversations/unread-count/');
    final data = r.data is Map ? r.data as Map : <String, dynamic>{};
    final unread = data['unread'];
    if (unread is int) return unread;
    if (unread is num) return unread.toInt();
    return 0;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) return 0;
    return 0;
  } catch (_) {
    return 0;
  }
});
