import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/action_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class LupaPasswordEmailScreen extends ConsumerStatefulWidget {
  const LupaPasswordEmailScreen({super.key});

  @override
  ConsumerState<LupaPasswordEmailScreen> createState() => _LupaPasswordEmailScreenState();
}

class _LupaPasswordEmailScreenState extends ConsumerState<LupaPasswordEmailScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email tidak boleh kosong'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).forgotPassword(
            email: _emailController.text.trim(),
          );

      if (mounted) {
        context.go('/lupa-password-confirmation?email=${_emailController.text.trim()}');
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      body: Stack(
        children: [
          _buildHeader(),
          _buildFormContainer(context, authState),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFA80000),
            Color(0xFF530000),
            Color(0xFF4C0000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          WaveWidget(
            config: CustomConfig(
              gradients: [
                [const Color(0xFFA80000), const Color(0xFF530000)],
                [const Color(0xFF530000), const Color(0xFF4C0000)],
              ],
              durations: [19440, 10800],
              heightPercentages: [0.20, 0.25],
              blur: const MaskFilter.blur(BlurStyle.solid, 10),
            ),
            size: const Size(double.infinity, 300),
            waveAmplitude: 0,
          ),
          Text(
            'LUPA PASSWORD',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.neutral0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer(BuildContext context, AuthState authState) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height - 200,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.xxl),
            topRight: Radius.circular(AppSpacing.xxl),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Masukkan Email Terdaftar',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Center(
                child: Text(
                  'Kami akan mengirimkan link reset password ke email Anda',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl * 2),
              _buildInputField('Email'),
              const SizedBox(height: AppSpacing.xxl * 2),
              authState.maybeWhen(
                loading: () => const Center(child: CircularProgressIndicator()),
                orElse: () => ActionButton(
                  text: 'KIRIM LINK RESET PASSWORD',
                  onPressed: _handleSendResetEmail,
                  isPrimary: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GestureDetector(
                  onTap: () {
                    context.go('/login');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Sudah ingat password? ',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.darkHover,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint) {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8E98A8)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.darkHover, width: 2.0),
        ),
      ),
    );
  }
}