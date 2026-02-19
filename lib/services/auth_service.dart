abstract class AuthService {
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> signOut();

  bool get isSignedIn;
}
