import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'application/services/background_tracking_service.dart';
import 'application/services/notification_service.dart';
import 'application/utils/navigation_helper.dart';
import 'application/providers/auth_provider.dart';
import 'application/providers/auth_state.dart';
import 'application/screens/auth/login_screen.dart';
import 'application/screens/auth/motor_details_screen.dart';
import 'application/screens/auth/motor_model_screen.dart';
import 'application/screens/auth/motor_type_screen.dart';
import 'application/screens/auth/register_screen.dart';
import 'application/screens/auth/privacy_policy_screen.dart';
import 'application/screens/auth/lupa_password_email_screen.dart';
import 'application/screens/auth/lupa_password_otp_screen.dart';
import 'application/screens/auth/lupa_password_form_screen.dart';
import 'application/screens/auth/lupa_password_confirmation_screen.dart';
import 'application/screens/auth/email_verification_screen.dart';
import 'application/screens/home/beranda_screen.dart';
import 'application/screens/home/monitoring_screen.dart';
import 'application/screens/home/profil_screen.dart';
import 'application/screens/home/riwayat_screen.dart';
import 'application/screens/home/current_location_screen.dart';
import 'application/screens/home/tentang_aplikasi_screen.dart';
import 'application/screens/home/analisis_penggunaan_screen.dart';
import 'application/screens/home/motor_saya_screen.dart';
import 'application/screens/home/ubah_password_screen.dart';
import 'application/screens/home/ubah_password_form_screen.dart';
import 'application/screens/home/bantuan_screen.dart';
import 'application/screens/home/subscription_management_screen.dart';
import 'application/screens/home/edit_profil_screen.dart';
import 'application/screens/home/developer_menu_screen.dart';
import 'application/screens/premium_screen.dart';
import 'application/screens/home/service_detail_by_date_screen.dart';
import 'application/screens/home/component_timeline_screen.dart';
import 'application/screens/onboarding/onboarding_screen.dart';
import 'application/screens/splash/splash_screen.dart';
import 'application/themes/app_theme.dart';
import 'application/widgets/app_bottom_nav_bar.dart';
import 'application/screens/home/notification_screen.dart';
import 'test_notification_simple.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notifier to trigger router refresh when auth state changes
final authChangeNotifier = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await BackgroundTrackingService.initialize();

  await NotificationService().initialize();

  // Initialize navigation helper with global navigator key
  NavigationHelper.initialize(navigatorKey);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: GlemoApp(),
    ),
  );
}

class GlemoApp extends ConsumerStatefulWidget {
  const GlemoApp({super.key});

  @override
  ConsumerState<GlemoApp> createState() => _GlemoAppState();
}

