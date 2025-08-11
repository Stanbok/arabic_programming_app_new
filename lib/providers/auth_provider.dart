import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuestUser = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null || _isGuestUser;
  bool get isGuestUser => _isGuestUser;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadGuestStatus();
  }

  Future<void> _loadGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuestUser = prefs.getBool('is_guest_user') ?? false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await FirebaseService.signInWithEmailAndPassword(email, password);
      if (credential != null) {
        _user = credential.user;
        _isGuestUser = false;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest_user', false);
        await prefs.setBool('stay_logged_in', true);
        
        // Update last login time
        if (_user != null) {
          await FirebaseService.updateUserData(_user!.uid, {
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      _user = userCredential.user;
      _isGuestUser = false;

      if (_user != null) {
        // إنشاء أو تحديث بيانات المستخدم
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (!userDoc.exists) {
          final userModel = UserModel(
            id: _user!.uid,
            name: _user!.displayName ?? 'مستخدم Google',
            email: _user!.email ?? '',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await FirebaseService.createUserDocument(userModel);
        } else {
          await FirebaseService.updateUserData(_user!.uid, {
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest_user', false);
        await prefs.setBool('stay_logged_in', true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      _setLoading(true);
      _clearError();

      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return false;

      final OAuthCredential facebookAuthCredential = 
          FacebookAuthProvider.credential(result.accessToken!.token);

      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(facebookAuthCredential);
      _user = userCredential.user;
      _isGuestUser = false;

      if (_user != null) {
        // إنشاء أو تحديث بيانات المستخدم
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (!userDoc.exists) {
          final userModel = UserModel(
            id: _user!.uid,
            name: _user!.displayName ?? 'مستخدم Facebook',
            email: _user!.email ?? '',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await FirebaseService.createUserDocument(userModel);
        } else {
          await FirebaseService.updateUserData(_user!.uid, {
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest_user', false);
        await prefs.setBool('stay_logged_in', true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAsGuest() async {
    try {
      _setLoading(true);
      _clearError();

      _isGuestUser = true;
      _user = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_user', true);
      await prefs.setBool('stay_logged_in', true);

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await FirebaseService.createUserWithEmailAndPassword(email, password);
      if (credential != null) {
        _user = credential.user;
        _isGuestUser = false;
        
        // Create user document in Firestore
        final userModel = UserModel(
          id: _user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await FirebaseService.createUserDocument(userModel);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest_user', false);
        await prefs.setBool('stay_logged_in', true);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await FirebaseService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      if (!_isGuestUser) {
        await FirebaseService.signOut();
        await GoogleSignIn().signOut();
        await FacebookAuth.instance.logOut();
      }
      
      _user = null;
      _isGuestUser = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_user', false);
      await prefs.setBool('stay_logged_in', false);
      
      notifyListeners();
    } catch (e) {
      _setError(_getArabicErrorMessage(e.toString()));
    }
  }

  Future<bool> checkSavedLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
    final isGuest = prefs.getBool('is_guest_user') ?? false;
    
    if (stayLoggedIn) {
      if (isGuest) {
        _isGuestUser = true;
        notifyListeners();
        return true;
      } else if (_user != null) {
        return true;
      }
    }
    return false;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getArabicErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
    } else if (error.contains('wrong-password')) {
      return 'كلمة المرور غير صحيحة';
    } else if (error.contains('email-already-in-use')) {
      return 'هذا البريد الإلكتروني مستخدم بالفعل';
    } else if (error.contains('weak-password')) {
      return 'كلمة المرور ضعيفة جداً';
    } else if (error.contains('invalid-email')) {
      return 'البريد الإلكتروني غير صحيح';
    } else if (error.contains('network-request-failed')) {
      return 'خطأ في الاتصال بالإنترنت';
    }
    return 'حدث خطأ غير متوقع';
  }
}
