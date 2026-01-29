import 'auth_service.dart';

class FakeAuthService implements AuthService {
  bool _signedIn = false;

  @override
  bool get isSignedIn => _signedIn;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final e = email.trim();
    final p = password.trim();

    if (e.isEmpty || p.isEmpty) {
      throw Exception("Email and password are required.");
    }
    if (!e.contains("@")) {
      throw Exception("Please enter a valid email address.");
    }

    _signedIn = true;
  }

  @override
  Future<void> register({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final e = email.trim();
    final p = password.trim();

    if (e.isEmpty || p.isEmpty) {
      throw Exception("Email and password are required.");
    }
    if (!e.contains("@")) {
      throw Exception("Please enter a valid email address.");
    }
    if (p.length < 6) {
      throw Exception("Password must be at least 6 characters.");
    }

    _signedIn = true;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _signedIn = false;
  }
}
