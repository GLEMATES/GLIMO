import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/google_signin_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../infrastructure/datasources/firebase_auth_datasource.dart';
import '../../infrastructure/repositories/auth_repository_impl.dart';
import 'motor_list_provider.dart';
import 'motor_details_provider.dart';
import 'trip_history_provider.dart';

import 'auth_state.dart';

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final datasource = ref.watch(firebaseAuthDatasourceProvider);
  return AuthRepositoryImpl(datasource);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

final googleSignInUseCaseProvider = Provider<GoogleSignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GoogleSignInUseCase(repository);
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordUseCase(repository);
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ChangePasswordUseCase(repository);
});

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final authStreamProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initializeAuth();
    return const AuthState.initial();
  }

  void _initializeAuth() {
    Future.microtask(() async {
      try {
        final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
        final user = await getCurrentUserUseCase.execute();

        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = const AuthState.unauthenticated();
        }
      } catch (e) {
        state = const AuthState.unauthenticated();
      }
    });
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      state = const AuthState.loading();

      final registerUseCase = ref.read(registerUseCaseProvider);
      final user = await registerUseCase.execute(
        fullName: fullName,
        email: email,
        password: password,
      );

      // Set flag that user has logged in before (persists even after logout)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasEverLoggedIn', true);

      ref.invalidate(tripHistoryProvider);

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = const AuthState.loading();

      final loginUseCase = ref.read(loginUseCaseProvider);
      final user = await loginUseCase.execute(
        email: email,
        password: password,
      );

      // Set flag that user has logged in before (persists even after logout)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasEverLoggedIn', true);

      ref.invalidate(tripHistoryProvider);

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AuthState.loading();

      final googleSignInUseCase = ref.read(googleSignInUseCaseProvider);
      final user = await googleSignInUseCase.execute();

      // Set flag that user has logged in before (persists even after logout)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasEverLoggedIn', true);

      ref.invalidate(tripHistoryProvider);

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      state = const AuthState.loading();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('motor_filled');

      await ref.read(motorListProvider.notifier).clearMotors();
      ref.read(motorDetailsProvider.notifier).clearAll();
      await ref.read(tripHistoryProvider.notifier).clearHistory();

      final logoutUseCase = ref.read(logoutUseCaseProvider);
      await logoutUseCase.execute();

      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      state = const AuthState.loading();

      final forgotPasswordUseCase = ref.read(forgotPasswordUseCaseProvider);
      await forgotPasswordUseCase.execute(email: email);

      state = const AuthState.initial();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      debugPrint('🔐 [PASSWORD DEBUG] Starting password change...');
      state = const AuthState.loading();

      final changePasswordUseCase = ref.read(changePasswordUseCaseProvider);
      await changePasswordUseCase.execute(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      debugPrint('🔐 [PASSWORD DEBUG] Password changed successfully in Firebase');

      // Keep user authenticated after password change
      final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
      final user = await getCurrentUserUseCase.execute();

      debugPrint('🔐 [PASSWORD DEBUG] Current user after password change: ${user?.email}');

      if (user != null) {
        state = AuthState.authenticated(user);
        debugPrint('🔐 [PASSWORD DEBUG] Auth state set to authenticated');
      } else {
        state = const AuthState.unauthenticated();
        debugPrint('🔐 [PASSWORD DEBUG] User is null, setting unauthenticated');
      }
    } catch (e) {
      debugPrint('🔐 [PASSWORD DEBUG] Error during password change: $e');
      state = AuthState.error(e.toString());
    }
  }
}