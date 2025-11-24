import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

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
          'assets/images/Guide_1.png',
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
                    Icons.motorcycle,
                    size: 80,
                    color: AppColors.normal,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Motorcycle\nIllustration',
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
          'Kelola Motor Anda',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.normal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          width: 276,
          child: Text(
            'Pantau dan kelola jadwal servis motor Anda dengan mudah dalam satu aplikasi.',
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