import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../calls/data/call_local_store.dart';
import '../../services/api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may not be configured yet in local/dev env.
  }

  final callIdRaw = message.data['call_id'];
  final callId = int.tryParse('${callIdRaw ?? ''}');
  if (callId != null && callId > 0) {
    await CallLocalStore().saveActiveCallId(callId);
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final CallLocalStore _store = CallLocalStore();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase config not ready; keep app running without push.
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handlePayload(details.payload);
      },
    );

    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (ApiService.token == null) return;
      try {
        await ApiService.updateFcmToken(token);
      } catch (_) {
        // Ignore token refresh sync errors.
      }
    });

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      final callIdRaw = message.data['call_id'];
      final callId = int.tryParse('${callIdRaw ?? ''}');
      if (callId != null && callId > 0) {
        await _store.saveActiveCallId(callId);
      }

      await _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'calls_channel',
            'Call Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _routeFromData(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _routeFromData(initialMessage.data);
    }

    _initialized = true;
  }

  Future<void> syncFcmTokenWithBackend() async {
    if (!_initialized || ApiService.token == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await ApiService.updateFcmToken(token);
    } catch (_) {
      // Ignore sync errors; app should keep working without blocking login.
    }
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final parsed = jsonDecode(payload);
      if (parsed is Map<String, dynamic>) {
        _routeFromData(parsed);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _routeFromData(Map<String, dynamic> data) async {
    final callIdRaw = data['call_id'];
    if (callIdRaw == null) return;

    final callId = int.tryParse(callIdRaw.toString());
    if (callId == null) return;

    await _store.saveActiveCallId(callId);

    final type = (data['type'] ?? '').toString();
    final action = (data['action'] ?? '').toString();
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'waiting_promoted' || action == 'EMERGENCY_PROMOTION') {
      navigator.pushNamed('/call-tracking', arguments: {'callId': callId});
      return;
    }

    navigator.pushNamed('/call-details', arguments: {'callId': callId});
  }
}
