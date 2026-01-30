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
    // Android setup
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Apple setup
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combine 
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

  Future<String?> getDeviceToken() async {
    if (!kIsWeb && !Platform.isMacOS) {
      return FirebaseMessaging.instance.getToken();
    }
    return null;
  }
}
