import 'dart:io' show Platform;

/// Барои Android/iOS/desktop: Android эмулятор 10.0.2.2, дигарон 127.0.0.1.
String getLocalApiHost() =>
    Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
