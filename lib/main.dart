import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/services/notification_service.dart';
import 'features/app/cyclecare_app.dart';
import 'firebase_options.dart';

// ── Background FCM handler — must be top-level ────────────────────────────────
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM shows the notification automatically in background/terminated state
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Timezone data for local notifications
  tz.initializeTimeZones();

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Firebase + FCM ────────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Request permission (Android 13+ / iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Get + save FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }

    // Refresh token listener
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveFcmToken);

    // Foreground messages → show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        NotificationService().showInstantNotification(
          title: n.title ?? 'CycleCare',
          body: n.body ?? '',
        );
      }
    });

    // App opened from notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.data}');
      // TODO: navigate based on message.data['route'] when deep linking is added
    });

    // Check if app was launched from a terminated-state notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('Launched from notification: ${initial.data}');
    }
  } catch (e) {
    // Firebase unavailable — app works in local-only mode
    debugPrint('Firebase init error: $e');
  }

  // ── Local notifications ───────────────────────────────────────────────────
  try {
    await NotificationService().initialize();
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: CycleCareApp(),
    ),
  );
}

/// Persist FCM token locally so it can be synced to Supabase when signed in
Future<void> _saveFcmToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cc.fcm_token', token);
    debugPrint('FCM token: ${token.substring(0, 20)}...');
  } catch (_) {}
}
