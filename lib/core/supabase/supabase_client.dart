import 'package:supabase/supabase.dart';
import '../constants/supabase_constants.dart';

/// Singleton Supabase client manager
/// 
/// Replaces Supabase.instance from supabase_flutter package.
/// Initialize once in main.dart, then access via SupabaseClientManager.instance.client
class SupabaseClientManager {
  SupabaseClientManager._();
  static final SupabaseClientManager instance = SupabaseClientManager._();

  SupabaseClient? _client;

  /// Initialize the Supabase client
  /// Must be called once at app startup
  void initialize() {
    _client = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );
  }

  /// Get the Supabase client instance
  /// Throws if not initialized
  SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseClientManager not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if the client is initialized
  bool get isInitialized => _client != null;
}
