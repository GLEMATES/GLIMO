import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class ServiceKilometerCard extends StatelessWidget {
  final String title;
  final String percentage;
  final int currentValue;
  final List<int> milestones;
  final String buttonText;
  final String imagePath;
  final String description;
  final VoidCallback? onPressed;

  const ServiceKilometerCard({
    super.key,
    required this.title,
    required this.percentage,
    required this.currentValue,
    required this.milestones,
    required this.buttonText,
    required this.imagePath,
    required this.description,
    this.onPressed,
  });

  void _showInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.l,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.m, thickness: 1),
              const SizedBox(height: AppSpacing.s),
              Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                description,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progressPercentage = currentValue / milestones.last;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.darkHover,
        borderRadius: BorderRadius.circular(AppSpacing.s),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              color: AppColors.darkHover,
            ),
            Expanded(
              child: Container(
                color: AppColors.neutral0,
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showInfoModal(context),
                          icon: Icon(
                            Icons.info_outline,
                            color: AppColors.neutral600,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double progressWidth = constraints.maxWidth;
                        final double indicatorPosition = progressPercentage * progressWidth;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 35),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    height: 8,
                                    child: LinearProgressIndicator(
                                      value: progressPercentage,
                                      backgroundColor: AppColors.neutral300,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkHover),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: milestones
                                        .map((m) => Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                '$m',
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 12,
                                                  color: AppColors.neutral900,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              left: indicatorPosition - 10,
                              top: 31,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral0,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.darkHover,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: indicatorPosition - 30,
                              top: 0,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkHover,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      percentage,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.neutral0,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  CustomPaint(
                                    size: const Size(14, 8),
                                    painter: TrianglePainter(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 36,
                        width: 120,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFA80000),
                                Color(0xFF860000),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onPressed,
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Text(
                                  buttonText,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.neutral0,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkHover
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}