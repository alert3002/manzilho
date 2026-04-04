import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/add_listing/add_listing_screen.dart';
import '../features/assistant/assistant_screen.dart';
import '../features/compare/compare_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/listings/listing_detail_screen.dart';
import '../features/listings/listings_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/balance_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/about_app_screen.dart';
import '../features/settings/about_us_screen.dart';
import '../features/settings/push_notifications_screen.dart';
import '../features/settings/settings_screen.dart';
import '../widgets/bottom_nav_scaffold.dart';

/// Ключ навигации для перехода из push-уведомлений (FCM).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // SmartPay return: https://manzilho.tj/profile?payment=return&order_id=...
      // В приложении удобнее открыть экран баланса и автоматически синкнуть оплату.
      if (state.uri.path == '/profile') {
        final payment = state.uri.queryParameters['payment'];
        final oid = state.uri.queryParameters['order_id'];
        if (payment == 'return' && oid != null && oid.isNotEmpty) {
          return Uri(path: '/balance', queryParameters: {'payment': 'return', 'order_id': oid}).toString();
        }
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => BottomNavScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
          GoRoute(
            path: '/add',
            builder: (context, state) {
              final edit = state.uri.queryParameters['edit'];
              return AddListingScreen(editListingId: edit != null ? int.tryParse(edit) : null);
            },
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) {
              final convId = state.uri.queryParameters['conversation'];
              return MessagesScreen(initialConversationId: convId != null ? int.tryParse(convId) : null);
            },
          ),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/balance', builder: (context, state) => const BalanceScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: '/push-notifications', builder: (context, state) => const PushNotificationsScreen()),
          GoRoute(path: '/about-us', builder: (context, state) => const AboutUsScreen()),
          GoRoute(path: '/about-app', builder: (context, state) => const AboutAppScreen()),
          GoRoute(path: '/listings', builder: (context, state) => const ListingsScreen()),
          GoRoute(
            path: '/listings/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ListingDetailScreen(id: id);
            },
          ),
          GoRoute(path: '/compare', builder: (context, state) => const CompareScreen()),
          GoRoute(
            path: '/assistant',
            builder: (context, state) {
              final req = state.uri.queryParameters['request'];
              return AssistantScreen(initialRequestId: req != null ? int.tryParse(req) : null);
            },
          ),
        ],
      ),
    ],
  );
});

