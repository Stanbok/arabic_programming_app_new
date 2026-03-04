import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/unit/presentation/unit_screen.dart';
import 'features/unit/presentation/lesson_screen.dart';
import 'features/quiz/presentation/quiz_screen.dart';

void main() {
  runApp(const ProviderScope(child: PythonLearningApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/unit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UnitScreen(unitId: id);
      },
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LessonScreen(lessonId: id);
      },
    ),
    GoRoute(
      path: '/quiz/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return QuizScreen(lessonId: id);
      },
    ),
  ],
);

class PythonLearningApp extends StatelessWidget {
  const PythonLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Learn Python',
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
