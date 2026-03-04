import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unit.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import '../../data/content_service.dart';
import '../../data/content_repository.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final svc = ref.read(contentServiceProvider);
  return ContentRepository(svc);
});

final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  final repo = ref.read(contentRepositoryProvider);
  return repo.getUnits();
});

final lessonsForUnitProvider = FutureProvider.family<List<Lesson>, String>((ref, unitId) async {
  final repo = ref.read(contentRepositoryProvider);
  return repo.getLessonsForUnit(unitId);
});

final quizForLessonProvider = FutureProvider.family<Quiz?, String>((ref, lessonId) async {
  final repo = ref.read(contentRepositoryProvider);
  return repo.getQuizForLesson(lessonId);
});

// helper provider for individual lesson lookup
final contentLessonProvider = FutureProvider.family<Lesson, String>((ref, lessonId) async {
  final repo = ref.read(contentRepositoryProvider);
  final lessons = await repo.getLessons();
  return lessons.firstWhere((l) => l.id == lessonId);
});
