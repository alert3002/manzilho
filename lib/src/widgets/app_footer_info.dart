import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme.dart';

class AppFooterInfo extends StatelessWidget {
  const AppFooterInfo({super.key});

  static const _phone = '+992 92 899 77 66';
  static const _phoneDigits = '992928997766';
  static const _email = 'info@manzilho.tj';
  static const _telegram = 'https://t.me/manzilho_tj';

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFf3f4f6);
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('© $year Manzilho', style: TextStyle(color: text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _launch(Uri.parse('tel:$_phoneDigits')),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text(_phone),
                style: TextButton.styleFrom(foregroundColor: manzilhoOrange),
              ),
              TextButton.icon(
                onPressed: () => _launch(Uri.parse('mailto:$_email')),
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text(_email),
                style: TextButton.styleFrom(foregroundColor: manzilhoOrange),
              ),
              TextButton.icon(
                onPressed: () => _launch(Uri.parse(_telegram)),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Telegram'),
                style: TextButton.styleFrom(foregroundColor: manzilhoOrange),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Служба поддержки: звоните или пишите нам.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}
