import 'package:flutter/material.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.xxl),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDADADA), width: 1),
            borderRadius: BorderRadius.circular(AppSpacing.xxl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                  ),
                )
              else
                _buildGoogleLogo(),
              const SizedBox(width: AppSpacing.m),
              Text(
                'Masuk dengan akun Google',
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF3C4043),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Image.asset(
        'assets/images/login_google.png',
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
  }
}
