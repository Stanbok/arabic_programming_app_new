import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/quiz_result_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  List<QuizResultModel> _quizResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _userSubscription;
  bool _isListening = false;

  UserModel? get user => _user;
  List<QuizResultModel> get quizResults => _quizResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isListening => _isListening;

  void startListening(String userId) {
    if (_isListening && _userSubscription != null) {
      return; // Already listening
    }
    
    _userSubscription?.cancel();
    _isListening = true;
    
    _userSubscription = FirebaseService.getUserDataStream(userId).listen(
      (user) {
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        print('خطأ في الاستماع لبيانات المستخدم: $error');
        _setError(error.toString());
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
