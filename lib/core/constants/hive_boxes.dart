/// Hive box names
class HiveBoxes {
  HiveBoxes._();

  static const String userProgress = 'user_progress';
  static const String userProfile = 'user_profile';
  static const String appSettings = 'app_settings';
  static const String cachedLessons = 'cached_lessons';
  
  static const String cachedManifests = 'cached_manifests';
  static const String updateCheck = 'update_check';
}

/// Hive keys for single-value boxes
class HiveKeys {
  HiveKeys._();

  static const String progress = 'progress';
  static const String profile = 'profile';
  static const String settings = 'settings';
  
  static const String globalManifest = 'global_manifest';
  static const String lastUpdateCheck = 'last_update_check';
}

/// Manifest cache key generators
class ManifestKeys {
  ManifestKeys._();

  /// Key for path manifest: "path_{pathId}"
  static String pathManifest(String pathId) => 'path_$pathId';

  /// Key for module lessons: "module_{moduleId}"
  static String moduleLessons(String moduleId) => 'module_$moduleId';
}
