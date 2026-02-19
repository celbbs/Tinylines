import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    AuthService? authService,
  }) : _authService = authService;

  // If null, we default to FirebaseAuthService() so behavior stays the same.
  final AuthService? _authService;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isSignIn = true;
  bool _loading = false;
  String? _error;

  AuthService get _authService => widget._authService ?? FirebaseAuthService();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _email.text.trim();
      final password = _password.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _error = 'Email and password are required.';
        });
        return;
      }

      if (_isSignIn) {
        await _authService.signIn(email: email, password: password);
      } else {
        await _authService.createAccount(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      // Preserves your existing Firebase error behavior/messages.
      setState(() {
        _error = e.message ?? 'Authentication failed.';
      });
    } catch (_) {
      // Covers fake/mocked auth services that throw non-Firebase exceptions.
      setState(() {
        _error = 'Authentication failed.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TinyLines')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.spacingL),
            Text(
              _isSignIn ? 'Sign in' : 'Create account',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),

            TextField(
              key: const Key('auth_email_field'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              key: const Key('auth_password_field'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            const SizedBox(height: AppTheme.spacingM),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: AppTheme.spacingM),
            ElevatedButton(
              key: const Key('auth_sign_in_button'),
              onPressed: _loading ? null : _submit,
              child: Text(
                _loading
                    ? 'Please wait...'
                    : (_isSignIn ? 'Sign In' : 'Create Account'),
              ),
            ),

            TextButton(
              onPressed: _loading ? null : () => setState(() => _isSignIn = !_isSignIn),
              child: Text(
                _isSignIn
                    ? 'Need an account? Sign up'
                    : 'Already have an account? Sign in',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
