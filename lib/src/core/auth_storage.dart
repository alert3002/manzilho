import 'package:shared_preferences/shared_preferences.dart';

const _keyAccessToken = 'access_token';

/// Токен барнома — аз логин гирифта мешавад; барои API Authorization: Bearer.
Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyAccessToken);
}

Future<void> setAccessToken(String? token) async {
  final prefs = await SharedPreferences.getInstance();
  if (token == null) {
    await prefs.remove(_keyAccessToken);
  } else {
    await prefs.setString(_keyAccessToken, token);
  }
}
