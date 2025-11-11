import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initialize() async {
    try {
      await _requestPermissions();
    } catch (e) {
      debugPrint(' ');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      } else {}
    } catch (e) {
      debugPrint(' ');
    }
  }

  Future<void> saveFCMToken(String userId) async {}

  Future<void> deleteFCMToken(String userId) async {}

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}
}
