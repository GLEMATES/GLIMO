import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<void> execute({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      throw Exception('Password lama tidak boleh kosong');
    }

    if (newPassword.isEmpty) {
      throw Exception('Password baru tidak boleh kosong');
    }

    if (newPassword.length < 8) {
      throw Exception('Password minimal 8 karakter');
    }

    if (newPassword != confirmPassword) {
      throw Exception('Password baru tidak sama');
    }

    if (currentPassword == newPassword) {
      throw Exception('Password baru harus berbeda dari password lama');
    }

    return await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
