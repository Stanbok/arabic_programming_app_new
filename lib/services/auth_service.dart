import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../core/constants/hive_boxes.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously on first app launch
  Future<UserModel?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          isAnonymous: true,
          createdAt: DateTime.now(),
        );
        
        await _saveUserToFirestore(userModel);
        await _saveUserToHive(userModel);
        
        return userModel;
      }
      return null;
    } catch (e) {
      throw AuthException('فشل تسجيل الدخول المجهول: $e');
    }
  }

  // Link anonymous account with Google
  Future<UserModel?> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;
      
      // If current user is anonymous, link the account
      if (_auth.currentUser?.isAnonymous ?? false) {
        userCredential = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        // Otherwise sign in directly
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      
      if (user != null) {
        // Get existing user data to preserve progress
        final existingUser = await _getUserFromHive();
        
        final userModel = UserModel(
          uid: user.uid,
          displayName: user.displayName ?? existingUser?.displayName,
          email: user.email,
          photoUrl: user.photoURL,
          selectedAvatarIndex: existingUser?.selectedAvatarIndex ?? 0,
          isAnonymous: false,
          isPremium: existingUser?.isPremium ?? false,
          createdAt: existingUser?.createdAt ?? DateTime.now(),
          totalXp: existingUser?.totalXp ?? 0,
          currentStreak: existingUser?.currentStreak ?? 0,
          completedLessons: existingUser?.completedLessons ?? 0,
        );
        
        await _saveUserToFirestore(userModel);
        await _saveUserToHive(userModel);
        
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw AuthException('هذا الحساب مرتبط بمستخدم آخر');
      }
      throw AuthException('فشل ربط الحساب: ${e.message}');
    } catch (e) {
      throw AuthException('فشل تسجيل الدخول بجوجل: $e');
    }
  }

  // Sign in with Google (for returning users)
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Try to get existing data from Firestore
        UserModel? userModel = await _getUserFromFirestore(user.uid);
        
        if (userModel == null) {
          userModel = UserModel(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoUrl: user.photoURL,
            isAnonymous: false,
            createdAt: DateTime.now(),
          );
          await _saveUserToFirestore(userModel);
        }
        
        await _saveUserToHive(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      throw AuthException('فشل تسجيل الدخول بجوجل: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _clearUserFromHive();
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    String? displayName,
    int? selectedAvatarIndex,
  }) async {
    try {
      final currentUserModel = await _getUserFromHive();
      if (currentUserModel == null) return null;

      final updatedUser = currentUserModel.copyWith(
        displayName: displayName ?? currentUserModel.displayName,
        selectedAvatarIndex: selectedAvatarIndex ?? currentUserModel.selectedAvatarIndex,
      );

      await _saveUserToFirestore(updatedUser);
      await _saveUserToHive(updatedUser);
      
      return updatedUser;
    } catch (e) {
      throw AuthException('فشل تحديث الملف الشخصي: $e');
    }
  }

  // Update user stats (XP, streak, completed lessons)
  Future<UserModel?> updateUserStats({
    int? addXp,
    int? newStreak,
    bool incrementCompletedLessons = false,
  }) async {
    try {
      final currentUserModel = await _getUserFromHive();
      if (currentUserModel == null) return null;

      final updatedUser = currentUserModel.copyWith(
        totalXp: addXp != null 
            ? currentUserModel.totalXp + addXp 
            : currentUserModel.totalXp,
        currentStreak: newStreak ?? currentUserModel.currentStreak,
        completedLessons: incrementCompletedLessons 
            ? currentUserModel.completedLessons + 1 
            : currentUserModel.completedLessons,
      );

      await _saveUserToFirestore(updatedUser);
      await _saveUserToHive(updatedUser);
      
      return updatedUser;
    } catch (e) {
      throw AuthException('فشل تحديث الإحصائيات: $e');
    }
  }

  // Private helper methods
  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc.data()!);
    }
    return null;
  }

  Future<void> _saveUserToHive(UserModel user) async {
    final box = await Hive.openBox<UserModel>(HiveBoxes.user);
    await box.put('currentUser', user);
  }

  Future<UserModel?> _getUserFromHive() async {
    final box = await Hive.openBox<UserModel>(HiveBoxes.user);
    return box.get('currentUser');
  }

  Future<void> _clearUserFromHive() async {
    final box = await Hive.openBox<UserModel>(HiveBoxes.user);
    await box.clear();
  }

  // Get cached user (offline support)
  Future<UserModel?> getCachedUser() async {
    return await _getUserFromHive();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}
