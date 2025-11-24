import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class UbahPasswordFormScreen extends ConsumerStatefulWidget {
  final String currentPassword;

  const UbahPasswordFormScreen({
    super.key,
    required this.currentPassword,
  });

  @override
  ConsumerState<UbahPasswordFormScreen> createState() => _UbahPasswordFormScreenState();
}

class _UbahPasswordFormScreenState extends ConsumerState<UbahPasswordFormScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    // Decode password dari base64
    final decodedPassword = utf8.decode(base64Decode(widget.currentPassword));

    await ref.read(authStateProvider.notifier).changePassword(
          currentPassword: decodedPassword,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen for success and errors
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      // Check if password was just changed successfully (loading -> authenticated)
      final wasLoading = previous?.maybeWhen(
        loading: () => true,
        orElse: () => false,
      ) ?? false;

      if (wasLoading) {
        next.maybeWhen(
          authenticated: (user) async {
            if (!mounted) return;
            final router = GoRouter.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Password berhasil diubah!',
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
            await Future.delayed(const Duration(seconds: 2));
            if (!mounted) return;
            router.go('/profil');
          },
          error: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message.replaceAll('Exception: ', ''),
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
                duration: const Duration(seconds: 3),
              ),
            );
          },
          orElse: () {},
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ubah Password',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      backgroundColor: AppColors.normalHover,
      body: Column(
        children: [
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
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan Password Baru',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildPasswordField(
                      hint: 'Masukkan Password Baru',
                      controller: _newPasswordController,
                      isVisible: _isPasswordVisible,
                      onToggle: (value) {
                        setState(() {
                          _isPasswordVisible = value;
                        });
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    PasswordStrengthIndicator(
                      password: _newPasswordController.text,
                      showRequirements: true,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildPasswordField(
                      hint: 'Konfirmasi Password Baru',
                      controller: _confirmPasswordController,
                      isVisible: _isConfirmPasswordVisible,
                      onToggle: (value) {
                        setState(() {
                          _isConfirmPasswordVisible = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Password minimal 8 karakter',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    authState.maybeWhen(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      orElse: () => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.normalHover,
                          foregroundColor: AppColors.neutral0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.xxl),
                          ),
                          elevation: 0,
                        ),
                          child: Text(
                            'Ubah Password',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required Function(bool) onToggle,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8E98A8)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.normalHover, width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off_outlined,
            color: const Color(0xFF8E98A8),
          ),
          onPressed: () {
            onToggle(!isVisible);
          },
        ),
      ),
    );
  }
}