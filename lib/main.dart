import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'data/models/user_progress_model.dart';
import 'data/models/user_profile_model.dart';
import 'data/models/app_settings_model.dart';
import 'data/models/cached_lesson_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserProgressModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());
  Hive.registerAdapter(AppSettingsModelAdapter());
  Hive.registerAdapter(CachedLessonModelAdapter());

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
}
