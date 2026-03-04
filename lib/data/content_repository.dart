import 'package:flutter/foundation.dart';

import 'content_service.dart';
import '../core/models/unit.dart';
import '../core/models/lesson.dart';
import '../core/models/quiz.dart';

/// Lightweight repository that currently reads from bundled assets via ContentService,
/// but provides an in-memory cache and a single place to swap in remote fetching later.
class ContentRepository {
  final ContentService _service;

  List<Unit>? _unitsCache;
  List<Lesson>? _lessonsCache;
  List<Quiz>? _quizzesCache;

  ContentRepository(this._service);

  Future<List<Unit>> getUnits({bool forceRefresh = false}) async {
    if (!forceRefresh && _unitsCache != null) return _unitsCache!;
    _unitsCache = await _service.loadUnits();
    return _unitsCache!;
  }

  Future<List<Lesson>> getLessons({bool forceRefresh = false}) async {
    if (!forceRefresh && _lessonsCache != null) return _lessonsCache!;
    _lessonsCache = await _service.loadLessons();
    return _lessonsCache!;
  }

  Future<List<Quiz>> getQuizzes({bool forceRefresh = false}) async {
    if (!forceRefresh && _quizzesCache != null) return _quizzesCache!;
    _quizzesCache = await _service.loadQuizzes();
    return _quizzesCache!;
  }

  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    final lessons = await getLessons();
    return lessons.where((l) => l.unitId == unitId).toList();
  }

  Future<Quiz?> getQuizForLesson(String lessonId) async {
    final quizzes = await getQuizzes();
    return quizzes.firstWhere((q) => q.lessonId == lessonId, orElse: () => null);
  }
}
