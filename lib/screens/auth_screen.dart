import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _isSignIn = true;
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
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
      final name = _name.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _error = 'Email and password are required.';
        });
        return;
      }

      if (!_isSignIn && name.isEmpty) {
        setState(() {
          _error = 'Please enter your name.';
        });
        return;
      }

      if (_isSignIn) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.updateDisplayName(name);
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
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TinyLines'),
      ),
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

            if (!_isSignIn) ...[
              TextField(
                controller: _name,
                keyboardType: TextInputType.name,
                autocorrect: false,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],

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
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                  },
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
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
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _isSignIn = !_isSignIn;
                        _error = null;
                      }),
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