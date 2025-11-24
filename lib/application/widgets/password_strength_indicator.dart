import 'package:flutter/material.dart';
import '../utils/password_strength.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = false,
  });

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthHelper.checkStrength(password);
    final strengthText = PasswordStrengthHelper.getStrengthText(strength);
    final strengthColor = PasswordStrengthHelper.getStrengthColor(strength);
    final progress = PasswordStrengthHelper.getStrengthProgress(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (password.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: strengthColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Text(
                strengthText,
                style: AppTypography.bodySmall.copyWith(
                  color: strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (showRequirements && strength != PasswordStrength.strong) ...[
            const SizedBox(height: AppSpacing.s),
            ...PasswordStrengthHelper.getPasswordRequirements(password)
                .take(2)
                .map((requirement) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: strengthColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            requirement,
                            style: AppTypography.bodySmall.copyWith(
                              color: strengthColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ],
      ],
    );
  }
}
