import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/lessons/screens/lessons_screen.dart';
import '../../features/lesson_viewer/screens/lesson_viewer_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/carousel_screen.dart';
import '../../features/onboarding/screens/personalization_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../data/models/path_model.dart';
import '../../data/models/lesson_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String carousel = '/carousel';
  static const String personalization = '/personalization';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String lessons = '/lessons';
  static const String lessonViewer = '/lesson-viewer';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String premium = '/premium';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fadeRoute(const SplashScreen());

      case AppRoutes.carousel:
        return _slideRoute(const CarouselScreen());

      case AppRoutes.personalization:
        return _slideRoute(const PersonalizationScreen());

      case AppRoutes.welcome:
        return _slideRoute(const WelcomeScreen());

      case AppRoutes.home:
        return _fadeRoute(const HomeScreen());

      case AppRoutes.lessons:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(
          LessonsScreen(path: args['path'] as PathModel),
        );

      case AppRoutes.lessonViewer:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(
          LessonViewerScreen(
            lesson: args['lesson'] as LessonModel,
            pathId: args['pathId'] as String,
          ),
        );

      case AppRoutes.profile:
        return _slideRoute(const ProfileScreen());

      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen());

      case AppRoutes.premium:
        return _slideRoute(const PremiumScreen());

      default:
        return _fadeRoute(const SplashScreen());
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        // RTL-aware slide transition (from left in RTL)
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
