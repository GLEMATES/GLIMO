import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> signInWithGoogle();

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Stream<UserEntity?> authStateChanges();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> resendVerificationEmail();

  Future<bool> checkEmailVerified();

  Future<String?> getCurrentUserEmail();
}