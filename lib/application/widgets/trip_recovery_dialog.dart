import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gps_tracking_provider.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

/// Widget to check and show recovery dialog for interrupted tracking session
class TripRecoveryChecker extends ConsumerStatefulWidget {
  const TripRecoveryChecker({super.key});

  @override
  ConsumerState<TripRecoveryChecker> createState() => _TripRecoveryCheckerState();
}

class _TripRecoveryCheckerState extends ConsumerState<TripRecoveryChecker> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // Delay check to ensure provider is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecovery();
    });
  }

  void _checkRecovery() {
    if (_hasChecked) return;
    _hasChecked = true;

    final trackingState = ref.read(gpsTrackingProvider);

    // If status is paused, it means we recovered a previous session
    if (trackingState.status == TrackingStatus.paused &&
        trackingState.positions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showRecoveryDialog();
        }
      });
    }
  }

  void _showRecoveryDialog() {
    final trackingState = ref.read(gpsTrackingProvider);
    final distance = trackingState.totalDistance;
    final duration = trackingState.getFormattedDuration();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restore,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  'Tracking Terdeteksi',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kami menemukan sesi tracking yang belum selesai:',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.m),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSpacing.s),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.route,
                      label: 'Jarak',
                      value: '${distance.toStringAsFixed(2)} km',
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _buildInfoRow(
                      icon: Icons.timer,
                      label: 'Durasi',
                      value: duration,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _buildInfoRow(
                      icon: Icons.gps_fixed,
                      label: 'GPS Points',
                      value: '${trackingState.positions.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Apakah Anda ingin melanjutkan atau membuang tracking ini?',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: AppSpacing.l,
            right: AppSpacing.l,
            left: AppSpacing.l,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(gpsTrackingProvider.notifier).resetTracking();
                      Navigator.of(dialogContext).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                    ),
                    child: const Text('Buang'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(gpsTrackingProvider.notifier).resumeTracking();
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tracking dilanjutkan! Scroll ke bawah untuk melihat map.',
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.normalHover,
                      foregroundColor: AppColors.neutral0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                    ),
                    child: const Text('Lanjutkan'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.neutral600,
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is an invisible widget that just checks for recovery
    return const SizedBox.shrink();
  }
}
