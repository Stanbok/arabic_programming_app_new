import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'models/lesson_model.dart';
import 'models/path_model.dart';
import 'models/progress_model.dart';
import 'models/card_model.dart';
import 'models/quiz_result_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (portrait only for kids)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  _registerHiveAdapters();
  
  await _openHiveBoxes();
  
  runApp(
    const ProviderScope(
      child: ArabicPythonApp(),
    ),
  );
}

void _registerHiveAdapters() {
  // Core models
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(LessonModelAdapter());
  Hive.registerAdapter(PathModelAdapter());
  Hive.registerAdapter(LessonProgressAdapter());
  
  // Card models from card_model.dart (typeId: 5 and 6)
  Hive.registerAdapter(LessonCardAdapter());
  Hive.registerAdapter(QuizQuestionAdapter());
  
  // Quiz result models
  Hive.registerAdapter(QuizResultModelAdapter());
  Hive.registerAdapter(QuestionResultAdapter());
}

Future<void> _openHiveBoxes() async {
  await Hive.openBox<UserModel>(HiveBoxes.user);
  await Hive.openBox<LessonModel>(HiveBoxes.cachedLessons);
  await Hive.openBox<LessonCard>(HiveBoxes.lessonCards);
  await Hive.openBox<LessonProgress>(HiveBoxes.progress);
  await Hive.openBox(HiveBoxes.settings);
  await Hive.openBox(HiveBoxes.cachedImages);
}
