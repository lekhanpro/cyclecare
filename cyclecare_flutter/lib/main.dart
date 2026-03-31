import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/utils/notification_helper.dart';
import 'data/database/app_database.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for notifications
  tz.initializeTimeZones();

  // Initialize database (must happen before runApp)
  await AppDatabase.instance.initialize();

  // Initialize notifications (not on web) - wrapped in try/catch
  // so a failure doesn't block the entire app
  if (!kIsWeb) {
    try {
      await NotificationHelper.initialize();
    } catch (_) {
      // Notification init can fail on some devices - app still works
    }
  }

  // Set preferred orientations (not on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(
    const ProviderScope(
      child: CycleCareApp(),
    ),
  );
}
