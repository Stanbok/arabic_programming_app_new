import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
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
  
  // Pending rewards system
  List<RewardInfo> _pendingRewards = [];
  bool _hasPendingRewards = false;
  
  // Getters
  UserModel? get user => _user;
  List<QuizResultModel> get quizResults => _quizResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isListening => _isListening;
  List<RewardInfo> get pendingRewards => _pendingRewards;
  bool get hasPendingRewards => _hasPendingRewards;
  
  // Total XP and Gems including pending rewards
  int get totalXP => (_user?.xp ?? 0) + _pendingRewards.fold(0, (sum, reward) => sum + reward.xp);
  int get totalGems => (_user?.gems ?? 0) + _pendingRewards.fold(0, (sum, reward) => sum + reward.gems);
  int get currentLevel => _calculateLevelFromXP(totalXP);

  UserProvider() {
    _loadPendingRewards();
  }

  // Initialize user data
  Future<void> initializeUser(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 تهيئة بيانات المستخدم: $userId');
      
      // Load user data from Firebase
      _user = await FirebaseService.getUserData(userId);
      
      if (_user == null) {
        print('⚠️ لا توجد بيانات للمستخدم في Firebase');
        return;
      }
      
      print('✅ تم تحميل بيانات المستخدم: ${_user!.name}');
      
      // Load pending rewards
      await _loadPendingRewards();
      
      // Sync pending rewards with Firebase if connected
      await _syncPendingRewardsWithFirebase(userId);
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تهيئة المستخدم: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Listen to user data changes
  void listenToUserChanges(String userId) {
    FirebaseService.getUserDataStream(userId).listen(
      (userData) {
        if (userData != null) {
          _user = userData;
          notifyListeners();
        }
      },
      onError: (error) {
        print('خطأ في stream المستخدم: $error');
        _setError(error.toString());
      },
    );
  }

  // Add pending reward
  Future<void> addPendingReward(RewardInfo reward) async {
    _pendingRewards.add(reward);
    _hasPendingRewards = true;
    await _savePendingRewards();
    
    print('💎 إضافة مكافأة معلقة: +${reward.xp} XP, +${reward.gems} Gems (${reward.source})');
    
    // Try to sync immediately if user is available
    if (_user != null) {
      await _syncPendingRewardsWithFirebase(_user!.id);
    }
    
    notifyListeners();
  }

  // Upload profile image with gem cost - إصلاح المشكلة الثالثة
  Future<String?> uploadProfileImage(String imagePath) async {
    if (_user == null) return null;
    
    try {
      _setLoading(true);
      
      // التحقق من الجواهر الفعلية في Firebase (وليس المجموع المحلي)
      final currentUserData = await FirebaseService.getUserData(_user!.id);
      final actualGems = currentUserData?.gems ?? 0;
      
      if (actualGems < 100) {
        throw Exception('تحتاج إلى 100 جوهرة لتغيير صورة الملف الشخصي (لديك $actualGems جوهرة)');
      }
      
      // رفع الصورة أولاً
      final imageUrl = await FirebaseService.uploadProfileImage(_user!.id, imagePath);
      
      if (imageUrl != null) {
        // تحديث بيانات المستخدم مع الصورة الجديدة
        await FirebaseService.updateUserData(_user!.id, {
          'profileImageUrl': imageUrl,
        });
        
        // خصم 100 جوهرة
        await FirebaseService.addXPAndGems(_user!.id, 0, -100, 'تغيير صورة الملف الشخصي');
        
        // تحديث البيانات المحلية فوراً
        if (_user != null) {
          _user = _user!.copyWith(
            profileImageUrl: imageUrl,
            gems: _user!.gems - 100,
          );
          notifyListeners();
        }
        
        return imageUrl;
      }
      
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Reset user progress - إصلاح المشكلة الرابعة
  Future<void> resetProgress() async {
    if (_user == null) return;
    
    try {
      _setLoading(true);
      
      // 1. إعادة تعيين المكافآت والإحصائيات المحلية
      await RewardService.resetAllRewards(_user!.id);
      await StatisticsService.resetAllStatistics(_user!.id);
      
      // 2. مسح المكافآت المعلقة
      _pendingRewards.clear();
      _hasPendingRewards = false;
      await _savePendingRewards();
      
      // 3. مسح البيانات المحلية للدروس
      await _resetLocalLessonProgress();
      
      // 4. إعادة تعيين البيانات في Firebase
      await FirebaseService.resetUserProgress(_user!.id);
      
      // 5. تحديث البيانات المحلية
      if (_user != null) {
        _user = _user!.copyWith(
          xp: 0,
          gems: 0,
          currentLevel: 1,
          completedLessons: [],
        );
      }
      
      print('🔄 تم إعادة تعيين تقدم المستخدم بالكامل');
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sync pending rewards with Firebase - إصلاح المشكلة الخامسة
  Future<void> _syncPendingRewardsWithFirebase(String userId) async {
    if (_pendingRewards.isEmpty) return;
    
    try {
      // التحقق من حالة الشبكة أولاً
      final isConnected = await FirebaseService.checkConnection();
      if (!isConnected) {
        print('⚠️ لا يوجد اتصال بالإنترنت - تأجيل المزامنة');
        return;
      }
      
      print('🔄 مزامنة ${_pendingRewards.length} مكافأة معلقة مع Firebase...');
      
      // مزامنة المكافآت مع إعادة المحاولة
      for (RewardInfo reward in List.from(_pendingRewards)) {
        bool synced = false;
        int attempts = 0;
        const maxAttempts = 3;
        
        while (!synced && attempts < maxAttempts) {
          try {
            await FirebaseService.addXPAndGems(
              userId, 
              reward.xp, 
              reward.gems, 
              _getRewardDescription(reward)
            ).timeout(const Duration(seconds: 10));
            
            // إزالة المكافأة بعد المزامنة الناجحة
            _pendingRewards.remove(reward);
            synced = true;
            
            print('✅ تم مزامنة المكافأة: +${reward.xp} XP, +${reward.gems} Gems');
          } catch (e) {
            attempts++;
            print('⚠️ فشل في مزامنة المكافأة (المحاولة $attempts/$maxAttempts): $e');
            
            if (attempts < maxAttempts) {
              // انتظار متزايد قبل إعادة المحاولة
              await Future.delayed(Duration(seconds: attempts * 2));
            }
          }
        }
      }
      
      _hasPendingRewards = _pendingRewards.isNotEmpty;
      await _savePendingRewards();
      
      if (_pendingRewards.isEmpty) {
        print('✅ تم مزامنة جميع المكافآت المعلقة بنجاح');
      } else {
        print('⚠️ فشل في مزامنة ${_pendingRewards.length} مكافأة - ستتم المحاولة لاحقاً');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في مزامنة المكافآت: $e');
    }
  }

  // Load pending rewards from local storage
  Future<void> _loadPendingRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = prefs.getString('pending_rewards') ?? '[]';
      final List<dynamic> rewardsList = json.decode(rewardsJson);
      
      _pendingRewards = rewardsList
          .map((json) => RewardInfo.fromMap(json))
          .toList();
      
      _hasPendingRewards = _pendingRewards.isNotEmpty;
      
      if (_pendingRewards.isNotEmpty) {
        print('📦 تم تحميل ${_pendingRewards.length} مكافأة معلقة');
      }
    } catch (e) {
      print('خطأ في تحميل المكافآت المعلقة: $e');
      _pendingRewards = [];
      _hasPendingRewards = false;
    }
  }

  // Save pending rewards to local storage
  Future<void> _savePendingRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = _pendingRewards.map((r) => r.toMap()).toList();
      await prefs.setString('pending_rewards', json.encode(rewardsJson));
    } catch (e) {
      print('خطأ في حفظ المكافآت المعلقة: $e');
    }
  }

  // Reset local lesson progress
  Future<void> _resetLocalLessonProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (String key in keys) {
        if (key.startsWith('lesson_') || 
            key.startsWith('quiz_') ||
            key.contains('completed_') ||
            key.contains('progress_')) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️ تم مسح البيانات المحلية للدروس');
    } catch (e) {
      print('خطأ في مسح البيانات المحلية: $e');
    }
  }

  // Helper methods
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

  String _getRewardDescription(RewardInfo reward) {
    switch (reward.source) {
      case 'lesson_completion':
        return 'إكمال الدرس ${reward.lessonId}';
      case 'quiz_completion':
        return 'إكمال اختبار الدرس ${reward.lessonId}';
      case 'first_lesson_pass':
        return 'النجاح الأول في الدرس ${reward.lessonId}';
      case 'perfect_score':
        return 'النتيجة المثالية في الدرس ${reward.lessonId}';
      case 'level_up':
        return 'ترقية المستوى';
      default:
        return 'مكافأة ${reward.source}';
    }
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
    _userSubscription?.cancel();
    super.dispose();
  }
}

// RewardInfo class for pending rewards
class RewardInfo {
  final String source;
  final String? lessonId;
  final int xp;
  final int gems;
  final DateTime timestamp;

  RewardInfo({
    required this.source,
    this.lessonId,
    required this.xp,
    required this.gems,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'lessonId': lessonId,
      'xp': xp,
      'gems': gems,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RewardInfo.fromMap(Map<String, dynamic> map) {
    return RewardInfo(
      source: map['source'] ?? '',
      lessonId: map['lessonId'],
      xp: map['xp'] ?? 0,
      gems: map['gems'] ?? 0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
