import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class AppBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.l,
          left: AppSpacing.l,
          right: AppSpacing.l,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF860000),
            borderRadius: BorderRadius.circular(AppSpacing.xxxl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xxxl),
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    label: 'Beranda',
                    isSelected: navigationShell.currentIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.bar_chart_outlined,
                    label: 'Monitoring',
                    isSelected: navigationShell.currentIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.history,
                    label: 'Riwayat',
                    isSelected: navigationShell.currentIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline,
                    label: 'Profil',
                    isSelected: navigationShell.currentIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.xxxl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.5,
                width: isSelected ? 28 : 0,
                decoration: BoxDecoration(
                  color: AppColors.neutral0,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.neutral0 : const Color(0xFFE4B0B0),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.neutral0 : const Color(0xFFE4B0B0),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}