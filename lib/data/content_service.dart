import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/models/unit.dart';
import '../core/models/lesson.dart';
import '../core/models/quiz.dart';

class ContentService {
  Future<List<Unit>> loadUnits() async {
    final jsonStr = await rootBundle.loadString('assets/content/units.json');
    final List data = json.decode(jsonStr);
    return data.map((e) => Unit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Lesson>> loadLessons() async {
    final jsonStr = await rootBundle.loadString('assets/content/lessons.json');
    final List data = json.decode(jsonStr);
    return data.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Quiz>> loadQuizzes() async {
    final jsonStr = await rootBundle.loadString('assets/content/quizzes.json');
    final List data = json.decode(jsonStr);
    return data.map((e) => Quiz.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// convenience helpers
  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    final lessons = await loadLessons();
    return lessons.where((l) => l.unitId == unitId).toList();
  }

  Future<Quiz?> getQuizForLesson(String lessonId) async {
    final quizzes = await loadQuizzes();
    return quizzes.firstWhere((q) => q.lessonId == lessonId, orElse: () => null);
  }
}
