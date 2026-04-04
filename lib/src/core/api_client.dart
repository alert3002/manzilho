import 'package:dio/dio.dart';

import 'api_client_stub.dart' if (dart.library.io) 'api_client_io.dart' as _platform;
import 'auth_storage.dart';

/// По умолчанию: всегда prod API `https://api.manzilho.tj`.
/// Для локального бэкенда включите:
/// `flutter run --dart-define=USE_LOCAL_API=true`
const bool _kUseLocalApiFromEnv = bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);
bool get _useLocalApi => _kUseLocalApiFromEnv;

String get apiBase {
  if (!_useLocalApi) return 'https://api.manzilho.tj';
  return _platform.getLocalApiHost();
}

late final dio = Dio(BaseOptions(baseUrl: apiBase, connectTimeout: const Duration(seconds: 15)));

/// Илова кардани interceptor барои Authorization: Bearer. Дар main() пеш аз runApp даъват кунед.
Future<void> initDioAuth() async {
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));
}

String getImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://static/') || url.startsWith('https://static/')) {
    url = url.replaceFirst(RegExp(r'^https?://static/'), '');
    return '$apiBase/$url';
  }
  if (url.startsWith('//static/')) {
    url = url.replaceFirst('//static/', '');
    return '$apiBase/$url';
  }
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return url.startsWith('/') ? '$apiBase$url' : '$apiBase/$url';
}

List<T> ensureArray<T>(dynamic data) {
  if (data is List) return List<T>.from(data);
  if (data is Map && data['results'] is List) return List<T>.from(data['results'] as List);
  return [];
}

/// Текст хатогӣ аз ҷавоби JSON (detail, error, …) — бе `{detail: ...}`.
String? extractApiErrorMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) return data.isEmpty ? null : data;
  if (data is Map) {
    final det = data['detail'];
    if (det is String && det.isNotEmpty) return det;
    if (det is List && det.isNotEmpty) {
      final first = det.first;
      if (first is String) return first;
    }
    for (final k in ['error', 'message', 'non_field_errors']) {
      final v = data[k];
      if (v is String && v.isNotEmpty) return v;
      if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
    }
  }
  return null;
}

/// Паёми хонандабар барои SnackBar / Alert.
String messageFromDioException(DioException e) {
  final status = e.response?.statusCode;
  if (status == 401) {
    return 'Нужен вход: откройте «Профиль» и войдите по коду из SMS.';
  }
  return extractApiErrorMessage(e.response?.data) ??
      e.message ??
      'Ошибка сети. Проверьте интернет и сервер.';
}
