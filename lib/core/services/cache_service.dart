import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';

class CacheService {
  static late Box<String> _lessonsBox;
  static late Box<Uint8List> _imagesBox;
  static late Box<String> _progressBox;

  static Future<void> init() async {
    _lessonsBox = await Hive.openBox<String>('cached_lessons');
    _imagesBox = await Hive.openBox<Uint8List>('cached_images');
    _progressBox = await Hive.openBox<String>('lesson_progress');
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
  }
}
