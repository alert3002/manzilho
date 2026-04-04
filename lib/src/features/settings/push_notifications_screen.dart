import 'package:flutter/material.dart';

/// Танзимоти push (FCM баъдтар пайваст мешавад).
class PushNotificationsScreen extends StatelessWidget {
  const PushNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Push-уведомления',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Text(
                  'Разрешите уведомления в системе, когда приложение спросит. '
                  'Новые сообщения в чате приходят как push; токен устройства отправляется на сервер после входа.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4, color: muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
