import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<void> execute({required String email}) async {
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email tidak valid');
    }

    return await repository.sendPasswordResetEmail(email: email);
  }
}
