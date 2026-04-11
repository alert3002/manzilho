import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localePrefsKey = 'app_locale';

/// Поддерживаемые коды: `tg`, `ru` (как на веб-фронтенде).
final appLocaleProvider = StateProvider<Locale>((ref) => const Locale('tg'));

Future<Locale> loadSavedLocale() async {
  final p = await SharedPreferences.getInstance();
  final code = (p.getString(_localePrefsKey) ?? 'tg').toLowerCase();
  if (code == 'ru') return const Locale('ru');
  return const Locale('tg');
}

Future<void> persistAppLocale(Locale locale) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_localePrefsKey, locale.languageCode);
}

/// Интихоби забон ва нигоҳдорӣ.
Future<void> setAppLocale(WidgetRef ref, Locale locale) async {
  final next = locale.languageCode == 'ru' ? const Locale('ru') : const Locale('tg');
  ref.read(appLocaleProvider.notifier).state = next;
  await persistAppLocale(next);
}
