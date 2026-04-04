import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import 'api_client.dart';
import 'auth_storage.dart';

/// Обработчик FCM в фоне (требуется top-level функция).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

String _fcmPlatformLabel() {
  if (kIsWeb) return 'web';
  if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
  return 'android';
}

Future<void> _registerFcmTokenWithBackend(String token) async {
  final access = await getAccessToken();
  if (access == null || access.isEmpty) return;
  try {
    await dio.post('/api/auth/fcm-token/', data: {'token': token, 'platform': _fcmPlatformLabel()});
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('FCM register on server failed: $e');
      debugPrint('$st');
    }
  }
}

/// Баъд аз вуруд — токенро ба сервер фиристодан.
Future<void> syncFcmTokenAfterLogin() async {
  if (Firebase.apps.isEmpty) return;
  try {
    final t = await FirebaseMessaging.instance.getToken();
    if (t != null) await _registerFcmTokenWithBackend(t);
  } catch (_) {}
}

/// Инициализация push: разрешение, токен на бэкенд, тап по уведомлению → чат.
Future<void> initPushNotifications() async {
  if (Firebase.apps.isEmpty) return;
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final t = await FirebaseMessaging.instance.getToken();
    if (t != null) await _registerFcmTokenWithBackend(t);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerFcmTokenWithBackend);

    // Foreground: показываем snackbar, не делаем auto-redirect.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final convId = message.data['conversation_id']?.toString();
      final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Уведомление';
      final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
      final ctx = appNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        final text = body.isNotEmpty ? body : title;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(text),
            duration: const Duration(seconds: 5),
            action: convId != null && convId.isNotEmpty
                ? SnackBarAction(
                    label: 'Открыть',
                    onPressed: () => GoRouter.of(ctx).go('/messages?conversation=$convId'),
                  )
                : null,
          ),
        );
      }
    });

    // Tap: open chat.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final convId = message.data['conversation_id']?.toString();
      if (convId != null && convId.isNotEmpty) {
        appNavigatorKey.currentContext?.go('/messages?conversation=$convId');
      } else {
        appNavigatorKey.currentContext?.push('/notifications');
      }
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final convId = initial.data['conversation_id']?.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (convId != null && convId.isNotEmpty) {
          appNavigatorKey.currentContext?.go('/messages?conversation=$convId');
        } else {
          appNavigatorKey.currentContext?.push('/notifications');
        }
      });
    }
  } catch (_) {}
}

