import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../models/user_profile_model.dart';

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

/// Repository for authentication operations
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Box<UserProfileModel>? _profileBox;

  Box<UserProfileModel> get _box {
    _profileBox ??= Hive.box<UserProfileModel>(HiveBoxes.userProfile);
    return _profileBox!;
  }

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Check if user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return AuthResult(success: true, user: credential.user);
    } on FirebaseAuthException catch (e) {
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
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link with current anonymous account
      final userCredential = await currentUser?.linkWithCredential(credential);
      
      if (userCredential?.user != null) {
        // Update local profile
        final profile = _box.get(HiveKeys.profile) ?? UserProfileModel();
        final updated = profile.copyWith(
          isLinked: true,
          email: userCredential!.user!.email,
          firebaseUid: userCredential.user!.uid,
        );
        await _box.put(HiveKeys.profile, updated);

        return AuthResult(success: true, user: userCredential.user);
      }

      return const AuthResult(success: false, error: 'فشل في ربط الحساب');
    } on FirebaseAuthException catch (e) {
      // Handle specific error cases
      if (e.code == 'credential-already-in-use') {
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
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Update local profile
        final profile = _box.get(HiveKeys.profile) ?? UserProfileModel();
        final updated = profile.copyWith(
          isLinked: true,
          email: userCredential.user!.email,
          firebaseUid: userCredential.user!.uid,
        );
        await _box.put(HiveKeys.profile, updated);

        return AuthResult(success: true, user: userCredential.user);
      }

      return const AuthResult(success: false, error: 'فشل في تسجيل الدخول');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    
    // Update local profile
    final profile = _box.get(HiveKeys.profile);
    if (profile != null) {
      final updated = profile.copyWith(
        isLinked: false,
        email: null,
        firebaseUid: null,
      );
      await _box.put(HiveKeys.profile, updated);
    }
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      await currentUser?.delete();
      await _googleSignIn.signOut();
      
      // Clear local profile
      await _box.delete(HiveKeys.profile);
      
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const AuthResult(
          success: false,
          error: 'يرجى تسجيل الخروج وإعادة تسجيل الدخول للمتابعة',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
