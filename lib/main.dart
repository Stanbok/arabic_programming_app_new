import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'data/models/user_progress_model.dart';
import 'data/models/user_profile_model.dart';
import 'data/models/app_settings_model.dart';
import 'data/models/cached_lesson_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Lock orientation to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Firebase FIRST (before any Firebase services are used)
    await Firebase.initializeApp();

    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProgressModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserProfileModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CachedLessonModelAdapter());
    }

    // Open Hive boxes
    await Future.wait([
      Hive.openBox<UserProgressModel>(HiveBoxes.userProgress),
      Hive.openBox<UserProfileModel>(HiveBoxes.userProfile),
      Hive.openBox<AppSettingsModel>(HiveBoxes.appSettings),
      Hive.openBox<CachedLessonModel>(HiveBoxes.cachedLessons),
    ]);

    runApp(
      const ProviderScope(
        child: PythonInArabicApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Show error screen if initialization fails
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ أثناء تشغيل التطبيق',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
