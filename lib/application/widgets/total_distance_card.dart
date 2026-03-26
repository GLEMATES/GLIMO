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
  final TextEditingController _odometerController = TextEditingController();

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  void _showEditOdometerDialog(Motor activeMotor) {
    _odometerController.text = activeMotor.odometer;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.l),
        ),
        title: Text(
          'Sesuaikan Odometer',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan nilai odometer yang tertera di motor Anda untuk sinkronisasi.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer (km)',
                hintText: 'Misal: 11722',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.m),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.m),
                  borderSide: const BorderSide(color: AppColors.normalActive, width: 2),
                ),
                suffixText: 'km',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newOdometer = _odometerController.text.trim();
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (newOdometer.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Odometer tidak boleh kosong',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral0,
                      ),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                await ref.read(motorListProvider.notifier).updateMotor(
                  activeMotor.id,
                  activeMotor.model,
                  activeMotor.type,
                  newOdometer,
                );

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Odometer berhasil diperbarui',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral0,
                      ),
                    ),
                    backgroundColor: AppColors.normalHover,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal memperbarui odometer: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral0,
                      ),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.normalActive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.m),
              ),
            ),
            child: Text(
              'Simpan',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        totalDistance = currentOdometer.toString();

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
          GestureDetector(
            onTap: activeMotor != null ? () => _showEditOdometerDialog(activeMotor) : null,
            child: Container(
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
              child: Stack(
                children: [
                  Padding(
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
                  // Edit icon hint
                  if (activeMotor != null)
                    Positioned(
                      top: AppSpacing.m,
                      right: AppSpacing.m,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
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

  /// Show location permission disclosure dialog (required by Google Play)
  Future<void> _showLocationDisclosureDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.l),
        ),
        icon: const Icon(
          Icons.location_on,
          color: AppColors.normalActive,
          size: 48,
        ),
        title: Text(
          'Izin Akses Lokasi',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glemo memerlukan akses lokasi di latar belakang untuk:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            _buildPermissionPoint(
              Icons.navigation,
              'Melacak perjalanan motor secara otomatis',
            ),
            const SizedBox(height: AppSpacing.s),
            _buildPermissionPoint(
              Icons.speed,
              'Menghitung jarak tempuh dengan akurat',
            ),
            const SizedBox(height: AppSpacing.s),
            _buildPermissionPoint(
              Icons.notifications,
              'Mengirim reminder servis berdasarkan jarak',
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.normalActive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.m),
                border: Border.all(
                  color: AppColors.normalActive.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        color: AppColors.normalActive,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Privasi Terjamin',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.normalActive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tracking hanya berjalan saat Anda memulai perjalanan. Data lokasi hanya digunakan untuk mencatat rute dan tidak dibagikan ke pihak manapun.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Aplikasi akan meminta izin akses lokasi. Pilih "Izinkan sepanjang waktu" agar tracking tetap berjalan meskipun aplikasi di-minimize.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.normalHover,
                    foregroundColor: AppColors.neutral0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.m,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xxl),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.normalHover,
                    side: BorderSide(
                      color: AppColors.normalHover,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.m,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xxl),
                    ),
                  ),
                  child: Text(
                    'Tidak Sekarang',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.normalHover,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
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
    }
  }

  Widget _buildPermissionPoint(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.normalActive,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral700,
            ),
          ),
        ),
      ],
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
            onTap: isTracking ? null : _showLocationDisclosureDialog,
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