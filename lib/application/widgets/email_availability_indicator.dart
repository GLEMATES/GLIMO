import 'package:flutter/material.dart';
import '../utils/email_checker.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class EmailAvailabilityIndicator extends StatelessWidget {
  final EmailStatus status;

  const EmailAvailabilityIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == EmailStatus.initial) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              EmailChecker.getStatusMessage(status),
              style: AppTypography.bodySmall.copyWith(
                color: _getColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (status) {
      case EmailStatus.checking:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.neutral600,
          ),
        );
      case EmailStatus.available:
        return Icon(
          Icons.check_circle,
          size: 18,
          color: _getColor(),
        );
      case EmailStatus.taken:
        return Icon(
          Icons.cancel,
          size: 18,
          color: _getColor(),
        );
      case EmailStatus.invalid:
        return Icon(
          Icons.error,
          size: 18,
          color: _getColor(),
        );
      case EmailStatus.initial:
        return const SizedBox.shrink();
    }
  }

  Color _getColor() {
    switch (status) {
      case EmailStatus.checking:
        return AppColors.neutral600;
      case EmailStatus.available:
        return const Color(0xFF4CAF50); // Green
      case EmailStatus.taken:
        return AppColors.error; // Red
      case EmailStatus.invalid:
        return const Color(0xFFFF9800); // Orange
      case EmailStatus.initial:
        return AppColors.neutral600;
    }
  }
}
