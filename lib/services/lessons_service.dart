import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';
import '../models/path_model.dart';
import '../models/progress_model.dart';
import '../core/constants/hive_boxes.dart';
import '../core/utils/app_exceptions.dart';

class LessonsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all paths
  Future<List<PathModel>> getPaths() async {
    try {
      final snapshot = await _firestore
          .collection('paths')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => PathModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Try to get from cache if offline
      try {
        final snapshot = await _firestore
            .collection('paths')
            .orderBy('order')
            .get(const GetOptions(source: Source.cache));

        return snapshot.docs
            .map((doc) => PathModel.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (_) {
        throw const NetworkException('فشل تحميل المسارات');
      }
    }
  }

  // Fetch lessons for a path
  Future<List<LessonModel>> getLessonsForPath(String pathId) async {
    try {
      final snapshot = await _firestore
          .collection('lessons')
          .where('pathId', isEqualTo: pathId)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Try cache if offline
      try {
        final snapshot = await _firestore
            .collection('lessons')
            .where('pathId', isEqualTo: pathId)
            .orderBy('order')
            .get(const GetOptions(source: Source.cache));

        return snapshot.docs
            .map((doc) => LessonModel.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (_) {
        throw const NetworkException('فشل تحميل الدروس');
      }
    }
  }

  // Get single lesson (from Hive if downloaded, else Firestore)
  Future<LessonModel?> getLesson(String lessonId) async {
    // Check Hive first
    final box = Hive.box<LessonModel>(HiveBoxes.cachedLessons);
    final cachedLesson = box.get(lessonId);
    if (cachedLesson != null) {
      return cachedLesson;
    }

    // Fetch from Firestore
    try {
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (doc.exists) {
        return LessonModel.fromFirestore(doc.data()!, doc.id);
      }
      throw LessonException.notFound();
    } catch (e) {
      if (e is LessonException) rethrow;
      throw const NetworkException('فشل تحميل الدرس');
    }
  }

  // Download lesson to Hive
  Future<bool> downloadLesson(String lessonId, String userId) async {
    try {
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!doc.exists) {
        throw LessonException.notFound();
      }

      final lesson = LessonModel.fromFirestore(doc.data()!, doc.id);

      // Save to Hive
      final box = Hive.box<LessonModel>(HiveBoxes.cachedLessons);
      await box.put(lessonId, lesson);

      // Record download in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('downloads')
          .doc(lessonId)
          .set({
        'lessonId': lessonId,
        'downloadedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (e is LessonException) rethrow;
      throw LessonException.downloadFailed();
    }
  }

  // Check if lesson is downloaded
  bool isLessonDownloaded(String lessonId) {
    final box = Hive.box<LessonModel>(HiveBoxes.cachedLessons);
    return box.containsKey(lessonId);
  }

  // Get user progress for a path
  Future<Map<String, LessonProgress>> getProgressForPath(
      String userId, String pathId) async {
    // Get from Hive first
    final progressBox = Hive.box<LessonProgress>(HiveBoxes.progress);
    final localProgress = <String, LessonProgress>{};

    for (final key in progressBox.keys) {
      final progress = progressBox.get(key);
      if (progress != null) {
        localProgress[progress.lessonId] = progress;
      }
    }

    // Try to sync with Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .where('pathId', isEqualTo: pathId)
          .get();

      for (final doc in snapshot.docs) {
        final progress = LessonProgress.fromFirestore(doc.data());
        localProgress[progress.lessonId] = progress;
        // Update local cache
        await progressBox.put(progress.lessonId, progress);
      }
    } catch (e) {
      // Use local data if offline - don't throw
    }

    return localProgress;
  }

  // Save lesson progress
  Future<void> saveProgress(String userId, LessonProgress progress) async {
    // Save to Hive immediately
    final box = Hive.box<LessonProgress>(HiveBoxes.progress);
    await box.put(progress.lessonId, progress);

    // Sync to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(progress.lessonId)
          .set(progress.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Will sync when online via Firestore persistence
    }
  }

  Future<void> updateLessonProgress({
    required String lessonId,
    required bool completed,
    required int lastCardIndex,
  }) async {
    try {
      final progressBox = Hive.box<LessonProgress>(HiveBoxes.progress);
      final existingProgress = progressBox.get(lessonId);
      
      final updatedProgress = LessonProgress(
        lessonId: lessonId,
        isCompleted: completed,
        isDownloaded: existingProgress?.isDownloaded ?? isLessonDownloaded(lessonId),
        quizScore: existingProgress?.quizScore ?? 0,
        totalQuestions: existingProgress?.totalQuestions ?? 0,
        lastCardIndex: lastCardIndex,
        completedAt: completed ? DateTime.now() : existingProgress?.completedAt,
      );
      
      await progressBox.put(lessonId, updatedProgress);
    } catch (e) {
      throw LessonException.progressSaveFailed();
    }
  }

  // Mark lesson as complete
  Future<void> completeLesson(
    String userId,
    String lessonId,
    int score,
    int totalQuestions,
  ) async {
    final progress = LessonProgress(
      lessonId: lessonId,
      isCompleted: true,
      isDownloaded: isLessonDownloaded(lessonId),
      quizScore: score,
      totalQuestions: totalQuestions,
      completedAt: DateTime.now(),
    );

    await saveProgress(userId, progress);

    // Update user stats
    try {
      await _firestore.collection('users').doc(userId).update({
        'stats.lessonsCompleted': FieldValue.increment(1),
        'stats.questionsAnswered': FieldValue.increment(totalQuestions),
        'stats.correctAnswers': FieldValue.increment(score),
      });
    } catch (e) {
      // Will sync later
    }
  }

  // Get downloaded lessons list
  List<LessonModel> getDownloadedLessons() {
    final box = Hive.box<LessonModel>(HiveBoxes.cachedLessons);
    return box.values.toList();
  }

  // Delete downloaded lesson
  Future<void> deleteDownloadedLesson(String lessonId) async {
    final box = Hive.box<LessonModel>(HiveBoxes.cachedLessons);
    await box.delete(lessonId);
  }
}
