import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/home_refresh_provider.dart';
import '../app/theme.dart';
import '../app/favorites_count_provider.dart';
import '../app/compare_provider.dart';
import '../app/unread_messages_provider.dart';
import 'drawer_header_logo.dart';
import 'manzilho_app_bar.dart';

class BottomNavScaffold extends ConsumerStatefulWidget {
  const BottomNavScaffold({super.key, required this.child});

  final Widget child;

  /// Саҳифаи тафсили объявление: `/listings/123` (на `/listings`).
  static bool isListingDetailPath(String path) {
    if (!path.startsWith('/listings/')) return false;
    final rest = path.substring('/listings/'.length);
    return rest.isNotEmpty && !rest.contains('/');
  }

  @override
  ConsumerState<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends ConsumerState<BottomNavScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// `null` — ҳеҷ таби поён намоиш дода намешавад (масалан объявление ё рӯйхат).
  int? _indexForPath(String path) {
    if (path == '/') return 0;
    if (path.startsWith('/favorites')) return 1;
    if (path.startsWith('/add')) return 2;
    if (path.startsWith('/messages')) return 3;
    if (path.startsWith('/profile') || path.startsWith('/balance')) return 4;
    return null;
  }

  void _goForIndex(int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        context.go('/favorites');
        return;
      case 2:
        context.go('/add');
        return;
      case 3:
        context.go('/messages');
        return;
      case 4:
        context.go('/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final idx = _indexForPath(path);
    final hideShellChrome = BottomNavScaffold.isListingDetailPath(path);
    final unreadAsync = ref.watch(unreadMessagesCountProvider);
    final messagesUnreadCount = unreadAsync.valueOrNull ?? 0;
    final favoritesAsync = ref.watch(favoritesCountProvider);
    final favoritesCount = favoritesAsync.valueOrNull ?? 0;
    final compareIds = ref.watch(compareIdsProvider);
    final compareCount = compareIds?.length ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: hideShellChrome
          ? null
          : ManzilhoAppBar(
              onLogoTap: () => onManzilhoLogoTap(context, ref),
              onNotificationsTap: () => context.push('/notifications'),
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      drawer: hideShellChrome
          ? null
          : Drawer(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeaderLogo(),
                  ListTile(
                    title: const Text('Главная'),
                    leading: const Icon(Icons.home_outlined),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  ListTile(
                    title: const Text('Поиск'),
                    leading: const Icon(Icons.search),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/listings');
                    },
                  ),
                  ListTile(
                    title: const Text('Уведомления'),
                    leading: const Icon(Icons.notifications_none_rounded),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),
                  ListTile(
                    title: const Text('Сравнение'),
                    leading: const Icon(Icons.balance),
                    trailing: compareCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: manzilhoOrange, borderRadius: BorderRadius.circular(12)),
                            child: Text('$compareCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/compare');
                    },
                  ),
                  ListTile(title: const Text('Умный помощник'), leading: const Icon(Icons.smart_toy), onTap: () { Navigator.pop(context); context.go('/assistant'); }),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Профиль'),
                    leading: const Icon(Icons.person_outline),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  ListTile(
                    title: const Text('Баланс'),
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/balance');
                    },
                  ),
                  ListTile(
                    title: const Text('Настройка'),
                    leading: const Icon(Icons.settings_outlined),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                  ListTile(
                    title: const Text('Push-уведомления'),
                    leading: const Icon(Icons.notifications_active_outlined),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/push-notifications');
                    },
                  ),
                ],
              ),
            ),
      body: widget.child,
      bottomNavigationBar: _ManzilhoBottomNav(
        currentIndex: idx,
        onTap: _goForIndex,
        favoritesCount: favoritesCount,
        messagesUnreadCount: messagesUnreadCount,
      ),
      // Дар «Сообщения», «Сравнение», тафсили объявление — робот намешавад / ҷой намегирад.
      floatingActionButton: (path.startsWith('/messages') || path.startsWith('/compare') || hideShellChrome)
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('/assistant'),
              backgroundColor: manzilhoOrange,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// 5 таб: Главная, Избранное (бо badge), Добавить (норанҷи миёна), Сообщения, Кабинет. Фон торики хокистарӣ.
class _ManzilhoBottomNav extends StatelessWidget {
  const _ManzilhoBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.favoritesCount = 0,
    this.messagesUnreadCount = 0,
  });

  /// `null` — ҳеҷ як таб интихоб нашуда (масалан рӯйхат ё тафсил).
  final int? currentIndex;
  final ValueChanged<int> onTap;
  final int favoritesCount;
  final int messagesUnreadCount;

  static const _navBg = Color(0xFF2c2c2c);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _navBg),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Главная', selected: currentIndex != null && currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.favorite_border, selectedIcon: Icons.favorite, label: 'Избранное', selected: currentIndex != null && currentIndex == 1, badge: favoritesCount > 0 ? favoritesCount : null, onTap: () => onTap(1)),
              _CenterAddButton(onTap: () => onTap(2)),
              _NavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Сообщения', selected: currentIndex != null && currentIndex == 3, badge: messagesUnreadCount > 0 ? messagesUnreadCount : null, onTap: () => onTap(3)),
              _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Кабинет', selected: currentIndex != null && currentIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.grey;
    final iconWidget = badge != null && badge! > 0
        ? Badge(
            label: Text('$badge', style: const TextStyle(fontSize: 10)),
            backgroundColor: manzilhoOrange,
            child: Icon(selected ? selectedIcon : icon, color: color, size: 24),
          )
        : Icon(selected ? selectedIcon : icon, color: color, size: 24);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  const _CenterAddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Material(
          color: manzilhoOrange,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(width: 48, height: 48, child: Center(child: Icon(Icons.add, color: Colors.white, size: 28))),
          ),
        ),
      ),
    );
  }
}
