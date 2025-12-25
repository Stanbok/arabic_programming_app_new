import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';

/// Singleton service for Supabase client management
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  SupabaseClient? _client;

  /// Get the Supabase client
  SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw StateError('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Initialize Supabase
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (SupabaseConstants.supabaseAnonKey.isEmpty) {
        debugPrint('Supabase initialization warning: SUPABASE_ANON_KEY is empty');
      }

      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );

      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _client?.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Auth state changes stream
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// Get Supabase client for direct access
  static SupabaseClient get clientInstance => Supabase.instance.client;
}
