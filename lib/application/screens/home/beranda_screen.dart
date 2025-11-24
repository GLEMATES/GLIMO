import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/tracking_mode_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/live_tracking_map.dart';
import '../../widgets/total_distance_card.dart';
import '../../widgets/monthly_stats_card.dart';
import '../../widgets/trip_recovery_dialog.dart';
import '../../widgets/daily_service_checker.dart';
import '../../widgets/debug_panel_widget.dart';

class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildHeader(ref),
          _buildContent(context),
          Positioned(
            top: 150,
            left: AppSpacing.l,
            right: AppSpacing.l,
            child: const TotalDistanceCard(),
          ),
          const TripRecoveryChecker(),
          const DailyServiceChecker(),
          const DebugPanelWidget(),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Container(
        width: double.infinity,
        height: 280,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF530000),
              Color(0xFF860000),
              Color(0xFFE40000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            WaveWidget(
            config: CustomConfig(
              gradients: [
                [const Color(0xFF530000).withValues(alpha: 0.3), const Color(0xFF860000).withValues(alpha: 0.3)],
                [const Color(0xFF860000).withValues(alpha: 0.2), const Color(0xFFE40000).withValues(alpha: 0.2)],
              ],
              durations: [19440, 10800],
              heightPercentages: [0.20, 0.25],
              blur: const MaskFilter.blur(BlurStyle.solid, 10),
            ),
            size: const Size(double.infinity, 280),
            waveAmplitude: 5,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.m,
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                ),
                child: _buildUserInfo(ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final firstName = profile.name.split(' ').first;

    return Builder(
      builder: (context) {
        return Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: profile.photoUrl != null
                    ? Image.file(
                        File(profile.photoUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi $firstName',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getGreeting(),
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                context.push('/notifikasi');
              },
            ),
          ],
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi!';
    } else if (hour < 15) {
      return 'Selamat Siang!';
    } else if (hour < 18) {
      return 'Selamat Sore!';
    } else {
      return 'Selamat Malam!';
    }
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 250),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 160,
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                  bottom: AppSpacing.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrackingModeSelector(context),
                    const SizedBox(height: AppSpacing.l),
                    const LiveTrackingMap(),
                    const SizedBox(height: AppSpacing.s),
                    // Monthly Statistics
                    const MonthlyStatsCard(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingModeSelector(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final trackingMode = ref.watch(trackingModeProvider);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.neutral0,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neutral200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.normalHover.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.route,
                        color: AppColors.normalHover,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Tracking',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trackingMode.mode == TrackingMode.automatic
                                ? 'Deteksi otomatis saat berkendara'
                                : 'Kontrol manual dengan tombol',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeOption(
                        ref,
                        TrackingMode.manual,
                        Icons.ads_click,
                        'Manual',
                        trackingMode.mode == TrackingMode.manual,
                        isLeft: true,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: AppColors.neutral200,
                    ),
                    Expanded(
                      child: _buildModeOption(
                        ref,
                        TrackingMode.automatic,
                        Icons.autorenew,
                        'Otomatis',
                        trackingMode.mode == TrackingMode.automatic,
                        isLeft: false,
                      ),
                    ),
                  ],
                ),
              ),
              if (!trackingMode.isActivityRecognitionAvailable &&
                  trackingMode.mode == TrackingMode.automatic)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.05),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.neutral200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Izin deteksi aktivitas diperlukan',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOption(
    WidgetRef ref,
    TrackingMode mode,
    IconData icon,
    String title,
    bool isSelected, {
    required bool isLeft,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(trackingModeProvider.notifier).setMode(mode);
        },
        borderRadius: BorderRadius.only(
          bottomLeft: isLeft ? const Radius.circular(12) : Radius.zero,
          bottomRight: !isLeft ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.normalHover : AppColors.neutral400,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.normalHover : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}