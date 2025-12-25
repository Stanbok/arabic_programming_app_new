/// Supabase configuration constants
class SupabaseConstants {
  SupabaseConstants._();

  // These values are loaded from environment variables
  // Set via --dart-define or .env file
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://akayeovizwifucvohtrx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Table names
  static const String profilesTable = 'profiles';
  static const String userProgressTable = 'user_progress';
  static const String pathsTable = 'paths';
  static const String lessonsTable = 'lessons';
  static const String lessonContentTable = 'lesson_content';
  static const String appMetadataTable = 'app_metadata';

  // Storage buckets
  static const String lessonsBucket = 'lessons';
}
