import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late DateTime _splashStartTime;
  static const int _minimumSplashDuration = 5000; // 5 seconds

  late Animation<double> _circleYPosition;
  late Animation<double> _circleSize;
  late Animation<Color?> _circleColor;
  late Animation<double> _circleShadowBlur;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoYOffset;
  late Animation<double> _secondLogoOpacity;

  @override
  void initState() {
    super.initState();

    // Record when splash screen starts
    _splashStartTime = DateTime.now();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _minimumSplashDuration),
    );

    _setupAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mainController.forward().then((_) async {
          if (mounted) {
            await _ensureMinimumDurationAndNavigate();
          }
        });
      }
    });
  }

  /// Ensures splash screen shows for minimum duration before navigating
  Future<void> _ensureMinimumDurationAndNavigate() async {
    final elapsed = DateTime.now().difference(_splashStartTime).inMilliseconds;
    final remaining = _minimumSplashDuration - elapsed;

    // Wait for remaining time if animation finished early
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted) {
      await _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final hasEverLoggedIn = prefs.getBool('hasEverLoggedIn') ?? false;

    final authState = ref.read(authStateProvider);

    authState.maybeWhen(
      authenticated: (_) {
        // Jika sudah login, langsung ke beranda (bypass splash dan onboarding)
        if (mounted) {
          context.go('/beranda');
        }
      },
      orElse: () {
        // Jika belum login (unauthenticated atau error)
        if (hasEverLoggedIn || hasSeenOnboarding) {
          // User pernah login atau sudah lihat onboarding → langsung ke login
          if (mounted) {
            context.go('/login');
          }
        } else {
          // User pertama kali buka app → tampilkan onboarding
          if (mounted) {
            context.go('/onboarding');
          }
        }
      },
    );
  }

  void _setupAnimations() {
    _circleYPosition = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.5, end: 0.0)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 85,
      ),
    ]).animate(_mainController);
    
    _circleSize = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.1),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 0.47)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.47, end: 0.70)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.70, end: 2.4)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(2.4),
        weight: 20,
      ),
    ]).animate(_mainController);
    
    _circleColor = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ConstantTween<Color>(AppColors.dark),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: AppColors.dark,
          end: AppColors.normal,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: AppColors.normal,
          end: AppColors.light,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: AppColors.light,
          end: AppColors.dark,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 19,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: AppColors.dark,
          end: AppColors.neutral0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 16,
      ),
    ]).animate(_mainController);
    
    _circleShadowBlur = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(4.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4.0, end: 25.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(25.0),
        weight: 50,
      ),
    ]).animate(_mainController);
    
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 20,
      ),
    ]).animate(_mainController);
    
    _logoYOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -70.0)
          .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_mainController);
    
    _secondLogoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_mainController);
    
    _mainController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final shortestSide = size.shortestSide;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    final double logoSize = shortestSide * 0.35;
    final double currentCircleSize = shortestSide * _circleSize.value;
    final Color currentCircleColor = _circleColor.value ?? AppColors.dark;
    final double currentBlurRadius = _circleShadowBlur.value;
    final double circleYOffset = _circleYPosition.value * size.height;
    final double circleY = centerY + circleYOffset - (currentCircleSize / 2);
    final double circleX = centerX - (currentCircleSize / 2);
    final double logoX = centerX - (logoSize / 2);
    final double logoY = centerY - (logoSize * 0.45) + _logoYOffset.value;
    final double secondLogoX = centerX - (logoSize / 2);
    final double secondLogoY = centerY + (logoSize * 0.1);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: circleX,
            top: circleY,
            child: Container(
              width: currentCircleSize,
              height: currentCircleSize,
              decoration: BoxDecoration(
                color: currentCircleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40000000),
                    offset: const Offset(0, 4),
                    blurRadius: currentBlurRadius,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.lightActive.withValues(
                      alpha: _mainController.value > 0.5 ? 1.0 : 0.5
                    ),
                    offset: const Offset(0, -2),
                    blurRadius: currentBlurRadius * 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            left: logoX,
            top: logoY,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: Image.asset(
                'assets/images/GELMO_Logo_Final.png',
                width: logoSize,
                height: logoSize * 0.9,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          if (_secondLogoOpacity.value > 0.01)
            Positioned(
              left: secondLogoX,
              top: secondLogoY,
              child: Opacity(
                opacity: _secondLogoOpacity.value,
                child: Transform.scale(
                  scale: _secondLogoOpacity.value,
                  child: Image.asset(
                    'assets/images/GLEMO_Text_Final.png',
                    width: logoSize,
                    height: logoSize * 0.3,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}