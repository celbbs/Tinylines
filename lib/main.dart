import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/journal_provider.dart';
import 'screens/home_screen.dart';
import 'tutorial_page.dart';
import 'utils/app_theme.dart';
import 'utils/tutorial_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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

  // Check if tutorial was seen
  bool seenTutorial = await TutorialHelper.hasSeenTutorial();

  runApp(TinyLinesApp(showTutorial: !seenTutorial));
}

class TinyLinesApp extends StatelessWidget {
  final bool showTutorial;
  const TinyLinesApp({super.key, required this.showTutorial});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JournalProvider(),
      child: MaterialApp(
        title: 'TinyLines',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: showTutorial ? const TutorialPage() : const HomeScreen(),
      ),
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