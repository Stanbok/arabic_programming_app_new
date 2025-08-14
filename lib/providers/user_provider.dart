import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../services/reward_service.dart';
import '../services/statistics_service.dart';
import '../models/user_model.dart';
import '../models/quiz_result_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  List<QuizResultModel> _quizResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _userSubscription;
  bool _isListening = false;
  
  // تتبع محلي للمكافآت المعلقة (في انتظار المزامنة)
  List<RewardInfo> _pendingRewards = [];
  bool _hasPendingRewards = false;

  UserModel? get user => _user;
  List<QuizResultModel> get quizResults => _quizResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isListening => _isListening;
  bool get hasPendingRewards => _hasPendingRewards;
  
  // حساب إجمالي XP والجواهر مع المكافآت المعلقة
  int get totalXP {
    int baseXP = _user?.xp ?? 0;
    int pendingXP = _pendingRewards.fold(0, (sum, reward) => sum + reward.xp);
    return baseXP + pendingXP;
  }
  
  int get totalGems {
    int baseGems = _user?.gems ?? 0;
    int pendingGems = _pendingRewards.fold(0, (sum, reward) => sum + reward.gems);
    return baseGems + pendingGems;
  }
  
  int get currentLevel {
    if (_user == null) return 1;
    return _calculateLevelFromXP(totalXP);
  }

  // تحميل فوري لبيانات المستخدم
  Future<void> loadUserDataInstantly(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // تحميل المكافآت المعلقة فوراً
      await _loadPendingRewards();
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
      
      // مزامنة المكافآت المعلقة مع Firebase
      await _syncPendingRewardsWithFirebase(userId);
      
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

  /// إضافة مكافأة - المصدر الوحيد لإضافة XP والجواهر
  Future<bool> addReward(RewardInfo rewardInfo, String userId) async {
    try {
      print('💎 إضافة مكافأة: $rewardInfo');
      
      // التحقق من صحة المكافأة
      if (!_isValidReward(rewardInfo)) {
        print('❌ مكافأة غير صحيحة: $rewardInfo');
        return false;
      }
      
      // إضافة المكافأة للقائمة المعلقة
      _pendingRewards.add(rewardInfo);
      _hasPendingRewards = true;
      
      // حفظ محلياً
      await _savePendingRewards();
      
      // تحديث الواجهة فوراً
      notifyListeners();
      
      // مزامنة مع Firebase في الخلفية
      _syncRewardWithFirebaseInBackground(rewardInfo, userId);
      
      return true;
    } catch (e) {
      print('❌ خطأ في إضافة المكافأة: $e');
      return false;
    }
  }
  
  /// مزامنة مكافأة واحدة مع Firebase في الخلفية
  Future<void> _syncRewardWithFirebaseInBackground(RewardInfo rewardInfo, String userId) async {
    try {
      await FirebaseService.addXPAndGems(
        userId, 
        rewardInfo.xp, 
        rewardInfo.gems, 
        _getRewardDescription(rewardInfo)
      ).timeout(const Duration(seconds: 10));
      
      // إزالة المكافأة من القائمة المعلقة بعد المزامنة الناجحة
      _pendingRewards.removeWhere((r) => 
        r.xp == rewardInfo.xp && 
        r.gems == rewardInfo.gems && 
        r.source == rewardInfo.source &&
        r.lessonId == rewardInfo.lessonId
      );
      
      _hasPendingRewards = _pendingRewards.isNotEmpty;
      await _savePendingRewards();
      
      print('🔄 تم مزامنة المكافأة مع Firebase: $rewardInfo');
      notifyListeners();
    } catch (e) {
      print('⚠️ فشل في المزامنة مع Firebase: $e');
    }
  }

  /// مزامنة جميع المكافآت المعلقة مع Firebase
  Future<void> _syncPendingRewardsWithFirebase(String userId) async {
    if (_pendingRewards.isEmpty) return;
    
    try {
      print('🔄 مزامنة ${_pendingRewards.length} مكافأة معلقة...');
      
      for (RewardInfo reward in List.from(_pendingRewards)) {
        await FirebaseService.addXPAndGems(
          userId, 
          reward.xp, 
          reward.gems, 
          _getRewardDescription(reward)
        ).timeout(const Duration(seconds: 10));
        
        // إزالة المكافأة بعد المزامنة الناجحة
        _pendingRewards.remove(reward);
      }
      
      _hasPendingRewards = false;
      await _savePendingRewards();
      
      print('✅ تم مزامنة جميع المكافآت المعلقة');
      notifyListeners();
    } catch (e) {
      print('⚠️ فشل في مزامنة المكافآت المعلقة: $e');
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
      
      // إعادة تعيين المكافآت المحلية
      await RewardService.resetAllRewards(_user!.id);
      _pendingRewards.clear();
      _hasPendingRewards = false;
      await _savePendingRewards();
      
      // إعادة تعيين البيانات في Firebase
      await FirebaseService.resetUserProgress(_user!.id);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> get userStats async {
    if (_user == null) {
      return {
        'totalQuizzes': 0,
        'averageScore': 0.0,
        'totalTimeSpent': 0,
        'completionRate': 0.0,
      };
    }

    // Get enhanced statistics from StatisticsService
    final stats = await StatisticsService.getUserStatistics(_user!.id);
    return stats;
  }

  /// حفظ المكافآت المعلقة محلياً
  Future<void> _savePendingRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = _pendingRewards.map((r) => r.toMap()).toList();
      await prefs.setString('pending_rewards', rewardsJson.toString());
      await prefs.setBool('has_pending_rewards', _hasPendingRewards);
    } catch (e) {
      print('❌ خطأ في حفظ المكافآت المعلقة: $e');
    }
  }

  /// تحميل المكافآت المعلقة محلياً
  Future<void> _loadPendingRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasPendingRewards = prefs.getBool('has_pending_rewards') ?? false;
      
      // يمكن تحسين هذا لاحقاً لتحميل المكافآت الفعلية
      // حالياً نعتمد على النظام الجديد
      _pendingRewards = [];
    } catch (e) {
      print('❌ خطأ في تحميل المكافآت المعلقة: $e');
      _pendingRewards = [];
      _hasPendingRewards = false;
    }
  }

  /// التحقق من صحة المكافأة
  bool _isValidReward(RewardInfo rewardInfo) {
    // التحقق من القيم الأساسية
    if (rewardInfo.xp < 0 || rewardInfo.gems < 0) {
      return false;
    }
    
    // التحقق من المصدر
    if (rewardInfo.source.isEmpty) {
      return false;
    }
    
    // التحقق من النتيجة إذا كانت من اختبار
    if (rewardInfo.source == 'lesson_completion' && rewardInfo.score != null) {
      if (rewardInfo.score! < 0 || rewardInfo.score! > 100) {
        return false;
      }
    }
    
    return true;
  }

  /// الحصول على وصف المكافأة
  String _getRewardDescription(RewardInfo rewardInfo) {
    switch (rewardInfo.source) {
      case 'lesson_completion':
        return 'إكمال درس: ${rewardInfo.lessonId} (${rewardInfo.score}%)';
      case 'lesson_retake':
        return 'إعادة محاولة درس: ${rewardInfo.lessonId} (${rewardInfo.score}%) - مضاعف: ${(rewardInfo.retakeMultiplier * 100).round()}%';
      default:
        return 'مكافأة: ${rewardInfo.source}';
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

  int _calculateLevelFromXP(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    return (xp / 500).floor() + 1;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
