/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Python بالعربي';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.example.python_in_arabic';

  // Timing
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Content
  static const String path1Id = 'path_1';
  static const int quizPassThreshold = 50; // 50% to pass

  // These are used as fallback when no manifest cache exists
  static const String pathsJsonPath = 'assets/data/paths.json';
  static const String lessonsJsonPath = 'assets/data/lessons.json';
  static const String path1ContentPath = 'assets/data/path_1_content';

  /// Minimum interval between update checks (1 day)
  static const Duration updateCheckInterval = Duration(days: 1);
  
  /// Timeout for manifest downloads
  static const Duration manifestDownloadTimeout = Duration(seconds: 30);
  
  /// Timeout for lesson content downloads
  static const Duration lessonDownloadTimeout = Duration(seconds: 60);

  // Avatar count
  static const int avatarCount = 10;
}
