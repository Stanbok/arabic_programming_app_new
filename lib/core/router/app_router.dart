import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/features_screen.dart';
import '../../features/onboarding/screens/personalize_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/lessons/screens/main_screen.dart';
import '../../features/lessons/screens/lesson_viewer_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/common/screens/no_internet_screen.dart';
import '../../features/quiz/screens/quiz_results_screen.dart';
import '../../features/celebration/screens/path_completion_screen.dart';
import '../../models/quiz_result_model.dart';
import '../../models/path_model.dart';
import '../constants/route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      
      // Onboarding Features
      GoRoute(
        path: RouteNames.onboardingFeatures,
        name: RouteNames.onboardingFeatures,
        pageBuilder: (context, state) => _slideTransition(state, const FeaturesScreen()),
      ),
      
      // Onboarding Personalize
      GoRoute(
        path: RouteNames.onboardingPersonalize,
        name: RouteNames.onboardingPersonalize,
        pageBuilder: (context, state) => _slideTransition(state, const PersonalizeScreen()),
      ),
      
      // Onboarding Welcome
      GoRoute(
        path: RouteNames.onboardingWelcome,
        name: RouteNames.onboardingWelcome,
        pageBuilder: (context, state) => _slideTransition(state, const WelcomeScreen()),
      ),
      
      GoRoute(
        path: RouteNames.main,
        name: RouteNames.main,
        pageBuilder: (context, state) => _slideTransition(state, const MainScreen()),
      ),
      
      // Lesson Viewer
      GoRoute(
        path: RouteNames.lessonViewer,
        name: RouteNames.lessonViewer,
        pageBuilder: (context, state) {
          final lessonId = state.extra as String? ?? '';
          return _slideTransition(
            state,
            LessonViewerScreen(lessonId: lessonId),
          );
        },
      ),
      
      // Settings
      GoRoute(
        path: RouteNames.settings,
        name: RouteNames.settings,
        pageBuilder: (context, state) => _slideTransition(state, const SettingsScreen()),
      ),
      
      // Premium
      GoRoute(
        path: RouteNames.premium,
        name: RouteNames.premium,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PremiumScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      
      // No Internet
      GoRoute(
        path: RouteNames.noInternet,
        name: RouteNames.noInternet,
        pageBuilder: (context, state) => _slideTransition(state, const NoInternetScreen()),
      ),
      
      // Quiz Results
      GoRoute(
        path: RouteNames.results,
        name: RouteNames.results,
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final result = extras['result'] as QuizResultModel;
          final lessonTitle = extras['lessonTitle'] as String? ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: QuizResultsScreen(
              result: result,
              lessonTitle: lessonTitle,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      
      GoRoute(
        path: RouteNames.pathCompletion,
        name: RouteNames.pathCompletion,
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final path = extras['path'] as PathModel;
          final totalLessons = extras['totalLessons'] as int? ?? 0;
          final totalXpEarned = extras['totalXpEarned'] as int? ?? 0;
          final hasNextPath = extras['hasNextPath'] as bool? ?? true;
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: PathCompletionScreen(
              path: path,
              totalLessons: totalLessons,
              totalXpEarned: totalXpEarned,
              hasNextPath: hasNextPath,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Scale and fade in for celebration effect
              return ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
  );
});

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // RTL slide (from left for Arabic)
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}
