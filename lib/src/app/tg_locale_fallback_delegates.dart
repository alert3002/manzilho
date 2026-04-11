import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const _fallbackUiLocale = Locale('ru');

/// Flutter пешфарзан `MaterialLocalizations` / `WidgetsLocalizations` барои `tg` надорад.
/// Барои `Drawer`, `Scaffold` ва ғ. бояд ин делегатҳо пеш аз Global* гузошта шаванд.
class TgMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const TgMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallbackUiLocale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class TgWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const TgWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_fallbackUiLocale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) => false;
}

class TgCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const TgCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallbackUiLocale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) => false;
}
