import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/journal_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'tutorial_page.dart';
import 'utils/app_theme.dart';
import 'utils/tutorial_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService.instance.init();

  runApp(const TinyLinesApp());
}

class TinyLinesApp extends StatelessWidget {
  const TinyLinesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JournalProvider(),
      child: MaterialApp(
        title: 'TinyLines',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;

  Future<void> _handleSignedInUser(BuildContext context, User user) async {
    final provider = context.read<JournalProvider>();

    if (_lastUserId != user.uid) {
      _lastUserId = user.uid;
      provider.resetForAuthChange();
      await provider.loadEntries();
    }
  }

  void _handleSignedOutUser(BuildContext context) {
    if (_lastUserId != null) {
      _lastUserId = null;
      context.read<JournalProvider>().resetForAuthChange();
    }
  }

  Future<bool> _shouldShowTutorial(User user) async {
    final seenTutorial = await TutorialHelper.hasSeenTutorial(user.uid);
    return !seenTutorial;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleSignedOutUser(context);
            }
          });
          return const AuthScreen();
        }

        return FutureBuilder<void>(
          future: _handleSignedInUser(context, user),
          builder: (context, loadSnapshot) {
            if (loadSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (loadSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Failed to load journal entries.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return FutureBuilder<bool>(
              future: _shouldShowTutorial(user),
              builder: (context, tutorialSnapshot) {
                if (tutorialSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (tutorialSnapshot.hasError) {
                  return const HomeScreen();
                }

                final showTutorial = tutorialSnapshot.data ?? false;

                return showTutorial
                    ? const TutorialPage()
                    : const HomeScreen();
              },
            );
          },
        );
      },
    );
  }
}

// Optional: request notification permissions
Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }
}