import 'package:flutter/material.dart';
import '../themes/app_spacing.dart';
import 'profile_menu_item.dart';

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6E6E6),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Column(
          children: [
            ProfileMenuItem(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              onTap: () {},
            ),
            ProfileMenuItem(
              icon: Icons.motorcycle_outlined,
              title: 'Motor Saya',
              onTap: () {},
            ),
            ProfileMenuItem(
              icon: Icons.lock_outline,
              title: 'Ubah Password',
              onTap: () {},
            ),
            ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Bantuan',
              onTap: () {},
            ),
            ProfileMenuItem(
              icon: Icons.logout,
              title: 'Keluar',
              onTap: () {},
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}