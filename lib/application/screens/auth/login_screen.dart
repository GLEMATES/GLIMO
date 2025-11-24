import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/action_button.dart';
import '../../widgets/google_signin_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../providers/motor_list_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isEmailLoading = true;
    });

    ref.read(authStateProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _handleGoogleSignIn() {
    setState(() {
      _isGoogleLoading = true;
    });

    ref.read(authStateProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) async {
          // Reset loading state
          if (mounted) {
            setState(() {
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
          }

          // Load motors untuk check apakah user sudah punya motor
          await ref.read(motorListProvider.notifier).loadMotors();
          final motors = ref.read(motorListProvider);

          if (context.mounted) {
            if (motors.isEmpty) {
              // Belum ada motor → redirect ke tambah motor (WAJIB!)
              context.go('/motor-details');
            } else {
              // Sudah ada motor → redirect ke beranda
              context.go('/beranda');
            }
          }
        },
        error: (message) {
          // Reset loading state
          if (mounted) {
            setState(() {
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
          }

          if (message == 'EMAIL_NOT_VERIFIED') {
            context.go('/email-verification?email=${_emailController.text.trim()}');
            ref.invalidate(authStateProvider);
            return;
          }

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
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 3),
            ),
          );

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
                    'Masukkan Alamat Email Kamu Untuk Login',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl * 2),
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
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildPasswordField('Password', context),
                const SizedBox(height: AppSpacing.xxl),
                _isEmailLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.darkHover,
                        ),
                      )
                    : ActionButton(
                        text: 'MASUK',
                        onPressed: _handleLogin,
                        isPrimary: true,
                      ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Text(
                    'Atau',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isGoogleLoading,
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      context.go('/register');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Tidak memiliki akun? ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Daftar',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkHover,
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
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildPasswordField(String hint, BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
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
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF8E98A8),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password tidak boleh kosong';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              context.push('/lupa-password-email');
            },
            child: Text(
              'Lupa Password?',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.darkHover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}