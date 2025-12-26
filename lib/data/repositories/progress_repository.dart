import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../models/user_progress_model.dart';
import '../models/path_model.dart';
import '../models/lesson_model.dart';
import 'content_repository.dart';
import 'sync_repository.dart';

/// Lock state for lessons and paths
enum ContentLockState { locked, available, completed }

/// Repository for managing user progress
/// 
/// Local-first: All reads/writes go to Hive immediately.
/// Background sync: Triggers Supabase sync after writes (non-blocking).
class ProgressRepository {
  ProgressRepository._();
  static final ProgressRepository instance = ProgressRepository._();

  final _contentRepo = ContentRepository.instance;
  final _syncRepo = SyncRepository.instance;
  Box<UserProgressModel>? _progressBox;

  Box<UserProgressModel> get _box {
    _progressBox ??= Hive.box<UserProgressModel>(HiveBoxes.userProgress);
    return _progressBox!;
  }

  UserProgressModel get _progress {
    return _box.get(HiveKeys.progress) ?? UserProgressModel();
  }

  /// Get lock state for a path
  Future<ContentLockState> getPathLockState(PathModel path) async {
    final progress = _progress;

    // Check if path is completed
    if (progress.completedPathIds.contains(path.id)) {
      return ContentLockState.completed;
    }

    // First path is always available
    if (path.order == 1) {
      return ContentLockState.available;
    }

    // Check if previous path is completed
    final paths = await _contentRepo.getPaths();
    final previousPath = paths.where((p) => p.order == path.order - 1).firstOrNull;
    
    if (previousPath == null) {
      return ContentLockState.available;
    }

    if (progress.completedPathIds.contains(previousPath.id)) {
      return ContentLockState.available;
    }

    return ContentLockState.locked;
  }

  /// Get lock state for a lesson
  Future<ContentLockState> getLessonLockState(LessonModel lesson) async {
    final progress = _progress;

    // Check if lesson is completed
    if (progress.completedLessonIds.contains(lesson.id)) {
      return ContentLockState.completed;
    }

    // First lesson in a path is available if path is unlocked
    if (lesson.order == 1) {
      return ContentLockState.available;
    }

    // Check if previous lesson in same path is completed
    final lessons = await _contentRepo.getLessonsForPath(lesson.pathId);
    final previousLesson = lessons.where((l) => l.order == lesson.order - 1).firstOrNull;

    if (previousLesson == null) {
      return ContentLockState.available;
    }

    if (progress.completedLessonIds.contains(previousLesson.id)) {
      return ContentLockState.available;
    }

    return ContentLockState.locked;
  }

  /// Mark lesson as completed
  Future<void> completeLesson(String lessonId) async {
    final progress = _progress;
    if (!progress.completedLessonIds.contains(lessonId)) {
      final updatedList = [...progress.completedLessonIds, lessonId];
      final updated = progress.copyWith(
        completedLessonIds: updatedList,
        lastUpdated: DateTime.now(),
      );
      await _box.put(HiveKeys.progress, updated);
      
      _syncRepo.syncProgress(); // Fire and forget
    }
  }

  /// Mark path as completed
  Future<void> completePath(String pathId) async {
    final progress = _progress;
    if (!progress.completedPathIds.contains(pathId)) {
      final updatedList = [...progress.completedPathIds, pathId];
      final updated = progress.copyWith(
        completedPathIds: updatedList,
        lastUpdated: DateTime.now(),
      );
      await _box.put(HiveKeys.progress, updated);
      
      _syncRepo.syncProgress(); // Fire and forget
    }
  }

  /// Check if all lessons in a path are completed
  Future<bool> areAllLessonsCompleted(String pathId) async {
    final lessons = await _contentRepo.getLessonsForPath(pathId);
    final progress = _progress;
    
    for (final lesson in lessons) {
      if (!progress.completedLessonIds.contains(lesson.id)) {
        return false;
      }
    }
    return true;
  }

  /// Get progress percentage for a path
  Future<double> getPathProgressPercentage(String pathId) async {
    final lessons = await _contentRepo.getLessonsForPath(pathId);
    if (lessons.isEmpty) return 0.0;

    final progress = _progress;
    int completed = 0;
    
    for (final lesson in lessons) {
      if (progress.completedLessonIds.contains(lesson.id)) {
        completed++;
      }
    }
    
    return completed / lessons.length;
  }

  /// Set current lesson position
  Future<void> setCurrentPosition({
    required String pathId,
    required String lessonId,
    int cardIndex = 0,
  }) async {
    final progress = _progress;
    final updated = progress.copyWith(
      currentPathId: pathId,
      currentLessonId: lessonId,
      currentCardIndex: cardIndex,
      lastUpdated: DateTime.now(),
    );
    await _box.put(HiveKeys.progress, updated);
    
    _syncRepo.syncProgress(); // Fire and forget
  }

  /// Update current card index
  Future<void> updateCardIndex(int cardIndex) async {
    final progress = _progress;
    final updated = progress.copyWith(
      currentCardIndex: cardIndex,
      lastUpdated: DateTime.now(),
    );
    await _box.put(HiveKeys.progress, updated);
    // Note: Don't sync on every card index change to reduce API calls
  }

  /// Get current position
  ({String? pathId, String? lessonId, int cardIndex}) getCurrentPosition() {
    final progress = _progress;
    return (
      pathId: progress.currentPathId,
      lessonId: progress.currentLessonId,
      cardIndex: progress.currentCardIndex ?? 0,
    );
  }

  /// Get total completed lessons count
  int getCompletedLessonsCount() {
    return _progress.completedLessonIds.length;
  }

  /// Get total completed paths count
  int getCompletedPathsCount() {
    return _progress.completedPathIds.length;
  }

  /// Reset all progress
  Future<void> resetProgress() async {
    await _box.delete(HiveKeys.progress);
    
    _syncRepo.syncProgress(); // Fire and forget
  }

  /// Fetch and merge progress from Supabase (called on app start)
  Future<void> fetchAndMergeFromCloud() async {
    await _syncRepo.fetchAndMergeProgress();
  }
}
