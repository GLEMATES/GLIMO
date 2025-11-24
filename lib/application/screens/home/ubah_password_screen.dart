import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';

class UbahPasswordScreen extends ConsumerStatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  ConsumerState<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends ConsumerState<UbahPasswordScreen> {
  final _currentPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyPassword() async {
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password tidak boleh kosong',
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
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify password dengan Firebase
      final firebaseAuth = FirebaseAuth.instance;
      final user = firebaseAuth.currentUser;

      if (user == null || user.email == null) {
        throw Exception('User tidak ditemukan');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Test re-authentication untuk verify password
      await user.reauthenticateWithCredential(credential);

      // Kalau berhasil, navigate ke form screen
      if (!mounted) return;

      // Encode password dengan base64 untuk avoid special character issues
      final encodedPassword = base64Encode(utf8.encode(_currentPasswordController.text));

      // ignore: use_build_context_synchronously
      context.push('/ubah-password-form?currentPassword=$encodedPassword');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gagal memverifikasi password';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Password lama salah';
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
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
    } catch (e) {
      if (!mounted) return;

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan: $e',
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
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Verifikasi Password Lama',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Kami perlu memverifikasi bahwa Anda adalah pemilik akun sebelum mengganti password. Masukkan password lama Anda untuk melanjutkan.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: AppSpacing.xxl * 2),
                    _buildPasswordField(),
                    const SizedBox(height: AppSpacing.xxl * 2),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _handleVerifyPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.normalHover,
                          foregroundColor: AppColors.neutral0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.xxl),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Lanjutkan',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildPasswordField() {
    return TextField(
      controller: _currentPasswordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Masukkan Password Lama',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8E98A8)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.normalHover, width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off_outlined,
            color: const Color(0xFF8E98A8),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}