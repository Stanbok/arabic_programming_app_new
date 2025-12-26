import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'core/constants/supabase_constants.dart';
import 'data/models/user_progress_model.dart';
import 'data/models/user_profile_model.dart';
import 'data/models/app_settings_model.dart';
import 'data/models/cached_lesson_model.dart';
import 'data/models/manifest/cached_manifest_model.dart';
import 'data/models/manifest/update_check_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserProgressModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());
  Hive.registerAdapter(AppSettingsModelAdapter());
  Hive.registerAdapter(CachedLessonModelAdapter());
  Hive.registerAdapter(CachedManifestModelAdapter());
  Hive.registerAdapter(UpdateCheckModelAdapter());

  // Open Hive boxes
  await Future.wait([
    Hive.openBox<UserProgressModel>(HiveBoxes.userProgress),
    Hive.openBox<UserProfileModel>(HiveBoxes.userProfile),
    Hive.openBox<AppSettingsModel>(HiveBoxes.appSettings),
    Hive.openBox<CachedLessonModel>(HiveBoxes.cachedLessons),
    Hive.openBox<CachedManifestModel>(HiveBoxes.cachedManifests),
    Hive.openBox<UpdateCheckModel>(HiveBoxes.updateCheck),
  ]);

  runApp(
    const ProviderScope(
      child: PythonInArabicApp(),
    ),
  );
}
