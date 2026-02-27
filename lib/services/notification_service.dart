import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // android
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // apple setup
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // both 
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);

    // Firebase on not mac os only
    if (!kIsWeb && !Platform.isMacOS) {
      // Request permission for iOS
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // Handle taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification tapped: ${message.data}');
      });
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.max,
      priority: Priority.high,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }
  // schedule a daily reminder at a specific time
Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
  const androidDetails = AndroidNotificationDetails(
    'daily_reminder',
    'Daily Journal Reminder',
    importance: Importance.high,
    priority: Priority.high,
  );

  const darwinDetails = DarwinNotificationDetails();

  const platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );

  await flutterLocalNotificationsPlugin.periodicallyShow(
    0, // notification ID
    'Time to journal ✏️',
    'Take a moment to write your daily entry.',
    RepeatInterval.daily,
    platformDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

// Cancel the daily reminder
Future<void> cancelDailyReminder() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}

  Future<String?> getDeviceToken() async {
    if (!kIsWeb && !Platform.isMacOS) {
      return FirebaseMessaging.instance.getToken();
    }
    return null;
  }
}
