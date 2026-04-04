import 'package:flutter/material.dart';

/// Header: логотип, колокольчик уведомлений, меню. Тема — в «Настройки».
class ManzilhoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ManzilhoAppBar({
    super.key,
    required this.onNotificationsTap,
    required this.onMenuTap,
    required this.onLogoTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onMenuTap;
  final VoidCallback onLogoTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2c2c2c),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 0,
      leadingWidth: 0,
      leading: const SizedBox.shrink(),
      title: Padding(
        padding: const EdgeInsets.only(left: 12, top: 14),
        child: Align(
          alignment: Alignment.topLeft,
          child: InkWell(
            onTap: onLogoTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Image.asset(
                'assets/logo_header.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.home_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
          onPressed: onNotificationsTap,
          tooltip: 'Уведомления',
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 24),
          onPressed: onMenuTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

