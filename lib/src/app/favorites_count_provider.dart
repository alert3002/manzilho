import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// Шумораи объявлений дар избранном — барои badge дар навбари поён.
final favoritesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final r = await dio.get('/api/listings/favorites/count/');
    final c = r.data is Map ? r.data['count'] : null;
    if (c is int) return c;
    if (c is num) return c.toInt();
    return 0;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) return 0;
    return 0;
  } catch (_) {
    return 0;
  }
});
