import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/action_button.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _timer;
  bool _isChecking = false;
  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isChecking) return;

      _isChecking = true;
      try {
        final repository = ref.read(authRepositoryProvider);
        final isVerified = await repository.checkEmailVerified();

        if (isVerified && mounted) {
          _timer?.cancel();
          _showSuccessDialog();
        }
      } catch (e) {
        debugPrint('Error checking verification: $e');
      } finally {
        _isChecking = false;
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.l),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Email Terverifikasi!',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Email kamu sudah berhasil diverifikasi. Silakan login untuk melanjutkan.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ActionButton(
            text: 'Login Sekarang',
            onPressed: () async {
              // Cache navigators before async operations
              final navigator = GoRouter.of(context);
              final dialogNavigator = Navigator.of(context);

              // Logout user supaya mereka harus login manual
              // Ini memastikan pending motor data akan tersimpan saat login
              // NOTE: Kita TIDAK gunakan authStateProvider.logout() karena itu akan
              // clear pending motor data dari SharedPreferences
              try {
                debugPrint('🔐 [EMAIL_VERIFY] Logging out user...');
                await FirebaseAuth.instance.signOut();
                debugPrint('✅ [EMAIL_VERIFY] User logged out successfully');

                // Force invalidate authStateProvider to ensure router knows user is logged out
                if (mounted) {
                  ref.invalidate(authStateProvider);
                  debugPrint('♻️ [EMAIL_VERIFY] AuthStateProvider invalidated');
                }

                // Wait for auth state to propagate to prevent race condition
                // Router redirect checks auth state - we need to ensure it's updated
                await Future.delayed(const Duration(milliseconds: 500));
                debugPrint('⏱️ [EMAIL_VERIFY] Auth state propagation delay complete');
              } catch (e) {
                debugPrint('❌ [EMAIL_VERIFY] Error logging out: $e');
              }

              if (mounted) {
                // Close dialog first
                dialogNavigator.pop();

                // Small delay to ensure dialog closes before navigation
                await Future.delayed(const Duration(milliseconds: 150));

                if (mounted) {
                  debugPrint('🔄 [EMAIL_VERIFY] Navigating to login screen...');
                  navigator.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email verifikasi berhasil dikirim ulang',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral0,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.m),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.m),
            ),
          ),
        );

        setState(() {
          _canResend = false;
          _resendCountdown = 60;
        });

        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          setState(() {
            _resendCountdown--;
            if (_resendCountdown <= 0) {
              _canResend = true;
              timer.cancel();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral0,
      appBar: AppBar(
        backgroundColor: AppColors.normal,
        elevation: 0,
        title: Text(
          'Verifikasi Email',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.neutral0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.normalHover.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: AppColors.normal,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Verifikasi Email Kamu',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Kami telah mengirimkan email verifikasi ke:',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                widget.email,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSpacing.m),
                  border: Border.all(
                    color: AppColors.neutral300,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.normal,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            'Langkah-langkah:',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _buildStep('1', 'Buka email kamu'),
                    const SizedBox(height: AppSpacing.s),
                    _buildStep(
                        '2', 'Cari email dari GLIMO (cek folder spam jika tidak ada)'),
                    const SizedBox(height: AppSpacing.s),
                    _buildStep('3', 'Klik link verifikasi di email'),
                    const SizedBox(height: AppSpacing.s),
                    _buildStep('4', 'Kembali ke app ini'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Tidak menerima email?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              ActionButton(
                text: _canResend
                    ? 'Kirim Ulang Email'
                    : 'Kirim Ulang ($_resendCountdown detik)',
                onPressed: _canResend ? _resendEmail : null,
                isPrimary: false,
              ),
              const SizedBox(height: AppSpacing.l),
              TextButton(
                onPressed: () async {
                  // Cache navigator before async operations
                  final navigator = GoRouter.of(context);

                  _timer?.cancel();

                  // Logout user supaya mereka harus login manual
                  // NOTE: Kita TIDAK gunakan authStateProvider.logout() karena itu akan
                  // clear pending motor data dari SharedPreferences
                  try {
                    debugPrint('🔐 [EMAIL_VERIFY] User clicked back to login, logging out...');
                    await FirebaseAuth.instance.signOut();
                    debugPrint('✅ [EMAIL_VERIFY] User logged out before returning to login');

                    // Force invalidate authStateProvider to ensure router knows user is logged out
                    if (mounted) {
                      ref.invalidate(authStateProvider);
                      debugPrint('♻️ [EMAIL_VERIFY] AuthStateProvider invalidated');
                    }

                    // Wait for auth state to propagate to prevent race condition
                    await Future.delayed(const Duration(milliseconds: 500));
                    debugPrint('⏱️ [EMAIL_VERIFY] Auth state propagation delay complete');
                  } catch (e) {
                    debugPrint('❌ [EMAIL_VERIFY] Error logging out: $e');
                  }

                  if (mounted) {
                    debugPrint('🔄 [EMAIL_VERIFY] Navigating to login screen...');
                    navigator.go('/login');
                  }
                },
                child: Text(
                  'Kembali ke Login',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.normal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.normal,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
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
}
