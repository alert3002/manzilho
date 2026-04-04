import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/legal_urls.dart';

/// Маълумот дар бораи барнома + пайвандҳои ҳуқуқӣ (талаботи дӯконҳо).
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);
    final card = isDark ? const Color(0xFF1c1c1e) : Colors.white;
    final border = isDark ? const Color(0xFF3a3a3c) : const Color(0xFFe5e5ea);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'О приложении',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),
          Center(
            child: Image.asset(
              'assets/logo512.png',
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.home_work_rounded, size: 64, color: manzilhoOrange),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'manzilho',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text),
          ),
          const SizedBox(height: 8),
          Text(
            'Платформа недвижимости в Таджикистане: продажа, аренда, агенты и застройщики.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45, color: muted),
          ),
          const SizedBox(height: 28),
          _AboutRow(label: 'Версия', value: '1.0.0', text: text, muted: muted),
          const SizedBox(height: 12),
          _AboutRow(label: 'Сайт', value: 'manzilho.tj', text: text, muted: muted),
          const SizedBox(height: 24),
          Text(
            'Документы',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Material(
            color: card,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: manzilhoOrange),
                    title: const Text('Политика конфиденциальности'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _open(kPrivacyPolicyUrl),
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: manzilhoOrange),
                    title: const Text('Условия использования'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _open(kTermsOfServiceUrl),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Разместите актуальные тексты по ссылкам выше перед публикацией в Google Play и App Store.',
            style: TextStyle(fontSize: 12, height: 1.35, color: muted),
          ),
          const SizedBox(height: 32),
          Text(
            '© Manzilho',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value, required this.text, required this.muted});

  final String label;
  final String value;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 15, color: muted, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: text, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
