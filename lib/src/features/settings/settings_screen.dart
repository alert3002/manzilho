import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../app/theme_mode_provider.dart';
import '../../core/legal_urls.dart';

/// Саҳифаи насбҳои барнома: профиль, мавзӯъ, push, дигар.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa);
    final text = isDark ? const Color(0xFFf2f2f7) : const Color(0xFF1c1c1e);
    final muted = isDark ? const Color(0xFF8e8e93) : const Color(0xFF636366);
    final card = isDark ? const Color(0xFF1c1c1e) : Colors.white;
    final border = isDark ? const Color(0xFF3a3a3c) : const Color(0xFFe5e5ea);

    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            'Настройки',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text('Профиль, оформление и уведомления', style: TextStyle(fontSize: 15, color: muted)),
          const SizedBox(height: 22),
          _SectionTitle(label: 'Аккаунт', color: muted),
          const SizedBox(height: 8),
          _SettingsCard(
            card: card,
            border: border,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Личные данные'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/profile?tab=settings'),
                ),
                Divider(height: 1, color: border),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Избранное'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/favorites'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(label: 'Оформление', color: muted),
          const SizedBox(height: 8),
          _SettingsCard(
            card: card,
            border: border,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: manzilhoOrange, size: 22),
                      const SizedBox(width: 10),
                      Text('Тема оформления', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'В шапке приложения — уведомления; тема переключается здесь.',
                    style: TextStyle(fontSize: 12, color: muted, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, label: Text('Светлая'), icon: Icon(Icons.light_mode_outlined, size: 18)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная'), icon: Icon(Icons.dark_mode_outlined, size: 18)),
                      ButtonSegment(value: ThemeMode.system, label: Text('Система'), icon: Icon(Icons.settings_suggest_outlined, size: 18)),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) {
                      ref.read(themeModeProvider.notifier).state = s.first;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(label: 'Уведомления', color: muted),
          const SizedBox(height: 8),
          _SettingsCard(
            card: card,
            border: border,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Центр уведомлений'),
                  subtitle: Text('Сообщения и подсказки', style: TextStyle(fontSize: 13, color: muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                Divider(height: 1, color: border),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Push-уведомления'),
                  subtitle: Text('Разрешения системы', style: TextStyle(fontSize: 13, color: muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/push-notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(label: 'О нас', color: muted),
          const SizedBox(height: 8),
          _SettingsCard(
            card: card,
            border: border,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.groups_outlined),
              title: const Text('О нас'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about-us'),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(label: 'Юридическое', color: muted),
          const SizedBox(height: 8),
          _SettingsCard(
            card: card,
            border: border,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Политика конфиденциальности'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    final u = Uri.parse(kPrivacyPolicyUrl);
                    if (await canLaunchUrl(u)) {
                      await launchUrl(u, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                Divider(height: 1, color: border),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Условия использования'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    final u = Uri.parse(kTermsOfServiceUrl);
                    if (await canLaunchUrl(u)) {
                      await launchUrl(u, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(label: 'О приложении', color: muted),
          const SizedBox(height: 8),
          _SettingsCard(
            card: card,
            border: border,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('О приложении'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about-app'),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'manzilho · версия 1.0.0',
              style: TextStyle(fontSize: 13, color: muted.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: color),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, required this.card, required this.border});

  final Widget child;
  final Color card;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: child,
      ),
    );
  }
}
