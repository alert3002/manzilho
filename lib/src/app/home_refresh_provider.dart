import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ҳар бор зиёд шудан → [HomeScreen] лентаҳоро аз нав бор мекунад.
final homeRefreshTickProvider = StateProvider<int>((ref) => 0);

/// Логотип: агар дар `/` бошем — refresh; вагарна → `context.go('/')`.
/// Агар drawer кушода бошад, пеш аз он пӯшида мешавад.
void onManzilhoLogoTap(BuildContext context, WidgetRef ref) {
  final scaffold = Scaffold.maybeOf(context);
  final drawerWasOpen = scaffold?.isDrawerOpen == true;
  if (drawerWasOpen) {
    Navigator.of(context).pop();
  }

  void act() {
    if (!context.mounted) return;
    final path = GoRouterState.of(context).uri.path;
    final onHome = path == '/' || path.isEmpty;
    if (onHome) {
      ref.read(homeRefreshTickProvider.notifier).state++;
    } else {
      context.go('/');
    }
  }

  if (drawerWasOpen) {
    WidgetsBinding.instance.addPostFrameCallback((_) => act());
  } else {
    act();
  }
}
