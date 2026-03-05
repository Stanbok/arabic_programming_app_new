import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/path_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/lesson_content_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/services/content_update_service.dart';

/// Provider for all paths
final pathsProvider = FutureProvider<List<PathModel>>((ref) async {
  return ContentRepository.instance.getPaths();
});

/// Provider for lessons in a specific path
final lessonsProvider = FutureProvider.family<List<LessonModel>, String>((ref, pathId) async {
  return ContentRepository.instance.getLessonsForPath(pathId);
});

final lessonsForPathProvider = lessonsProvider;

/// Provider for lesson content
final lessonContentProvider = FutureProvider.family<LessonContentModel?, ({String lessonId, String pathId})>((ref, params) async {
  return ContentRepository.instance.getLessonContent(params.lessonId, params.pathId);
});

/// Provider for path lock states
final pathLockStateProvider = FutureProvider.family<ContentLockState, PathModel>((ref, path) async {
  return ProgressRepository.instance.getPathLockState(path);
});

/// Provider for lesson lock states
final lessonLockStateProvider = FutureProvider.family<ContentLockState, LessonModel>((ref, lesson) async {
  return ProgressRepository.instance.getLessonLockState(lesson);
});

/// Provider for path progress percentage
final pathProgressProvider = FutureProvider.family<double, String>((ref, pathId) async {
  return ProgressRepository.instance.getPathProgressPercentage(pathId);
});

/// Provider for path download status
final pathDownloadStatusProvider = FutureProvider.family<(int, int), String>((ref, pathId) async {
  return ContentRepository.instance.getPathDownloadStatus(pathId);
});

/// Provider to check if lesson is available offline
final lessonOfflineAvailableProvider = Provider.family<bool, ({String lessonId, String pathId})>((ref, params) {
  return ContentRepository.instance.isLessonAvailableOffline(params.lessonId, params.pathId);
});

// ===== UPDATE PROVIDERS =====

/// Provider to check if there's a pending update notification
final hasUpdateNotificationProvider = Provider<bool>((ref) {
  return ContentUpdateService.instance.hasPendingUpdateNotification();
});

/// Provider for pending update message
final updateMessageProvider = Provider<String?>((ref) {
  return ContentUpdateService.instance.getPendingUpdateMessage();
});

/// State notifier for update notification visibility
class UpdateNotificationNotifier extends StateNotifier<bool> {
  UpdateNotificationNotifier() : super(ContentUpdateService.instance.hasPendingUpdateNotification());

  void dismiss() {
    ContentUpdateService.instance.dismissUpdateNotification();
    state = false;
  }

  void refresh() {
    state = ContentUpdateService.instance.hasPendingUpdateNotification();
  }
}

final updateNotificationProvider = StateNotifierProvider<UpdateNotificationNotifier, bool>((ref) {
  return UpdateNotificationNotifier();
});
