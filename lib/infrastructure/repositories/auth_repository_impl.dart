import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final userModel = await datasource.register(
      fullName: fullName,
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final userModel = await datasource.login(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final userModel = await datasource.signInWithGoogle();
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await datasource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userModel = await datasource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return datasource.authStateChanges().map(
          (userModel) => userModel?.toEntity(),
        );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await datasource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await datasource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> resendVerificationEmail() async {
    await datasource.resendVerificationEmail();
  }

  @override
  Future<bool> checkEmailVerified() async {
    return await datasource.checkEmailVerified();
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    return await datasource.getCurrentUserEmail();
  }
}