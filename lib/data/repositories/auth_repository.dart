import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/hive_boxes.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_service.dart';

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult({
    required this.success,
    this.error,
    this.user,
  });
}

/// Repository for authentication operations using Supabase
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
  );

  Box<UserProfileModel>? _profileBox;

  Box<UserProfileModel> get _box {
    _profileBox ??= Hive.box<UserProfileModel>(HiveBoxes.userProfile);
    return _profileBox!;
  }

  SupabaseClient get _supabase => SupabaseService.clientInstance;

  /// Get current Supabase user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Check if user is anonymous
  bool get isAnonymous {
    final user = currentUser;
    if (user == null) return true;
    // Supabase anonymous users have no email and no identities
    return user.email == null && (user.identities?.isEmpty ?? true);
  }

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      if (response.user != null) {
        return AuthResult(success: true, user: response.user);
      }
      return const AuthResult(success: false, error: 'فشل في إنشاء حساب مجهول');
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Link anonymous account with Google
  Future<AuthResult> linkWithGoogle() async {
    try {
      // Trigger Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult(success: false, error: 'تم إلغاء تسجيل الدخول');
      }

      // Get auth details
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return const AuthResult(success: false, error: 'فشل في الحصول على رمز المصادقة');
      }

      // Link with Supabase using Google OAuth
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // Update local profile
        final profile = _box.get(HiveKeys.profile) ?? UserProfileModel();
        final updated = profile.copyWith(
          isLinked: true,
          email: response.user!.email,
          supabaseUid: response.user!.id,
        );
        await _box.put(HiveKeys.profile, updated);

        return AuthResult(success: true, user: response.user);
      }

      return const AuthResult(success: false, error: 'فشل في ربط الحساب');
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return const AuthResult(
          success: false,
          error: 'هذا الحساب مرتبط بمستخدم آخر',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign in with Google (for already linked accounts)
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult(success: false, error: 'تم إلغاء تسجيل الدخول');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return const AuthResult(success: false, error: 'فشل في الحصول على رمز المصادقة');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // Update local profile
        final profile = _box.get(HiveKeys.profile) ?? UserProfileModel();
        final updated = profile.copyWith(
          isLinked: true,
          email: response.user!.email,
          supabaseUid: response.user!.id,
        );
        await _box.put(HiveKeys.profile, updated);

        return AuthResult(success: true, user: response.user);
      }

      return const AuthResult(success: false, error: 'فشل في تسجيل الدخول');
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();

    // Update local profile
    final profile = _box.get(HiveKeys.profile);
    if (profile != null) {
      final updated = profile.copyWith(
        isLinked: false,
        email: null,
        supabaseUid: null,
      );
      await _box.put(HiveKeys.profile, updated);
    }
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      // Delete user data from Supabase first
      final userId = currentUser?.id;
      if (userId != null) {
        // Delete profile and progress (cascade will handle related data)
        await _supabase.from('profiles').delete().eq('id', userId);
        await _supabase.from('user_progress').delete().eq('user_id', userId);
      }

      // Sign out
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();

      // Clear local profile
      await _box.delete(HiveKeys.profile);

      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
