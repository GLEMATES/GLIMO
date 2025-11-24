import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/password_strength_indicator.dart';

class LupaPasswordFormScreen extends ConsumerStatefulWidget {
  const LupaPasswordFormScreen({super.key});

  @override
  ConsumerState<LupaPasswordFormScreen> createState() => _LupaPasswordFormScreenState();
}

class _LupaPasswordFormScreenState extends ConsumerState<LupaPasswordFormScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password berhasil direset!',
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
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reset Password',
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
                      'Buat Password Baru',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Pastikan password baru Anda berbeda dari password sebelumnya untuk keamanan akun Anda.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildPasswordField(
                      hint: 'Masukkan Password Baru',
                      controller: _passwordController,
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
                      password: _passwordController.text,
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
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.normalHover,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.xxl),
                          ),
                        ),
                        child: Text(
                          'Reset Password',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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