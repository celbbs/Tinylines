import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../utils/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    AuthService? authService,
  }) : _authService = authService;

  final AuthService? _authService;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

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
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email and password are required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignIn) {
        await _authService.signIn(email: email, password: password);
      } else {
        await _authService.createAccount(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Authentication failed.';
      });
    } catch (_) {
      setState(() {
        _error = 'Authentication failed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TinyLines'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingL),
              Text(
                _isSignIn ? 'Sign In' : 'Create Account',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                _isSignIn
                    ? 'Sign in to access your journal entries.'
                    : 'Create an account to save journal entries to your profile.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextField(
                key: const Key('auth_email_field'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                key: const Key('auth_password_field'),
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                key: const Key('auth_submit_button'),
                onPressed: _loading ? null : _submit,
                child: Text(
                  _loading
                      ? 'Please wait...'
                      : (_isSignIn ? 'Sign In' : 'Create Account'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              TextButton(
                onPressed: _loading ? null : _toggleMode,
                child: Text(
                  _isSignIn
                      ? 'Need an account? Sign up'
                      : 'Already have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}