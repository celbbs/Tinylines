abstract class AuthService {
  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> createAccount({
    required String email,
    required String password,
  });
}
