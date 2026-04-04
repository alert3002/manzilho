import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';

/// «О нас» — дар бораи ширкат ва миссия.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static final Uri _telegram = Uri.parse('https://t.me/manzilho_tj');

  Future<void> _openTelegram() async {
    if (await canLaunchUrl(_telegram)) {
      await launchUrl(_telegram, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'О нас',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Manzilho.tj — сервис объявлений о недвижимости в Таджикистане. Мы помогаем людям находить жильё, '
            'продавать и сдавать квартиры и дома, а агентам и застройщикам — выходить к аудитории на одной платформе.',
            style: TextStyle(fontSize: 15, height: 1.5, color: text),
          ),
          const SizedBox(height: 16),
          Text(
            'Наша цель — сделать поиск и размещение недвижимости простым и безопасным: удобный поиск, честные объявления '
            'и поддержка пользователей.',
            style: TextStyle(fontSize: 15, height: 1.5, color: muted),
          ),
          const SizedBox(height: 28),
          Text('Связь с нами', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.telegram, color: manzilhoBlue),
            title: Text('Telegram', style: TextStyle(color: text, fontWeight: FontWeight.w600)),
            subtitle: Text('@manzilho_tj', style: TextStyle(color: muted, fontSize: 14)),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: _openTelegram,
          ),
          const SizedBox(height: 24),
          Text(
            '© Manzilho.tj',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}
