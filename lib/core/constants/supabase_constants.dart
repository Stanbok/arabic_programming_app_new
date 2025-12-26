/// Supabase configuration constants
/// 
/// IMPORTANT: Firebase Auth remains isolated.
/// Supabase is used ONLY for:
/// - Content metadata (manifests)
/// - User progress sync
/// - Hosting JSON files (Supabase Storage)
/// 
/// Supabase Auth MUST NOT be used.
class SupabaseConstants {
  SupabaseConstants._();

  /// Supabase project URL
  static const String supabaseUrl = 'https://jnimcsiushnsonyvfrtt.supabase.co';

  /// Supabase anon key (public, safe to include in client)
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpuaW1jc2l1c2huc29ueXZmcnR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3MTA5MzMsImV4cCI6MjA4MjI4NjkzM30.r-neavwKe_tP2dm1d2ShMmSapOgRwY-_jJpbqTIMCpM';

  /// Storage bucket for content manifests and lessons
  static const String contentBucket = 'content';

  /// Table names
  static const String userProgressTable = 'user_progress';
  static const String userProfilesTable = 'user_profiles';

  /// Base storage URL for public files
  static String get storageBaseUrl => 
      '$supabaseUrl/storage/v1/object/public/$contentBucket';

  /// Storage paths
  static const String globalManifestPath = 'manifests/global_manifest.json';
  
  /// Get full public URL for global manifest
  static String get globalManifestUrl => 
      '$storageBaseUrl/$globalManifestPath';
  
  /// Get path manifest storage path
  static String pathManifestPath(String pathId) => 
      'manifests/paths/$pathId/manifest.json';
  
  /// Get full public URL for path manifest
  static String pathManifestUrl(String pathId) => 
      '$storageBaseUrl/${pathManifestPath(pathId)}';
  
  /// Get module lessons storage path
  static String moduleLessonsPath(String pathId, String moduleId) => 
      'manifests/paths/$pathId/modules/$moduleId/lessons.json';
  
  /// Get full public URL for module lessons
  static String moduleLessonsUrl(String pathId, String moduleId) => 
      '$storageBaseUrl/${moduleLessonsPath(pathId, moduleId)}';
  
  /// Get lesson content storage path
  static String lessonContentPath(String pathId, String moduleId, String lessonId) => 
      'content/paths/$pathId/modules/$moduleId/lessons/$lessonId.json';
  
  /// Get full public URL for lesson content
  static String lessonContentUrl(String pathId, String moduleId, String lessonId) => 
      '$storageBaseUrl/${lessonContentPath(pathId, moduleId, lessonId)}';
}
