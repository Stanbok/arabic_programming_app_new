import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_result_model.dart';

class LessonProvider with ChangeNotifier {
  List<LessonModel> _lessons = [];
  LessonModel? _currentLesson;
  ProgressModel? _currentProgress;
  bool _isLoading = false;
  String? _errorMessage;

  List<LessonModel> get lessons => _lessons;
  LessonModel? get currentLesson => _currentLesson;
  ProgressModel? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLessons({int? level}) async {
    try {
      _setLoading(true);
      _clearError();
      
      _lessons = await FirebaseService.getLessons(level: level);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _currentLesson = await FirebaseService.getLesson(lessonId);
      _currentProgress = await FirebaseService.getLessonProgress(userId, lessonId);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeSlide(String userId, String lessonId, String slideId) async {
    if (_currentProgress == null) {
      _currentProgress = ProgressModel(lessonId: lessonId);
    }

    try {
      final updatedSlidesCompleted = List<String>.from(_currentProgress!.slidesCompleted);
      if (!updatedSlidesCompleted.contains(slideId)) {
        updatedSlidesCompleted.add(slideId);
        
        _currentProgress = _currentProgress!.copyWith(
          slidesCompleted: updatedSlidesCompleted,
        );
        
        await FirebaseService.updateLessonProgress(userId, lessonId, _currentProgress!);
        
        // Award XP for completing slide
        await FirebaseService.addXPAndGems(userId, 10, 1, 'إكمال شريحة');
        
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> completeLesson(String userId, String lessonId) async {
    if (_currentLesson == null) return;

    try {
      final completedProgress = _currentProgress?.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      ) ?? ProgressModel(
        lessonId: lessonId,
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      await FirebaseService.updateLessonProgress(userId, lessonId, completedProgress);
      
      // Update user's completed lessons
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      });
      
      // Award XP and gems for completing lesson
      await FirebaseService.addXPAndGems(
        userId, 
        _currentLesson!.xpReward, 
        _currentLesson!.gemsReward, 
        'إكمال درس: ${_currentLesson!.title}'
      );
      
      _currentProgress = completedProgress;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> saveQuizResult(String userId, String lessonId, QuizResultModel result) async {
    try {
      await FirebaseService.saveQuizResult(userId, lessonId, result);
      
      // Award XP and gems based on quiz performance
      int xpReward = 100;
      int gemsReward = 5;
      
      if (result.score >= 90) {
        xpReward += 50; // Bonus for excellent performance
        gemsReward += 3;
      } else if (result.score >= 80) {
        xpReward += 25;
        gemsReward += 2;
      }
      
      await FirebaseService.addXPAndGems(
        userId, 
        xpReward, 
        gemsReward, 
        'إكمال اختبار: ${result.score}%'
      );
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  List<LessonModel> getAvailableLessons(List<String> completedLessons, int currentLevel) {
    return _lessons.where((lesson) {
      // Show current level lessons and next level if current is completed
      if (lesson.level == currentLevel) return true;
      if (lesson.level == currentLevel + 1) {
        // Check if current level is completed
        final currentLevelLessons = _lessons.where((l) => l.level == currentLevel).toList();
        final completedCurrentLevel = currentLevelLessons.every((l) => completedLessons.contains(l.id));
        return completedCurrentLevel;
      }
      return false;
    }).toList();
  }

  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final lesson = await FirebaseService.getLesson(lessonId);
      return lesson;
    } catch (e) {
      _setError(e.toString());
      return null;
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
}
