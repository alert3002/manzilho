import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/core/api_client.dart';
import 'src/core/push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDioAuth();
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firebase.initializeApp failed (FCM tokens will not register): $e');
      debugPrint('$st');
    }
  }
  runApp(const ProviderScope(child: ManzilhoApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) => initPushNotifications());
}
