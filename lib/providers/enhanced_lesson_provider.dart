import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/enhanced_lesson_model.dart';
import '../services/enhanced_firebase_service.dart';
import '../services/code_execution_service.dart';
import '../services/reward_service.dart';
import '../services/firebase_service.dart';
import '../models/decay_tracker_model.dart';

class EnhancedLessonProvider with ChangeNotifier {
  EnhancedLessonModel? _currentLesson;
  int _currentBlockIndex = 0;
  Map<String, dynamic> _blockProgress = {};
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, DecayTrackerModel> _decayTrackers = {};
  bool _lessonCompleted = false;
  Map<String, int>? _lastRewards;

  EnhancedLessonModel? get currentLesson => _currentLesson;
  int get currentBlockIndex => _currentBlockIndex;
  Map<String, dynamic> get blockProgress => _blockProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get lessonCompleted => _lessonCompleted;
  Map<String, int>? get lastRewards => _lastRewards;

  double get lessonProgress {
    if (_currentLesson == null || _currentLesson!.blocks.isEmpty) return 0.0;
    return (_currentBlockIndex + 1) / _currentLesson!.blocks.length;
  }

  Future<void> loadEnhancedLesson(String lessonId) async {
    try {
      _setLoading(true);
      _clearError();

      _currentLesson = await EnhancedFirebaseService.getEnhancedLesson(lessonId);
      
      if (_currentLesson != null) {
        await _loadLessonProgress(lessonId);
        await _loadDecayTrackers();
        _currentBlockIndex = _getLastCompletedBlockIndex();
        _lessonCompleted = _isLessonFullyCompleted();
      }

      notifyListeners();
    } catch (e) {
      _setError('فشل في تحميل الدرس: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeBlock(String blockId, Map<String, dynamic> result) async {
    if (_currentLesson == null) return;

    try {
      _blockProgress[blockId] = {
        'completed': true,
        'result': result,
        'completedAt': DateTime.now().toIso8601String(),
      };

      await _saveLessonProgress(_currentLesson!.id);
      
      // الانتقال للكتلة التالية إذا كانت متاحة
      if (_currentBlockIndex < _currentLesson!.blocks.length - 1) {
        _currentBlockIndex++;
      }

      notifyListeners();
    } catch (e) {
      _setError('فشل في حفظ تقدم الكتلة: $e');
    }
  }

  Future<void> executeCode(String code, String language) async {
    try {
      final result = await CodeExecutionService.executeCode(code, language);
      return result;
    } catch (e) {
      throw Exception('فشل في تنفيذ الكود: $e');
    }
  }

  void navigateToBlock(int index) {
    if (_currentLesson != null && index >= 0 && index < _currentLesson!.blocks.length) {
      _currentBlockIndex = index;
      notifyListeners();
    }
  }

  void nextBlock() {
    if (_currentLesson != null && _currentBlockIndex < _currentLesson!.blocks.length - 1) {
      _currentBlockIndex++;
      notifyListeners();
    }
  }

  void previousBlock() {
    if (_currentBlockIndex > 0) {
      _currentBlockIndex--;
      notifyListeners();
    }
  }

  bool isBlockCompleted(String blockId) {
    return _blockProgress[blockId]?['completed'] ?? false;
  }

  Map<String, dynamic>? getBlockResult(String blockId) {
    return _blockProgress[blockId]?['result'];
  }

  int _getLastCompletedBlockIndex() {
    if (_currentLesson == null) return 0;
    
    for (int i = _currentLesson!.blocks.length - 1; i >= 0; i--) {
      if (isBlockCompleted(_currentLesson!.blocks[i].id)) {
        return i + 1 < _currentLesson!.blocks.length ? i + 1 : i;
      }
    }
    return 0;
  }

  Future<void> _loadLessonProgress(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressString = prefs.getString('enhanced_lesson_progress_$lessonId');
      
      if (progressString != null) {
        _blockProgress = Map<String, dynamic>.from(json.decode(progressString));
      } else {
        _blockProgress = {};
      }
    } catch (e) {
      _blockProgress = {};
    }
  }

  Future<void> _saveLessonProgress(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('enhanced_lesson_progress_$lessonId', json.encode(_blockProgress));
    } catch (e) {
      print('خطأ في حفظ تقدم الدرس: $e');
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
  }

  Future<void> completeQuizBlock(String blockId, double scorePercentage, String userId) async {
    if (_currentLesson == null) return;

    try {
      // حفظ نتيجة الكتلة
      _blockProgress[blockId] = {
        'completed': true,
        'score': scorePercentage,
        'isPassed': scorePercentage >= 70,
        'completedAt': DateTime.now().toIso8601String(),
      };

      // إذا نجح في الاختبار، حساب المكافآت
      if (scorePercentage >= 70) {
        await _calculateAndAwardRewards(blockId, scorePercentage, userId);
        
        _checkLessonCompletion(userId);
      }

      await _saveLessonProgress(_currentLesson!.id);
      
      // الانتقال للكتلة التالية
      if (_currentBlockIndex < _currentLesson!.blocks.length - 1) {
        _currentBlockIndex++;
      }

      notifyListeners();
    } catch (e) {
      _setError('فشل في حفظ نتيجة الاختبار: $e');
    }
  }

  Future<void> _calculateAndAwardRewards(String blockId, double scorePercentage, String userId) async {
    if (_currentLesson == null) return;

    try {
      // تحويل الدرس المحسن إلى نموذج الدرس العادي للمكافآت
      final lessonModel = LessonModel(
        id: _currentLesson!.id,
        title: _currentLesson!.title,
        description: _currentLesson!.description,
        unit: _currentLesson!.unit,
        order: _currentLesson!.order,
        xpReward: _currentLesson!.xpReward,
        gemsReward: _currentLesson!.gemsReward,
        slides: [], // فارغ للدروس المحسنة
        questions: [], // فارغ للدروس المحسنة
      );

      // الحصول على تتبع الاضمحلال
      final decayTracker = _decayTrackers[blockId];
      
      // حساب المكافآت
      final rewards = RewardService.calculateTotalRewards(
        lessonModel, 
        scorePercentage, 
        decayTracker: decayTracker
      );

      _lastRewards = rewards;

      // إعطاء المكافآت إذا كانت أكبر من صفر
      if (rewards['xp']! > 0 || rewards['gems']! > 0) {
        await FirebaseService.addXPAndGems(
          userId,
          rewards['xp']!,
          rewards['gems']!,
          'إكمال كتلة: ${_currentLesson!.title} (${scorePercentage.toStringAsFixed(1)}%)'
        );
      }

      // تحديث تتبع الاضمحلال
      await _updateDecayTracker(blockId);

    } catch (e) {
      print('خطأ في حساب المكافآت: $e');
    }
  }

  Future<void> _updateDecayTracker(String blockId) async {
    try {
      if (_decayTrackers.containsKey(blockId)) {
        // كتلة تم إكمالها مسبقاً - تحديث الإعادة
        final currentTracker = _decayTrackers[blockId]!;
        _decayTrackers[blockId] = currentTracker.withDailyReset().withNewRetake();
      } else {
        // كتلة جديدة - إنشاء تتبع جديد
        _decayTrackers[blockId] = DecayTrackerModel(retakeCount: 0);
      }

      // حفظ محلياً
      await _saveDecayTrackers();
    } catch (e) {
      print('خطأ في تحديث تتبع الاضمحلال: $e');
    }
  }

  void _checkLessonCompletion(String userId) {
    if (_currentLesson == null) return;

    // فحص إذا كانت جميع الكتل مكتملة
    bool allBlocksCompleted = true;
    for (final block in _currentLesson!.blocks) {
      if (block.type == 'quiz' && !isBlockCompleted(block.id)) {
        allBlocksCompleted = false;
        break;
      }
    }

    if (allBlocksCompleted && !_lessonCompleted) {
      _lessonCompleted = true;
      _markLessonAsCompleted(userId);
    }
  }

  Future<void> _markLessonAsCompleted(String userId) async {
    if (_currentLesson == null) return;

    try {
      // إضافة الدرس للقائمة المكتملة في Firebase
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([_currentLesson!.id]),
      });

      print('✅ تم تسجيل الدرس المحسن كمكتمل: ${_currentLesson!.id}');
    } catch (e) {
      print('❌ خطأ في تسجيل إكمال الدرس المحسن: $e');
    }
  }

  Future<void> _saveDecayTrackers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackersMap = _decayTrackers.map((key, value) => MapEntry(key, value.toMap()));
      await prefs.setString('decay_trackers_${_currentLesson?.id}', json.encode(trackersMap));
    } catch (e) {
      print('خطأ في حفظ تتبع الاضمحلال: $e');
    }
  }

  Future<void> _loadDecayTrackers() async {
    if (_currentLesson == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackersString = prefs.getString('decay_trackers_${_currentLesson!.id}');
      
      if (trackersString != null) {
        final trackersMap = Map<String, dynamic>.from(json.decode(trackersString));
        _decayTrackers = trackersMap.map((key, value) => 
          MapEntry(key, DecayTrackerModel.fromMap(Map<String, dynamic>.from(value)))
        );
      }
    } catch (e) {
      print('خطأ في تحميل تتبع الاضمحلال: $e');
      _decayTrackers = {};
    }
  }

  bool _isLessonFullyCompleted() {
    if (_currentLesson == null) return false;
    
    for (final block in _currentLesson!.blocks) {
      if (block.type == 'quiz' && !isBlockCompleted(block.id)) {
        return false;
      }
    }
    return true;
  }

  DecayTrackerModel? getDecayTracker(String blockId) {
    return _decayTrackers[blockId];
  }

  void reset() {
    _currentLesson = null;
    _currentBlockIndex = 0;
    _blockProgress = {};
    _decayTrackers = {};
    _lessonCompleted = false;
    _lastRewards = null;
    _errorMessage = null;
    notifyListeners();
  }
}
