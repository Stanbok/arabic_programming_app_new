import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/quiz_result_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  List<QuizResultModel> _quizResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _userSubscription;
  bool _isListening = false;
  
  // تتبع محلي للـ XP والجواهر
  int _localXP = 0;
  int _localGems = 0;
  bool _hasLocalProgress = false;

  UserModel? get user => _user;
  List<QuizResultModel> get quizResults => _quizResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isListening => _isListening;
  int get totalXP => (_user?.xp ?? 0) + _localXP;
  int get totalGems => (_user?.gems ?? 0) + _localGems;

  // تحميل فوري لبيانات المستخدم
  Future<void> loadUserDataInstantly(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // تحميل التقدم المحلي فوراً
      await _loadLocalProgress();
      notifyListeners();
      
      // تحميل بيانات Firebase في الخلفية
      _loadFirebaseUserDataInBackground(userId);
      
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // تحميل بيانات Firebase في الخلفية
  Future<void> _loadFirebaseUserDataInBackground(String userId) async {
    try {
      // بدء الاستماع للتحديثات
      if (!_isListening) {
        startListening(userId);
      }
      
      // جلب البيانات مرة واحدة مع timeout قصير
      _user = await FirebaseService.getUserData(userId)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      
      if (_user == null) {
        // إنشاء مستخدم جديد بالقيم الافتراضية
        await _createNewUser(userId);
      }
      
      // مزامنة التقدم المحلي مع Firebase
      await _syncLocalProgressWithFirebase();
      
      notifyListeners();
    } catch (e) {
      print('⚠️ فشل تحميل بيانات Firebase (سيتم المتابعة بالبيانات المحلية): $e');
    }
  }

  // إنشاء مستخدم جديد بالقيم الافتراضية
  Future<void> _createNewUser(String userId) async {
    try {
      final newUser = UserModel(
        id: userId,
        name: 'مستخدم جديد',
        email: '',
        xp: 0,
        gems: 0,
        currentLevel: 1,
        completedLessons: [],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      await FirebaseService.createUserDocument(newUser)
          .timeout(const Duration(seconds: 10));
      
      _user = newUser;
      print('✅ تم إنشاء مستخدم جديد بالقيم الافتراضية');
    } catch (e) {
      print('⚠️ فشل في إنشاء المستخدم الجديد: $e');
    }
  }

  // إضافة XP وجواهر محلياً (فوري)
  Future<void> addXPAndGemsLocally(int xp, int gems, String reason) async {
    _localXP += xp;
    _localGems += gems;
    _hasLocalProgress = true;
    
    await _saveLocalProgress();
    notifyListeners();
    
    print('💎 تم إضافة محلياً: +$xp XP, +$gems جوهرة ($reason)');
    
    // مزامنة مع Firebase في الخلفية
    _syncWithFirebaseInBackground(xp, gems, reason);
  }

  // مزامنة مع Firebase في الخلفية
  Future<void> _syncWithFirebaseInBackground(int xp, int gems, String reason) async {
    if (_user == null) return;
    
    try {
      await FirebaseService.addXPAndGems(_user!.id, xp, gems, reason)
          .timeout(const Duration(seconds: 10));
      
      print('🔄 تم مزامنة التقدم مع Firebase');
    } catch (e) {
      print('⚠️ فشل في المزامنة مع Firebase: $e');
    }
  }

  // حفظ التقدم المحلي
  Future<void> _saveLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('local_xp', _localXP);
    await prefs.setInt('local_gems', _localGems);
    await prefs.setBool('has_local_progress', _hasLocalProgress);
  }

  // تحميل التقدم المحلي
  Future<void> _loadLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _localXP = prefs.getInt('local_xp') ?? 0;
    _localGems = prefs.getInt('local_gems') ?? 0;
    _hasLocalProgress = prefs.getBool('has_local_progress') ?? false;
  }

  // مزامنة التقدم المحلي مع Firebase
  Future<void> _syncLocalProgressWithFirebase() async {
    if (!_hasLocalProgress || _user == null) return;
    
    try {
      if (_localXP > 0 || _localGems > 0) {
        await FirebaseService.addXPAndGems(
          _user!.id, 
          _localXP, 
          _localGems, 
          'مزامنة التقدم المحلي'
        ).timeout(const Duration(seconds: 10));
        
        // مسح التقدم المحلي بعد المزامنة
        _localXP = 0;
        _localGems = 0;
        _hasLocalProgress = false;
        await _saveLocalProgress();
        
        print('🔄 تم مزامنة التقدم المحلي مع Firebase');
      }
    } catch (e) {
      print('⚠️ فشل في مزامنة التقدم المحلي: $e');
    }
  }

  void startListening(String userId) {
    if (_isListening && _userSubscription != null) {
      return;
    }
    
    _userSubscription?.cancel();
    _isListening = true;
    
    _userSubscription = FirebaseService.getUserDataStream(userId).listen(
      (user) {
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        print('⚠️ خطأ في الاستماع لبيانات المستخدم: $error');
        _isListening = false;
      },
    );
  }

  void stopListening() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _isListening = false;
  }

  Future<void> loadUserData(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // إذا لم نكن نستمع بعد، ابدأ الاستماع
      if (!_isListening) {
        startListening(userId);
      }
      
      // جلب البيانات مرة واحدة للتحميل السريع
      _user = await FirebaseService.getUserData(userId);
      _quizResults = await FirebaseService.getQuizResults(userId);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return;
    
    try {
      await FirebaseService.updateUserData(_user!.id, data);
      // The stream listener will automatically update the user data
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> addXPAndGems(int xp, int gems, String reason) async {
    if (_user == null) return;
    
    try {
      await FirebaseService.addXPAndGems(_user!.id, xp, gems, reason);
      // The stream listener will automatically update the user data
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<String?> uploadProfileImage(String imagePath) async {
    if (_user == null) return null;
    
    try {
      _setLoading(true);
      
      // Deduct 100 gems for profile image upload
      if (_user!.gems < 100) {
        throw Exception('تحتاج إلى 100 جوهرة لتغيير صورة الملف الشخصي');
      }
      
      final imageUrl = await FirebaseService.uploadProfileImage(_user!.id, imagePath);
      
      // Update user data with new image URL and deduct gems
      await FirebaseService.updateUserData(_user!.id, {
        'profileImageUrl': imageUrl,
        'gems': FieldValue.increment(-100),
      });
      
      // Add transaction log
      await FirebaseService.addXPAndGems(_user!.id, 0, -100, 'تغيير صورة الملف الشخصي');
      
      return imageUrl;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetProgress() async {
    if (_user == null) return;
    
    try {
      _setLoading(true);
      await FirebaseService.resetUserProgress(_user!.id);
      // The stream listener will automatically update the user data
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Map<String, dynamic> get userStats {
    if (_user == null || _quizResults.isEmpty) {
      return {
        'totalQuizzes': 0,
        'averageScore': 0.0,
        'totalTimeSpent': 0,
        'completionRate': 0.0,
      };
    }

    final totalQuizzes = _quizResults.length;
    final averageScore = _quizResults.map((r) => r.score).reduce((a, b) => a + b) / totalQuizzes;
    final completionRate = (_user!.completedLessons.length / 50.0) * 100; // Assuming 50 total lessons

    return {
      'totalQuizzes': totalQuizzes,
      'averageScore': averageScore,
      'totalTimeSpent': 0, // Would need to calculate from progress data
      'completionRate': completionRate,
    };
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

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
