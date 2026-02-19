import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/journal_provider.dart';
import '../screens/home_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Run once per auth state change (not every rebuild)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final provider = Provider.of<JournalProvider>(context, listen: false);
          provider.resetForAuthChange();
          if (FirebaseAuth.instance.currentUser != null) {
            provider.loadEntries();
          }
        });

        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const SignInScreen();
      },
    );
  }
}
