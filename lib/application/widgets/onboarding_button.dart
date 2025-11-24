import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_typography.dart';

class OnboardingButton extends StatelessWidget {
  final bool isLastPage;
  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  const OnboardingButton({
    super.key,
    required this.isLastPage,
    required this.currentPage,
    required this.onNext,
    required this.onSkip,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentPage == 0)
          GestureDetector(
            onTap: onSkip,
            child: Text(
              'Skip',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: onBack,
            child: Text(
              'Back',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: isLastPage ? 140 : 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.normalHover,
              borderRadius: BorderRadius.circular(23),
            ),
            child: isLastPage
                ? Center(
                    child: Text(
                      'Mulai',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.neutral0,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward,
                    color: AppColors.neutral0,
                    size: 24,
                  ),
          ),
        ),
      ],
    );
  }
}