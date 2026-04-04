import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/home_refresh_provider.dart';

/// Сарлавҳаи drawer — танҳо логотип, 15px фосила аз боло, зеркашӣ ба хона ё refresh.
class DrawerHeaderLogo extends ConsumerWidget {
  const DrawerHeaderLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: const Color(0xFF2c2c2c),
      child: InkWell(
        onTap: () => onManzilhoLogoTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Image.asset(
              'assets/logo_header.png',
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
