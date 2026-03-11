import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/journal_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'tutorial_page.dart';
import 'utils/tutorial_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'TinyLines',
            theme: settings.themeData,
            debugShowCheckedModeBanner: false,
            home: const AuthGate(),
          );
        },
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
  Future<void>? _loadFuture;

  // Tracks whether the user has passed the PIN lock screen during this session
  // Resets to false when a different user signs in
  bool _passcodeUnlocked = false;

  static const _secureStorage = FlutterSecureStorage();

  Future<String?> _loadPin(String uid) async {
    return _secureStorage.read(key: 'settings_${uid}_app_passcode');
  }

  void _triggerSignedInLoad(BuildContext context, User user) {
    if (_lastUserId != user.uid) {
      _lastUserId = user.uid;
      _passcodeUnlocked = false; // require PIN to be entered again for a new user session
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final journalProvider = context.read<JournalProvider>();
        final settingsProvider = context.read<SettingsProvider>();
        journalProvider.resetForAuthChange();
        setState(() {
          _loadFuture = Future.wait([
            journalProvider.loadEntries(),
            settingsProvider.loadForUser(user.uid),
          ]);
        });
      });
    }
  }

  void _handleSignedOutUser(BuildContext context) {
    if (_lastUserId != null) {
      _lastUserId = null;
      context.read<JournalProvider>().resetForAuthChange();
      context.read<SettingsProvider>().resetForSignOut();
    }
  }

  Future<bool> _shouldShowTutorial() async {
    final seenTutorial = await TutorialHelper.hasSeenTutorial();
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

        _triggerSignedInLoad(context, user);

        return FutureBuilder<void>(
          future: _loadFuture,
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

            return FutureBuilder<(bool, String?)>(
              future: Future.wait([
                _shouldShowTutorial(),
                _loadPin(user.uid),
              ]).then((results) => (results[0] as bool, results[1] as String?)),
              builder: (context, startupSnapshot) {
                if (startupSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (startupSnapshot.hasError) {
                  return const HomeScreen();
                }

                final (showTutorial, storedPin) =
                    startupSnapshot.data ?? (false, null);

                // Show tutorial before anything else on first launch
                if (showTutorial) return const TutorialPage();

                // If a PIN is set and the user hasn't unlocked this session then show the lock screen
                final pinIsSet =
                    storedPin != null && storedPin.isNotEmpty;
                if (pinIsSet && !_passcodeUnlocked) {
                  return _PasscodeLockScreen(
                    correctPin: storedPin,
                    onUnlocked: () =>
                        setState(() => _passcodeUnlocked = true),
                  );
                }

                return const HomeScreen();
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

// PIN lock screen shown at app launch when the user has set a passcode

class _PasscodeLockScreen extends StatefulWidget {
  final String correctPin;
  final VoidCallback onUnlocked;

  const _PasscodeLockScreen({
    required this.correctPin,
    required this.onUnlocked,
  });

  @override
  State<_PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<_PasscodeLockScreen> {
  String _input = '';
  String? _error;

  void _onDigit(String d) {
    if (_input.length >= 4) return;
    setState(() {
      _input += d;
      _error = null;
    });
    if (_input.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _checkPin);
    }
  }

  void _checkPin() {
    if (_input == widget.correctPin) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Incorrect passcode. Try again.';
        _input = '';
      });
    }
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.lock_outline, color: Colors.white54, size: 40),
            const SizedBox(height: 20),
            const Text(
              'Enter Passcode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _input.length;
                return Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: filled ? Colors.white : Colors.white38,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Error message
            SizedBox(
              height: 24,
              child: _error != null
                  ? Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 32),

            // Number pad
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 72),
                        _buildDigitButton('0'),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: IconButton(
                            onPressed: _onDelete,
                            icon: const Icon(
                              Icons.backspace_outlined,
                              color: Colors.white54,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildDigitButton).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1E2A45),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}