import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/motor_list_provider.dart';
import '../providers/gps_tracking_provider.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class TotalDistanceCard extends ConsumerStatefulWidget {
  const TotalDistanceCard({super.key});

  @override
  ConsumerState<TotalDistanceCard> createState() => _TotalDistanceCardState();
}

class _TotalDistanceCardState extends ConsumerState<TotalDistanceCard> {
  @override
  Widget build(BuildContext context) {
    ref.watch(motorListProvider);
    final activeMotor = ref.read(motorListProvider.notifier).getActiveMotor();

    // Calculate total distance
    String totalDistance = '0';
    String startDate = '-';
    String endDate = '-';

    if (activeMotor != null) {
      try {
        final currentOdometer = int.parse(activeMotor.odometer);
        final initialOdometer = int.parse(activeMotor.odometerAwal);
        final distance = currentOdometer - initialOdometer;

        // Format distance with comma separator
        totalDistance = distance.toString();

        // Format dates
        startDate = _formatDate(activeMotor.tanggalDitambah);
        endDate = _formatDate(DateTime.now());
      } catch (e) {
        totalDistance = '0';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF530000),
                  Color(0xFF860000),
                  Color(0xFFE40000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Jarak Tempuh',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$totalDistance km',
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 38,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        startDate,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        endDate,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            child: _buildTripButton(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildTripButton(WidgetRef ref) {
    final trackingState = ref.watch(gpsTrackingProvider);
    final isTracking = trackingState.status == TrackingStatus.tracking;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: isTracking ? AppColors.error : AppColors.normalHover,
          strokeWidth: 2,
          dashWidth: 8,
          dashSpace: 4,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isTracking ? null : () async {
              try {
                await ref.read(gpsTrackingProvider.notifier).startTracking();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tracking dimulai! Scroll ke bawah untuk melihat map.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.normalHover,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(AppSpacing.m),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(AppSpacing.m),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.m),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTracking ? Icons.gps_fixed : Icons.navigation,
                    color: isTracking ? AppColors.error : AppColors.normalHover,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    isTracking ? 'Sedang Melacak...' : 'Mulai Perjalanan',
                    style: AppTypography.titleMedium.copyWith(
                      color: isTracking ? AppColors.error : AppColors.normalHover,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 8,
    this.dashSpace = 4,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
                       size.width - strokeWidth, size.height - strokeWidth),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? dashWidth : dashSpace;
        if (distance + length > metric.length) {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        } else {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, distance + length),
              Offset.zero,
            );
          }
          distance += length;
          draw = !draw;
        }
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.dashWidth != dashWidth ||
           oldDelegate.dashSpace != dashSpace;
  }
}