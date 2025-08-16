import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _userSubscription;
  bool _isListening = false;
  
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isListening => _isListening;
  
  int get totalXP => _user?.xp ?? 0;
  int get totalGems => _user?.gems ?? 0;
  int get currentLevel => _user?.currentLevel ?? 1;

  // تحميل فوري لبيانات المستخدم
  Future<void> loadUserDataInstantly(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
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

  Future<String?> uploadProfileImage(String imagePath) async {
    if (_user == null) return null;
    
    try {
      _setLoading(true);
      
      // Deduct 100 gems for profile image upload
      if (totalGems < 100) {
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
      
      // إعادة تعيين البيانات المحلية في LessonProvider
      // سيتم استدعاؤها من الشاشة التي تحتوي على كلا المزودين
      
      // إعادة تعيين البيانات في Firebase
      await FirebaseService.resetUserProgress(_user!.id);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
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

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
