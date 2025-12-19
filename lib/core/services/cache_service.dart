import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';
import '../models/path_model.dart';

class CacheService {
  static late Box<String> _lessonsBox;
  static late Box<Uint8List> _imagesBox;
  static late Box<String> _progressBox;
  static late Box<String> _pathsBox;

  static Future<void> init() async {
    _lessonsBox = await Hive.openBox<String>('cached_lessons');
    _imagesBox = await Hive.openBox<Uint8List>('cached_images');
    _progressBox = await Hive.openBox<String>('lesson_progress');
    _pathsBox = await Hive.openBox<String>('cached_paths');
  }

  // Lesson caching
  static Future<void> cacheLesson(LessonModel lesson) async {
    await _lessonsBox.put(lesson.id, jsonEncode(lesson.toMap()));
  }

  static LessonModel? getCachedLesson(String lessonId) {
    final data = _lessonsBox.get(lessonId);
    if (data == null) return null;
    return LessonModel.fromMap(jsonDecode(data), lessonId);
  }

  static bool isLessonCached(String lessonId) {
    return _lessonsBox.containsKey(lessonId);
  }

  static List<String> getCachedLessonIds() {
    return _lessonsBox.keys.cast<String>().toList();
  }

  static Future<void> cacheLessonsForPath(String pathId, List<LessonModel> lessons) async {
    final lessonsData = lessons.map((l) => l.toMap()).toList();
    await _lessonsBox.put('path_lessons_$pathId', jsonEncode(lessonsData));
  }

  static List<LessonModel>? getCachedLessonsForPath(String pathId) {
    final data = _lessonsBox.get('path_lessons_$pathId');
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.asMap().entries.map((e) {
      final map = e.value as Map<String, dynamic>;
      return LessonModel.fromMap(map, map['id'] ?? 'lesson_${e.key}');
    }).toList();
  }

  static bool hasLessonsForPath(String pathId) {
    return _lessonsBox.containsKey('path_lessons_$pathId');
  }

  static Future<void> cachePaths(List<PathModel> paths) async {
    final pathsData = paths.map((p) => p.toMap()).toList();
    await _pathsBox.put('all_paths', jsonEncode(pathsData));
  }

  static List<PathModel>? getCachedPaths() {
    final data = _pathsBox.get('all_paths');
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.asMap().entries.map((e) {
      final map = e.value as Map<String, dynamic>;
      return PathModel.fromMap(map, map['id'] ?? 'path_${e.key}');
    }).toList();
  }

  static bool hasCachedPaths() {
    return _pathsBox.containsKey('all_paths');
  }

  // Image caching
  static Future<void> cacheImage(String url, Uint8List bytes) async {
    await _imagesBox.put(url, bytes);
  }

  static Uint8List? getCachedImage(String url) {
    return _imagesBox.get(url);
  }

  static bool isImageCached(String url) {
    return _imagesBox.containsKey(url);
  }

  // Lesson progress tracking (position in lesson)
  static Future<void> saveLessonPosition(String lessonId, int cardIndex) async {
    await _progressBox.put('position_$lessonId', cardIndex.toString());
  }

  static int? getLessonPosition(String lessonId) {
    final position = _progressBox.get('position_$lessonId');
    return position != null ? int.tryParse(position) : null;
  }

  static Future<void> clearLessonPosition(String lessonId) async {
    await _progressBox.delete('position_$lessonId');
  }

  // Clear all cache
  static Future<void> clearAll() async {
    await _lessonsBox.clear();
    await _imagesBox.clear();
    await _progressBox.clear();
    await _pathsBox.clear();
  }
}
