import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';
import '../models/path_model.dart';
import '../models/progress_model.dart';

class CacheService {
  static late Box<String> _lessonsBox;
  static late Box<Uint8List> _imagesBox;
  static late Box<String> _progressBox;
  static late Box<String> _pathsBox;
  static late Box<String> _metadataBox;
  static late Box<String> _userBox;
  static late Box<String> _syncBox;

  static Future<void> init() async {
    _lessonsBox = await Hive.openBox<String>('cached_lessons');
    _imagesBox = await Hive.openBox<Uint8List>('cached_images');
    _progressBox = await Hive.openBox<String>('lesson_progress');
    _pathsBox = await Hive.openBox<String>('cached_paths');
    _metadataBox = await Hive.openBox<String>('lessons_metadata');
    _userBox = await Hive.openBox<String>('user_data');
    _syncBox = await Hive.openBox<String>('sync_queue');
  }

  // ==================== المسارات ====================
  
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

  // ==================== البيانات الوصفية للدروس (بدون المحتوى) ====================
  
  static Future<void> cacheLessonsMetadata(String pathId, List<LessonModel> lessons) async {
    final metadataList = lessons.map((l) => {
      'id': l.id,
      'pathId': l.pathId,
      'title': l.title,
      'orderIndex': l.orderIndex,
      'thumbnailUrl': l.thumbnailUrl,
      'cardsCount': l.cards.length,
      'quizCount': l.quiz.length,
      'xpReward': l.xpReward,
      'gemsReward': l.gemsReward,
    }).toList();
    await _metadataBox.put('metadata_$pathId', jsonEncode(metadataList));
  }

  static List<LessonModel>? getCachedLessonsMetadata(String pathId) {
    final data = _metadataBox.get('metadata_$pathId');
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((map) {
      return LessonModel(
        id: map['id'] ?? '',
        pathId: map['pathId'] ?? '',
        title: map['title'] ?? '',
        orderIndex: map['orderIndex'] ?? 0,
        thumbnailUrl: map['thumbnailUrl'] ?? '',
        cards: [],
        quiz: [],
        xpReward: map['xpReward'] ?? 300,
        gemsReward: map['gemsReward'] ?? 5,
      );
    }).toList();
  }

  static bool hasLessonsMetadata(String pathId) {
    return _metadataBox.containsKey('metadata_$pathId');
  }

  // ==================== المحتوى الكامل للدرس ====================
  
  static Future<void> cacheFullLesson(LessonModel lesson) async {
    await _lessonsBox.put('full_${lesson.id}', jsonEncode(lesson.toMap()));
  }

  static LessonModel? getCachedFullLesson(String lessonId) {
    final data = _lessonsBox.get('full_$lessonId');
    if (data == null) return null;
    return LessonModel.fromMap(jsonDecode(data), lessonId);
  }

  static bool isLessonContentCached(String lessonId) {
    return _lessonsBox.containsKey('full_$lessonId');
  }

  // للتوافق مع الكود القديم
  static Future<void> cacheLesson(LessonModel lesson) => cacheFullLesson(lesson);
  static LessonModel? getCachedLesson(String lessonId) => getCachedFullLesson(lessonId);
  static bool isLessonCached(String lessonId) => isLessonContentCached(lessonId);

  // ==================== التقدم (Offline-First) ====================
  
  static Future<void> saveLocalProgress(String lessonId, ProgressModel progress) async {
    await _progressBox.put('progress_$lessonId', jsonEncode(progress.toMap()));
    // إضافة للطابور للمزامنة لاحقاً
    await _addToSyncQueue(lessonId);
  }

  static ProgressModel? getLocalProgress(String lessonId) {
    final data = _progressBox.get('progress_$lessonId');
    if (data == null) return null;
    return ProgressModel.fromMap(jsonDecode(data), lessonId);
  }

  static Map<String, ProgressModel> getAllLocalProgress() {
    final Map<String, ProgressModel> progress = {};
    for (final key in _progressBox.keys) {
      if (key.toString().startsWith('progress_')) {
        final lessonId = key.toString().replaceFirst('progress_', '');
        final data = _progressBox.get(key);
        if (data != null) {
          progress[lessonId] = ProgressModel.fromMap(jsonDecode(data), lessonId);
        }
      }
    }
    return progress;
  }

  static bool isLessonCompleted(String lessonId) {
    final progress = getLocalProgress(lessonId);
    return progress?.completed ?? false;
  }

  static Future<void> mergeProgress(Map<String, ProgressModel> serverProgress) async {
    final localProgress = getAllLocalProgress();
    
    for (final entry in serverProgress.entries) {
      final local = localProgress[entry.key];
      // إذا الخادم يحتوي على تقدم غير موجود محلياً أو أحدث
      if (local == null || 
          (entry.value.completed && !local.completed) ||
          (entry.value.completedAt != null && 
           local.completedAt != null && 
           entry.value.completedAt!.isAfter(local.completedAt!))) {
        await _progressBox.put('progress_${entry.key}', jsonEncode(entry.value.toMap()));
      }
    }
  }

  // ==================== طابور المزامنة ====================
  
  static Future<void> _addToSyncQueue(String lessonId) async {
    final queue = getSyncQueue();
    if (!queue.contains(lessonId)) {
      queue.add(lessonId);
      await _syncBox.put('pending_sync', jsonEncode(queue));
    }
  }

  static List<String> getSyncQueue() {
    final data = _syncBox.get('pending_sync');
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }

  static Future<void> removeFromSyncQueue(String lessonId) async {
    final queue = getSyncQueue();
    queue.remove(lessonId);
    await _syncBox.put('pending_sync', jsonEncode(queue));
  }

  static Future<void> clearSyncQueue() async {
    await _syncBox.delete('pending_sync');
  }

  // ==================== آخر مسار ====================
  
  static Future<void> saveLastPathIndex(int index) async {
    await _userBox.put('last_path_index', index.toString());
  }

  static int getLastPathIndex() {
    final data = _userBox.get('last_path_index');
    return data != null ? int.tryParse(data) ?? 0 : 0;
  }

  // ==================== علامة التهيئة الأولى ====================
  
  static Future<void> markInitialSyncDone() async {
    await _userBox.put('initial_sync_done', 'true');
  }

  static bool isInitialSyncDone() {
    return _userBox.get('initial_sync_done') == 'true';
  }

  // ==================== الصور ====================
  
  static Future<void> cacheImage(String url, Uint8List bytes) async {
    await _imagesBox.put(url, bytes);
  }

  static Uint8List? getCachedImage(String url) {
    return _imagesBox.get(url);
  }

  static bool isImageCached(String url) {
    return _imagesBox.containsKey(url);
  }

  // ==================== موضع الدرس ====================
  
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

  // ==================== مسح الكاش ====================
  
  static Future<void> clearAll() async {
    await _lessonsBox.clear();
    await _imagesBox.clear();
    await _progressBox.clear();
    await _pathsBox.clear();
    await _metadataBox.clear();
    await _userBox.clear();
    await _syncBox.clear();
  }

  // ==================== للتوافق ====================
  
  static Future<void> cacheLessonsForPath(String pathId, List<LessonModel> lessons) => 
      cacheLessonsMetadata(pathId, lessons);
  static List<LessonModel>? getCachedLessonsForPath(String pathId) => 
      getCachedLessonsMetadata(pathId);
  static bool hasLessonsForPath(String pathId) => 
      hasLessonsMetadata(pathId);
}
