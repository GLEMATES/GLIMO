import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<UserEntity> execute({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (fullName.isEmpty) {
      throw Exception('Nama lengkap tidak boleh kosong');
    }

    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email tidak valid');
    }

    if (password.length < 8) {
      throw Exception('Password minimal 8 karakter');
    }

    return await repository.register(
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}