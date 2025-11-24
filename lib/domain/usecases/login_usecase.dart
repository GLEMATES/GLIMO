import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> execute({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email tidak valid');
    }

    if (password.isEmpty) {
      throw Exception('Password tidak boleh kosong');
    }

    return await repository.login(
      email: email,
      password: password,
    );
  }
}