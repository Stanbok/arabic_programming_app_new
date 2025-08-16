import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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

  Future<T?> _executeWithErrorHandling<T>(
    Future<T> Function() operation,
    String operationName,
    {Duration timeout = const Duration(seconds: 10)}
  ) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔐 بدء $operationName...');
      
      final result = await operation().timeout(timeout, onTimeout: () {
        throw Exception('انتهت مهلة $operationName - تأكد من اتصال الإنترنت');
      });
      
      print('✅ تم $operationName بنجاح');
      return result;
    } catch (e) {
      print('❌ خطأ في $operationName: $e');
      _setError(_getArabicErrorMessage(e.toString()));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updateUserDataSafely(String uid, Map<String, dynamic> data) async {
    try {
      await FirebaseService.updateUserData(uid, data)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      print('⚠️ فشل في تحديث بيانات المستخدم: $e');
      // لا نفشل العملية بسبب هذا الخطأ
    }
  }

  Future<void> _createOrUpdateUserDocument(String name) async {
    if (_user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!userDoc.exists) {
        final userModel = UserModel(
          id: _user!.uid,
          name: name,
          email: _user!.email ?? '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await FirebaseService.createUserDocument(userModel)
            .timeout(const Duration(seconds: 5));
      } else {
        await _updateUserDataSafely(_user!.uid, {
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('⚠️ فشل في إنشاء/تحديث مستند المستخدم: $e');
    }
  }

  Future<void> _saveLoginState({bool isGuest = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_user', isGuest);
    await prefs.setBool('stay_logged_in', true);
  }

  Future<bool> signIn(String email, String password) async {
    final credential = await _executeWithErrorHandling(
      () => FirebaseService.signInWithEmailAndPassword(email, password),
      'تسجيل الدخول',
      timeout: const Duration(seconds: 12),
    );
    
    if (credential != null) {
      _user = credential.user;
      _isGuestUser = false;
      
      if (_user != null) {
        await _updateUserDataSafely(_user!.uid, {
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
      
      await _saveLoginState();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signInWithGoogle() async {
    final googleUser = await _executeWithErrorHandling(
      () async {
        final user = await GoogleSignIn().signIn();
        if (user == null) throw Exception('تم إلغاء تسجيل الدخول');
        return user;
      },
      'تسجيل الدخول عبر Google',
      timeout: const Duration(seconds: 25),
    );
    
    if (googleUser == null) return false;

    final result = await _executeWithErrorHandling(
      () async {
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await FirebaseAuth.instance.signInWithCredential(credential);
      },
      'المصادقة عبر Google',
    );

    if (result != null) {
      _user = result.user;
      _isGuestUser = false;
      
      await _createOrUpdateUserDocument(_user!.displayName ?? 'مستخدم Google');
      await _saveLoginState();
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signInWithFacebook() async {
    final loginResult = await _executeWithErrorHandling(
      () async {
        final result = await FacebookAuth.instance.login();
        if (result.status != LoginStatus.success) {
          throw Exception('فشل في تسجيل الدخول عبر Facebook');
        }
        return result;
      },
      'تسجيل الدخول عبر Facebook',
      timeout: const Duration(seconds: 25),
    );
    
    if (loginResult == null) return false;

    final result = await _executeWithErrorHandling(
      () async {
        final facebookAuthCredential = 
            FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
        return await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      },
      'المصادقة عبر Facebook',
    );

    if (result != null) {
      _user = result.user;
      _isGuestUser = false;
      
      await _createOrUpdateUserDocument(_user!.displayName ?? 'مستخدم Facebook');
      await _saveLoginState();
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signInAsGuest() async {
    final result = await _executeWithErrorHandling(
      () async {
        _isGuestUser = true;
        _user = null;
        return true;
      },
      'تسجيل الدخول كضيف',
    );

    if (result == true) {
      await _saveLoginState(isGuest: true);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    final credential = await _executeWithErrorHandling(
      () => FirebaseService.createUserWithEmailAndPassword(email, password),
      'إنشاء حساب جديد',
      timeout: const Duration(seconds: 12),
    );
    
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
      
      try {
        await FirebaseService.createUserDocument(userModel)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        print('⚠️ فشل في إنشاء مستند المستخدم: $e');
      }

      await _saveLoginState();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> resetPassword(String email) async {
    bool success = false;
    await _executeWithErrorHandling(
      () async {
        await FirebaseService.sendPasswordResetEmail(email);
        success = true; // إذا لم يحدث خطأ، فالعملية نجحت
      },
      'إرسال رابط إعادة تعيين كلمة المرور',
      timeout: const Duration(seconds: 8),
    );
    return success;
  }

  Future<void> signOut() async {
    try {
      if (!_isGuestUser) {
        // تنفيذ عمليات تسجيل الخروج بشكل متوازي لتحسين الأداء
        await Future.wait([
          FirebaseService.signOut().catchError((e) => print('خطأ في Firebase signOut: $e')),
          GoogleSignIn().signOut().catchError((e) => print('خطأ في Google signOut: $e')),
          FacebookAuth.instance.logOut().catchError((e) => print('خطأ في Facebook signOut: $e')),
        ]);
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
    final errorMap = {
      'user-not-found': 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني',
      'wrong-password': 'كلمة المرور غير صحيحة',
      'email-already-in-use': 'هذا البريد الإلكتروني مستخدم بالفعل',
      'weak-password': 'كلمة المرور ضعيفة جداً',
      'invalid-email': 'البريد الإلكتروني غير صحيح',
      'too-many-requests': 'تم تجاوز عدد المحاولات المسموح - حاول مرة أخرى لاحقاً',
      'operation-not-allowed': 'هذه الطريقة غير مفعلة حالياً',
      'account-exists-with-different-credential': 'يوجد حساب بنفس البريد الإلكتروني بطريقة تسجيل دخول مختلفة',
    };

    for (final entry in errorMap.entries) {
      if (error.contains(entry.key)) {
        return entry.value;
      }
    }

    if (error.contains('network-request-failed') || error.contains('انتهت مهلة')) {
      return 'خطأ في الاتصال بالإنترنت - تحقق من اتصالك وحاول مرة أخرى';
    }

    return 'حدث خطأ غير متوقع - حاول مرة أخرى';
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
}
