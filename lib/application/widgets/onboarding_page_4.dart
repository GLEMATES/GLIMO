import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import 'action_button.dart';

class OnboardingPage4 extends StatelessWidget {
  final VoidCallback? onRegister;
  final VoidCallback? onLogin;
  final VoidCallback? onBack;

  const OnboardingPage4({
    super.key,
    this.onRegister,
    this.onLogin,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        _buildIllustration(),
        const SizedBox(height: 32),
        _buildContent(),
        const SizedBox(height: 60),
        _buildButtons(),
        const Spacer(),
        _buildBackButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildIllustration() {
    return Expanded(
      flex: 2,
      child: Center(
        child: Image.asset(
          'assets/images/guide-4-white-bg.gif',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 350,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 100,
                    color: AppColors.normal,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Login/Register\nIllustration',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.normal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'GLEMO siap membantu Anda mengingat servis motor, melacak perjalanan, dan mencatat riwayat perawatan.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral700,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        children: [
          ActionButton(
            text: 'DAFTAR',
            onPressed: onRegister ?? () {},
            isPrimary: true,
          ),
          const SizedBox(height: AppSpacing.m),
          ActionButton(
            text: 'MASUK',
            onPressed: onLogin ?? () {},
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onBack ?? () {},
          child: Text(
            'Back',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ),
      ),
    );
  }
}