class _GlemoAppState extends ConsumerState<GlemoApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create router only ONCE - redirect logic will handle auth state changes
    _router = _createRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and notify router
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      // Increment counter to trigger router refresh
      authChangeNotifier.value++;
    });

    return MaterialApp.router(
      title: 'GLIMO - Motor Service Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

CustomTransitionPage _buildPageWithSlideTransition({
  required Widget child,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

CustomTransitionPage _buildPageWithFadeTransition({
  required Widget child,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

GoRouter _createRouter(WidgetRef ref) {
  // Initial location is always '/splash' to ensure proper app initialization
  // Splash screen will handle navigation based on auth state and onboarding status
  String initialLocation = '/splash';

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authChangeNotifier, // Refresh routes when auth state changes
    redirect: (context, state) async {
      // Read current auth state from provider (not from closure)
      final currentAuthState = ref.read(authStateProvider);
      final isAuthenticated = currentAuthState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

      // Jika authenticated, cek apakah motor sudah di-fill (ONLY pada registration flow)
      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        // Cek apakah ini registration flow dengan motor_filled flag
        final motorFilled = prefs.getBool('motor_filled') ?? false;

        final currentPath = state.matchedLocation;

        // HANYA apply motor-details redirect jika motor_filled flag TRUE (dari registration)
        // Setelah user berhasil login sekali, flag di-clear dan tidak akan redirect ke motor-details lagi
        if (motorFilled && currentPath != '/motor-details' && currentPath != '/motor-model' && !currentPath.startsWith('/motor-type/')) {
          return '/motor-details';
        }

        // Jika motor_filled dan user di motor-details page, allow
        if (motorFilled && (currentPath == '/motor-details' || currentPath == '/motor-model' || currentPath.startsWith('/motor-type/'))) {
          return null; // allow
        }

        // Clear motor_filled setelah user successfully navigate away dari motor-details
        if (motorFilled && currentPath == '/beranda') {
          await prefs.remove('motor_filled');
        }
      }

      // Continue dengan logic yang sudah ada
      final currentPath = state.matchedLocation;

      final publicPaths = [
        '/splash',
        '/onboarding',
        '/login',
        '/register',
        '/privacy-policy',
        '/motor-details',
        '/motor-model',
        '/motor-type',
        '/lupa-password-email',
        '/lupa-password-otp',
        '/lupa-password-form',
        '/lupa-password-confirmation',
        '/email-verification',
      ];

      final isPublicPath = publicPaths.contains(currentPath) || currentPath.startsWith('/motor-type/');

      // Jika sudah authenticated dan mencoba akses login/register, redirect ke beranda
      // (tapi izinkan akses ke motor-details untuk input motor setelah register)
      if (isAuthenticated && (currentPath == '/login' || currentPath == '/register')) {
        return '/beranda';
      }

      // Jika belum authenticated dan mencoba akses protected paths, redirect ke login
      if (!isAuthenticated && !isPublicPath) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/lupa-password-email',
        name: 'lupa-password-email',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const LupaPasswordEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/lupa-password-otp',
        name: 'lupa-password-otp',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const LupaPasswordOTPScreen(),
        ),
      ),
      GoRoute(
        path: '/lupa-password-form',
        name: 'lupa-password-form',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const LupaPasswordFormScreen(),
        ),
      ),
      GoRoute(
        path: '/lupa-password-confirmation',
        name: 'lupa-password-confirmation',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _buildPageWithSlideTransition(
            child: LupaPasswordConfirmationScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _buildPageWithSlideTransition(
            child: EmailVerificationScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/motor-details',
        name: 'motor-details',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const MotorDetailsScreen(),
        ),
      ),
      GoRoute(
        path: '/motor-model',
        name: 'motor-model',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const MotorModelScreen(),
        ),
      ),
      GoRoute(
        path: '/motor-type/:model',
        name: 'motor-type',
        pageBuilder: (context, state) {
          final model = state.pathParameters['model'] ?? 'Undefined';
          return _buildPageWithSlideTransition(
            child: MotorTypeScreen(model: model),
          );
        },
      ),
      GoRoute(
        path: '/current-location',
        name: 'current-location',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const CurrentLocationScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profil',
        name: 'edit-profil',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const EditProfilScreen(),
        ),
      ),
      GoRoute(
        path: '/tentang-aplikasi',
        name: 'tentang-aplikasi',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const TentangAplikasiScreen(),
        ),
      ),
      GoRoute(
        path: '/analisis-penggunaan',
        name: 'analisis-penggunaan',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const AnalisisPenggunaanScreen(),
        ),
      ),
      GoRoute(
        path: '/motor-saya',
        name: 'motor-saya',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const MotorSayaScreen(),
        ),
      ),
      GoRoute(
        path: '/ubah-password',
        name: 'ubah-password',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const UbahPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/ubah-password-form',
        name: 'ubah-password-form',
        pageBuilder: (context, state) {
          final currentPassword = state.uri.queryParameters['currentPassword'] ?? '';
          return _buildPageWithSlideTransition(
            child: UbahPasswordFormScreen(currentPassword: currentPassword),
          );
        },
      ),
      GoRoute(
        path: '/bantuan',
        name: 'bantuan',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const BantuanScreen(),
        ),
      ),
      GoRoute(
        path: '/test-notification',
        name: 'test-notification',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const SimpleNotificationTest(),
        ),
      ),
      GoRoute(
        path: '/subscription-management',
        name: 'subscription-management',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const SubscriptionManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/premium',
        name: 'premium',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const PremiumScreen(),
        ),
      ),
      GoRoute(
        path: '/developer-menu',
        name: 'developer-menu',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const DeveloperMenuScreen(),
        ),
      ),
      GoRoute(
        path: '/service-detail-by-date',
        name: 'service-detail-by-date',
        pageBuilder: (context, state) {
          DateTime date = DateTime.now();
          if (state.extra is String) {
            try {
              date = DateTime.parse(state.extra as String);
            } catch (e) {
              date = DateTime.now();
            }
          }
          return _buildPageWithSlideTransition(
            child: ServiceDetailByDateScreen(date: date),
          );
        },
      ),
      GoRoute(
        path: '/component-timeline',
        name: 'component-timeline',
        pageBuilder: (context, state) {
          final componentName = state.extra as String? ?? 'Unknown';
          return _buildPageWithSlideTransition(
            child: ComponentTimelineScreen(componentName: componentName),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beranda',
                name: 'beranda',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: const BerandaScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/monitoring',
                name: 'monitoring',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: const MonitoringScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/riwayat',
                name: 'riwayat',
                pageBuilder: (context, state) {
                  // Get tab index from query parameter (default to 0)
                  final tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
                  return CustomTransitionPage(
                    child: RiwayatScreen(initialTabIndex: tabIndex),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                name: 'profil',
                pageBuilder: (context, state) {
                  return CustomTransitionPage(
                    child: const ProfilScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifikasi',
        name: 'notifikasi',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const NotificationScreen(),
        ),
      ),
    ],
  );
}