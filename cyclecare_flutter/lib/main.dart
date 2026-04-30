import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';
import 'data/database/app_database.dart';
import 'features/app/cyclecare_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  try {
    await AppDatabase.instance.initialize();
  } catch (e) {
    print('Database initialization failed: $e');
  }
  
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    print('Notification service initialization failed: $e');
  }
  
  runApp(
    const ProviderScope(
      child: CycleCareApp(),
    ),
  );
}
