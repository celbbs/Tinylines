import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

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
  bool _obscure = true;

  late final AnimationController _bgController;
  late final AnimationController _cardController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));

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
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        // Subtle animated gradient shift (professional, not loud).
        final t = _bgController.value;
        final a = Color.lerp(const Color(0xFF0B1026), const Color(0xFF1B1145), t)!;
        final b = Color.lerp(const Color(0xFF20104A), const Color(0xFF0E2A53), (t + 0.35) % 1.0)!;
        final c = Color.lerp(const Color(0xFF0E2A53), const Color(0xFF0B1026), (t + 0.7) % 1.0)!;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [a, b, c],
                  ),
                ),
              ),

              // Blurred blobs (glassmorphism)
              _BlobLight(
                alignment: const Alignment(-0.85, -0.75),
                diameter: size.width * 0.95,
                color: const Color(0xFF8A5CFF).withOpacity(0.35),
              ),
              _BlobLight(
                alignment: const Alignment(0.95, -0.35),
                diameter: size.width * 0.8,
                color: const Color(0xFFFF6FAE).withOpacity(0.28),
              ),
              _BlobLight(
                alignment: const Alignment(0.25, 1.05),
                diameter: size.width * 1.15,
                color: const Color(0xFF3EE6FF).withOpacity(0.18),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          _AppMark(),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TinyLines',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'A tiny journal, done daily.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // Big headline
                      const Text(
                        'Write one line.\nKeep the streak.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Fast, private journaling that feels effortless.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Glass card
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SegmentedToggle(
                                  left: 'Sign in',
                                  right: 'Register',
                                  isLeftSelected: _isLogin,
                                  onChanged: (isLeft) {
                                    setState(() {
                                      _isLogin = isLeft;
                                      _error = null;
                                    });
                                  },
                                ),

                                const SizedBox(height: 18),

                                _Field(
                                  controller: _emailController,
                                  hintText: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  leading: Icons.alternate_email_rounded,
                                ),
                                const SizedBox(height: 12),

                                _Field(
                                  controller: _passwordController,
                                  hintText: 'Password',
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  leading: Icons.lock_rounded,
                                  trailing: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  onSubmitted: (_) => _isBusy ? null : _submit(),
                                ),

                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB4B4),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                _PrimaryButton(
                                  text: _isBusy
                                      ? 'Please wait...'
                                      : (_isLogin ? 'Continue' : 'Create account'),
                                  onPressed: _isBusy ? null : _submit,
                                ),

                                const SizedBox(height: 12),

                                const Text(
                                  'Auth is scaffolded for now.\nFirebase can be plugged in later with no UI changes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Footer microcopy
                      const Center(
                        child: Text(
                          'By continuing, you agree to keep your journal secure.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A5CFF), Color(0xFFFF6FAE)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.edit_note_rounded, color: Colors.white),
    );
  }
}

class _BlobLight extends StatelessWidget {
  final Alignment alignment;
  final double diameter;
  final Color color;

  const _BlobLight({
    required this.alignment,
    required this.diameter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          height: diameter,
          width: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final String left;
  final String right;
  final bool isLeftSelected;
  final ValueChanged<bool> onChanged;

  const _SegmentedToggle({
    required this.left,
    required this.right,
    required this.isLeftSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              text: left,
              selected: isLeftSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              text: right,
              selected: !isLeftSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final IconData? leading;
  final Widget? trailing;
  final void Function(String)? onSubmitted;

  const _Field({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.leading,
    this.trailing,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600),
          prefixIcon: leading == null
              ? null
              : Icon(leading, color: Colors.white70),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8A5CFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          shadowColor: Colors.black.withOpacity(0.35),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
    );
  }
}
