import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/action_button.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../widgets/email_availability_indicator.dart';
import '../../utils/email_checker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import 'privacy_policy_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  EmailStatus _emailStatus = EmailStatus.initial;
  Timer? _emailCheckTimer;

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkEmailAvailability(String email) {
    // Cancel timer sebelumnya
    _emailCheckTimer?.cancel();

    // Jika email kosong, reset status
    if (email.isEmpty) {
      setState(() {
        _emailStatus = EmailStatus.initial;
      });
      return;
    }

    // Set status checking
    setState(() {
      _emailStatus = EmailStatus.checking;
    });

    // Debounce: tunggu 800ms sebelum check
    _emailCheckTimer = Timer(const Duration(milliseconds: 800), () async {
      final status = await EmailChecker.checkEmailAvailability(email);
      if (mounted) {
        setState(() {
          _emailStatus = status;
        });
      }
    });
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Check jika email sudah terdaftar
    if (_emailStatus == EmailStatus.taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email sudah terdaftar. Gunakan email lain atau login.',
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

    // Check jika email masih dalam proses pengecekan
    if (_emailStatus == EmailStatus.checking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon tunggu, sedang memeriksa ketersediaan email...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral0,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.neutral600,
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

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda harus menyetujui Syarat dan Ketentuan',
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motor_filled', true);

    ref.read(authStateProvider.notifier).register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) {
          if (mounted) {
            context.go('/email-verification?email=${_emailController.text.trim()}');
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
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
          // Reset auth state setelah error ditampilkan agar bisa retry
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.invalidate(authStateProvider);
            }
          });
        },
        orElse: () {},
      );
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            'SELAMAT DATANG',
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 210),
        child: Container(
          width: double.infinity,
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Masukkan Data Diri Kamu',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildInputField(
                  'Nama Lengkap',
                  _fullNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildInputField(
                  'Email',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _checkEmailAvailability(value);
                  },
                ),
                EmailAvailabilityIndicator(status: _emailStatus),
                const SizedBox(height: AppSpacing.xxl),
                _buildPasswordField(
                  'Password',
                  _passwordController,
                  _obscurePassword,
                  () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                    return null;
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
                  'Konfirmasi Password',
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                  () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password tidak boleh kosong';
                    }
                    if (value != _passwordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.l),
                _buildTermsAndConditions(),
                const SizedBox(height: AppSpacing.xxl),
                authState.maybeWhen(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkHover,
                    ),
                  ),
                  orElse: () => ActionButton(
                    text: 'DAFTAR',
                    onPressed: _handleRegister,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      context.go('/login');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Sudah Punya akun? ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Masuk',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkHover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8E98A8)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.darkHover, width: 2.0),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool obscureText,
    VoidCallback onToggle, {
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8E98A8)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.darkHover, width: 2.0),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF8E98A8),
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildTermsAndConditions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (bool? value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              activeColor: AppColors.darkHover,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );

                if (result == true) {
                  setState(() {
                    _agreedToTerms = true;
                  });
                }
              },
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  text: 'Saya Setuju dengan ',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.neutral700),
                  children: [
                    TextSpan(
                      text: 'Syarat dan Ketentuan',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.normal,
                      ),
                    ),
                    TextSpan(
                      text: ' dan Pemberitahuan Privasi yang berlaku.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.neutral700),
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
}