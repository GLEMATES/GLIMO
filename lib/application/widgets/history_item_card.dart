import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class HistoryItemCard extends StatefulWidget {
  final int number;
  final String distance;
  final String startKm;
  final String endKm;
  final String date;
  final String source; // "gps" atau "manual"
  final String? startLocation; // Optional start location
  final String? endLocation; // Optional end location
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HistoryItemCard({
    super.key,
    required this.number,
    required this.distance,
    required this.startKm,
    required this.endKm,
    required this.date,
    this.source = 'manual',
    this.startLocation,
    this.endLocation,
    this.onDelete,
    this.onTap,
  });

  @override
  State<HistoryItemCard> createState() => _HistoryItemCardState();
}

class _HistoryItemCardState extends State<HistoryItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Random offset based on card number untuk staggered animation
    final offset = (widget.number % 5) * 0.2; // 0.0, 0.2, 0.4, 0.6, 0.8

    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: false);

    // Add initial delay based on card position
    Future.delayed(Duration(milliseconds: (offset * 1000).toInt()), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Start from outside left to outside right for seamless loop
    _animation = Tween<double>(begin: -0.15, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.normalHover.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.number}',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalHover,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.distance,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    // Badge GPS/Manual
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.source == 'gps'
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.source == 'gps'
                              ? Colors.blue.withValues(alpha: 0.3)
                              : AppColors.neutral300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.source == 'gps' ? Icons.gps_fixed : Icons.edit,
                            size: 10,
                            color: widget.source == 'gps' ? Colors.blue : AppColors.neutral600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.source == 'gps' ? 'GPS' : 'Manual',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: widget.source == 'gps' ? Colors.blue : AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Odometer visualization with motorcycle
                Row(
                  children: [
                    // Start odometer
                    Text(
                      widget.startKm,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Line with animated motorcycle icon
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return SizedBox(
                                height: 16,
                                child: ClipRect(
                                  clipBehavior: Clip.hardEdge,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                    // Dotted line
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: CustomPaint(
                                          size: Size(constraints.maxWidth, 1),
                                          painter: DashedLinePainter(
                                            color: AppColors.neutral400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Animated Motorcycle icon
                                    Positioned(
                                      left: _animation.value * (constraints.maxWidth - 18),
                                      top: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.neutral0,
                                        ),
                                        child: Icon(
                                          Icons.two_wheeler,
                                          size: 14,
                                          color: AppColors.normalHover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // End odometer
                    Text(
                      '${widget.endKm} km',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.date,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
                // Show location if available (GPS trips)
                if (widget.startLocation != null || widget.endLocation != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.neutral500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.startLocation ?? widget.endLocation ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ), // close Row
        ), // close Padding
      ), // close InkWell
      ), // close Material
    ); // close Container
  }
}

/// Custom painter for drawing dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 3,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}