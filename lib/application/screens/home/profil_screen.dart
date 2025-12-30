import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/tracking_mode_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/profile_menu_item.dart';
import '../../widgets/profile_subscription_banner.dart';
import '../../services/notification_service.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  int _tapCount = 0;
  bool _showTestButton = false;

  void _onProfilePhotoTap() {
    // Test menu tersedia dengan tap 5x di foto profile
    // Temporarily enabled untuk internal testing
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _showTestButton = true;
        _tapCount = 0; // Reset
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🧪 Mode Developer Aktif',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral0,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.normalHover,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _testNotification() async {
    // Clear daily check throttle first for testing
    final notifService = NotificationService();
    await notifService.clearDailyCheckThrottle();

    if (mounted) {
      context.push('/test-notification');
    }
  }

  void _showGPSTrackingSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.l,
            left: AppSpacing.l,
            right: AppSpacing.l,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + AppSpacing.l,
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final trackingMode = ref.watch(trackingModeProvider);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.normalHover.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: AppColors.normalHover,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Text(
                        'Pengaturan GPS Tracking',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Pilih Mode Tracking',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildModeOption(
                    ref,
                    TrackingMode.manual,
                    'Manual',
                    'Gunakan tombol untuk mulai/berhenti tracking',
                    trackingMode.mode == TrackingMode.manual,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _buildModeOption(
                    ref,
                    TrackingMode.automatic,
                    'Otomatis',
                    'Tracking dimulai otomatis saat berkendara',
                    trackingMode.mode == TrackingMode.automatic,
                  ),
                  if (!trackingMode.isActivityRecognitionAvailable &&
                      trackingMode.mode == TrackingMode.automatic) ...[
                    const SizedBox(height: AppSpacing.m),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Text(
                              'Izin deteksi aktivitas diperlukan',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.l),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cara Kerja Mode Otomatis',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        _buildInfoItem(Icons.play_arrow, 'Mulai otomatis saat terdeteksi berkendara'),
                        _buildInfoItem(Icons.schedule, 'Berhenti 2 menit setelah aktivitas berhenti'),
                        _buildInfoItem(Icons.power_settings_new, 'Hemat baterai, tidak perlu buka aplikasi'),
                        _buildInfoItem(Icons.verified_user, 'Memerlukan izin deteksi aktivitas'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.normalHover,
                        foregroundColor: AppColors.neutral0,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModeOption(
    WidgetRef ref,
    TrackingMode mode,
    String title,
    String description,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(trackingModeProvider.notifier).setMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.normalHover.withValues(alpha: 0.1)
              : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.s),
          border: Border.all(
            color: isSelected ? AppColors.normalHover : AppColors.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.normalHover : AppColors.neutral400,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.normalHover : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.normalHover,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildHeader(ref),
          _buildContent(context, ref),
          Positioned(
            top: 240,
            left: AppSpacing.l,
            right: AppSpacing.l,
            child: const ProfileSubscriptionBanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 300,
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
            size: const Size(double.infinity, 300),
            waveAmplitude: 5,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.l,
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                ),
                child: _buildProfileInfo(ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Column(
      children: [
        GestureDetector(
          onTap: _onProfilePhotoTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
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
                          size: 40,
                        );
                      },
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          profile.name,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 270),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 160),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    child: _buildMenuList(context, ref),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ProfileMenuItem(
          icon: Icons.edit_outlined,
          title: 'Edit Profil',
          onTap: () {
            context.push('/edit-profil');
          },
        ),
        ProfileMenuItem(
          icon: Icons.analytics_outlined,
          title: 'Analisis Penggunaan',
          onTap: () {
            context.push('/analisis-penggunaan');
          },
        ),
        // ProfileMenuItem(
        //   icon: Icons.scatter_plot,
        //   title: 'K-Means (Demo Presentasi)',
        //   onTap: () {
        //     context.push('/kmeans-demo');
        //   },
        // ),
        ProfileMenuItem(
          icon: Icons.navigation,
          title: 'Pengaturan GPS Tracking',
          onTap: () {
            _showGPSTrackingSettings(context, ref);
          },
        ),
        ProfileMenuItem(
          icon: Icons.info_outline,
          title: 'Tentang Aplikasi',
          onTap: () {
            context.push('/tentang-aplikasi');
          },
        ),
        ProfileMenuItem(
          icon: Icons.motorcycle_outlined,
          title: 'Motor Saya',
          onTap: () {
            context.push('/motor-saya');
          },
        ),
        ProfileMenuItem(
          icon: Icons.lock_outline,
          title: 'Ubah Password',
          onTap: () {
            context.push('/ubah-password');
          },
        ),
        ProfileMenuItem(
          icon: Icons.help_outline,
          title: 'Bantuan',
          onTap: () {
            context.push('/bantuan');
          },
        ),
        // Hidden developer feature: Test notification (Debug mode only)
        // Temporarily enabled untuk internal testing
        if (_showTestButton)
          ProfileMenuItem(
            icon: Icons.developer_mode,
            title: '🛠️ Developer Menu',
            onTap: () => context.push('/developer-menu'),
          ),
        if (kDebugMode && _showTestButton)
          ProfileMenuItem(
            icon: Icons.notifications_active,
            title: '🧪 Test Notification',
            onTap: _testNotification,
          ),
        ProfileMenuItem(
          icon: Icons.logout,
          title: 'Keluar',
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text(
                    'Konfirmasi Keluar',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin keluar dari akun?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.only(
                    bottom: AppSpacing.l,
                    right: AppSpacing.l,
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.m),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await ref.read(authStateProvider.notifier).logout();
                            // Router akan handle redirect ke login otomatis
                            // karena auth state sudah jadi unauthenticated
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.normalHover,
                            foregroundColor: AppColors.neutral0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.m),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                          ),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
          isLast: true,
        ),
      ],
    );
  }
}