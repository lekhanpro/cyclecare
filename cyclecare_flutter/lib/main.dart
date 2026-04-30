import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';
import 'data/database/app_database.dart';
import 'features/app/cyclecare_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppDatabase.instance.initialize();
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(
    const ProviderScope(
      child: CycleCareApp(),
    ),
  );
}
