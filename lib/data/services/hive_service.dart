import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../models/cached_lesson_model.dart';
import '../models/lesson_content_model.dart';

/// Service for managing Hive cache operations
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  Box<CachedLessonModel>? _cacheBox;

  Box<CachedLessonModel> get _box {
    _cacheBox ??= Hive.box<CachedLessonModel>(HiveBoxes.cachedLessons);
    return _cacheBox!;
  }

  /// Check if a lesson is cached
  bool isLessonCached(String lessonId) {
    return _box.containsKey(lessonId);
  }

  /// Get cached lesson content
  LessonContentModel? getCachedLessonContent(String lessonId) {
    final cached = _box.get(lessonId);
    if (cached == null) return null;

    try {
      final jsonMap = json.decode(cached.contentJson);
      return LessonContentModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Cache lesson content
  Future<void> cacheLessonContent({
    required String lessonId,
    required String pathId,
    required LessonContentModel content,
  }) async {
    final cached = CachedLessonModel(
      lessonId: lessonId,
      pathId: pathId,
      contentJson: json.encode(content.toJson()),
      cachedAt: DateTime.now(),
    );
    await _box.put(lessonId, cached);
  }

  /// Get all cached lesson IDs for a path
  List<String> getCachedLessonIdsForPath(String pathId) {
    return _box.values
        .where((cached) => cached.pathId == pathId)
        .map((cached) => cached.lessonId)
        .toList();
  }

  /// Delete cached lesson
  Future<void> deleteCachedLesson(String lessonId) async {
    await _box.delete(lessonId);
  }

  /// Delete all cached lessons for a path
  Future<void> deleteCachedLessonsForPath(String pathId) async {
    final keysToDelete = _box.values
        .where((cached) => cached.pathId == pathId)
        .map((cached) => cached.lessonId)
        .toList();
    
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  /// Clear all cached lessons
  Future<void> clearAllCache() async {
    await _box.clear();
  }

  /// Get total cache size (approximate)
  int getCacheSize() {
    int total = 0;
    for (final cached in _box.values) {
      total += cached.contentJson.length;
    }
    return total;
  }
}
