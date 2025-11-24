import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100),
        _buildIllustration(),
        const SizedBox(height: 40),
        _buildContent(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildIllustration() {
    return Expanded(
      child: Center(
        child: Image.asset(
          'assets/images/Guide_3.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 300,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 80,
                    color: AppColors.normal,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Notifications\nIllustration',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Text(
          'Lacak perjalanan Anda',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.normal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          width: 276,
          child: Text(
            'Pantau jarak tempuh motor Anda secara otomatis dengan pelacakan GPS.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}