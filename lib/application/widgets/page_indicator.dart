import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int numPages;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.numPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(numPages, (index) {
        bool isActive = currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 15 : 12,
          height: isActive ? 15 : 12,
          decoration: BoxDecoration(
            color: isActive ? AppColors.normal : AppColors.neutral300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}