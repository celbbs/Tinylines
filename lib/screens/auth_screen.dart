import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isBusy = false;
  String? _error;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _cardController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();

      if (_isLogin) {
        await auth.signIn(email: email, password: password);
      } else {
        await auth.register(email: email, password: password);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        // Keeps the same vibe — animated warm gradient.
        final colorTween = TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(
              begin: const Color(0xFFFFD1A4),
              end: const Color(0xFFFF9A9E),
            ),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: ColorTween(
              begin: const Color(0xFFFF9A9E),
              end: const Color(0xFF9E6FFF),
            ),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: ColorTween(
              begin: const Color(0xFF9E6FFF),
              end: const Color(0xFFFFD1A4),
            ),
            weight: 1,
          ),
        ]);

        final color1 =
            colorTween.evaluate(AlwaysStoppedAnimation(_bgController.value))!;
        final color2 = colorTween.evaluate(
          AlwaysStoppedAnimation((_bgController.value + 0.5) % 1.0),
        )!;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color1, color2],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    const Icon(
                      Icons.edit_note_rounded,
                      size: 88,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      "TinyLines",
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "A calm, lightweight journal.\nOne small line a day.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const _FeatureRow(
                      icon: Icons.lock_outline,
                      text: "Private, personal journaling",
                    ),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                      icon: Icons.calendar_today_outlined,
                      text: "Daily entries with calendar view",
                    ),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                      icon: Icons.favorite_border,
                      text: "Build a gentle daily habit",
                    ),

                    const SizedBox(height: 32),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 26,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isLogin ? "Sign In" : "Create Account",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A148C),
                                ),
                              ),

                              const SizedBox(height: 18),

                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "Email",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                ),
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 22),

                              ElevatedButton(
                                onPressed: _isBusy ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B1FA2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 64,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 6,
                                ),
                                child: Text(
                                  _isBusy
                                      ? "Please wait..."
                                      : (_isLogin
                                          ? "Sign In"
                                          : "Create Account"),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),

                              const SizedBox(height: 14),

                              TextButton(
                                onPressed: _isBusy
                                    ? null
                                    : () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                          _error = null;
                                        });
                                      },
                                child: Text(
                                  _isLogin
                                      ? "Need an account? Register"
                                      : "Already have an account? Sign In",
                                  style: const TextStyle(
                                    color: Color(0xFF4A148C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                "Auth is stubbed for now.\nFirebase can be plugged in later without changing this UI.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
