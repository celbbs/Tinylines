import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/journal_provider.dart';
import 'screens/auth_screen.dart';
import 'utils/app_theme.dart';
import 'services/auth_service.dart';
import 'services/fake_auth_service.dart';

void main() {
  runApp(const TinyLinesApp());
}

class TinyLinesApp extends StatelessWidget {
  const TinyLinesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        Provider<AuthService>(create: (_) => FakeAuthService()),
      ],
      child: MaterialApp(
        title: 'TinyLines',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthScreen(),
      ),
    );
  }
}