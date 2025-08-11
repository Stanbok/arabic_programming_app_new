import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';
import '../models/lesson_model.dart';
import '../services/firebase_service.dart';

class AdminProvider with ChangeNotifier {
  static const String ADMIN_UID = 'FkRMLu7IC3WLSD6jzujnJ79elUO2';
  
  bool _isAdminMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<LessonModel> _lessons = [];
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _hasMoreLessons = true;

  bool get isAdminMode => _isAdminMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LessonModel> get lessons => _lessons;
  bool get hasMoreLessons => _hasMoreLessons;
  int get currentPage => _currentPage;

  bool get isAuthorizedAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == ADMIN_UID;
  }

  void toggleAdminMode() {
    if (isAuthorizedAdmin) {
      _isAdminMode = !_isAdminMode;
      if (_isAdminMode) {
        _loadLessons(refresh: true);
      }
      notifyListeners();
    }
  }

  void exitAdminMode() {
    _isAdminMode = false;
    _lessons.clear();
    _currentPage = 0;
    _hasMoreLessons = true;
    notifyListeners();
  }

  Future<void> _loadLessons({bool refresh = false}) async {
    if (!isAuthorizedAdmin) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _lessons.clear();
        _currentPage = 0;
        _hasMoreLessons = true;
      }

      Query query = FirebaseFirestore.instance
          .collection('lessons')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_currentPage > 0) {
        final lastDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .orderBy('createdAt', descending: true)
            .limit(_currentPage * _pageSize)
            .get();
        
        if (lastDoc.docs.isNotEmpty) {
          query = query.startAfterDocument(lastDoc.docs.last);
        }
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMoreLessons = false;
      } else {
        final newLessons = snapshot.docs
            .map((doc) => LessonModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        
        if (refresh) {
          _lessons = newLessons;
        } else {
          _lessons.addAll(newLessons);
        }
        
        _currentPage++;
        _hasMoreLessons = snapshot.docs.length == _pageSize;
      }

    } catch (e) {
      _setError('خطأ في تحميل الدروس: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreLessons() async {
    if (!_hasMoreLessons || _isLoading) return;
    await _loadLessons();
  }

  Future<bool> uploadLesson(LessonUploadModel lessonData) async {
    if (!isAuthorizedAdmin) return false;

    try {
      _setLoading(true);
      _clearError();

      final lessonId = FirebaseFirestore.instance.collection('lessons').doc().id;
      
      final lesson = LessonModel(
        id: lessonId,
        title: lessonData.title,
        description: lessonData.description,
        imageUrl: lessonData.imageUrl,
        level: lessonData.level,
        order: lessonData.order,
        xpReward: lessonData.xpReward,
        gemsReward: lessonData.gemsReward,
        slides: lessonData.slides.map((slide) => SlideModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: slide.title,
          content: slide.content,
          imageUrl: slide.imageUrl,
          codeExample: slide.codeExample,
          order: slide.order,
        )).toList(),
        quiz: lessonData.quiz.map((quiz) => QuizQuestionModel(
          question: quiz.question,
          options: quiz.options,
          correctAnswerIndex: quiz.correctAnswerIndex,
          explanation: quiz.explanation,
        )).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .set(lesson.toMap());

      // Refresh lessons list
      await _loadLessons(refresh: true);
      
      return true;
    } catch (e) {
      _setError('خطأ في رفع الدرس: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateLesson(String lessonId, LessonUploadModel lessonData) async {
    if (!isAuthorizedAdmin) return false;

    try {
      _setLoading(true);
      _clearError();

      final updateData = lessonData.toMap();
      updateData['updatedAt'] = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .update(updateData);

      // Refresh lessons list
      await _loadLessons(refresh: true);
      
      return true;
    } catch (e) {
      _setError('خطأ في تحديث الدرس: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteLesson(String lessonId) async {
    if (!isAuthorizedAdmin) return false;

    try {
      _setLoading(true);
      _clearError();

      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .delete();

      // Remove from local list
      _lessons.removeWhere((lesson) => lesson.id == lessonId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('خطأ في حذف الدرس: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleLessonPublishStatus(String lessonId, bool isPublished) async {
    if (!isAuthorizedAdmin) return false;

    try {
      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .update({
        'isPublished': isPublished,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _lessons.indexWhere((lesson) => lesson.id == lessonId);
      if (index != -1) {
        // Note: This is a simplified update. In a real app, you'd want to create a new LessonModel
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('خطأ في تحديث حالة النشر: ${e.toString()}');
      return false;
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
}
