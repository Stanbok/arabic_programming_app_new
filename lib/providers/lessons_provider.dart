import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_model.dart';
import '../models/path_model.dart';
import '../models/progress_model.dart';
import '../services/lessons_service.dart';
import 'auth_provider.dart';

// Service provider
final lessonsServiceProvider = Provider<LessonsService>((ref) {
  return LessonsService();
});

// Paths provider
final pathsProvider = FutureProvider<List<PathModel>>((ref) async {
  final service = ref.watch(lessonsServiceProvider);
  return service.getPaths();
});

// Current path provider
final currentPathProvider = StateProvider<PathModel?>((ref) => null);

// Lessons for current path
final lessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  final service = ref.watch(lessonsServiceProvider);
  final currentPath = ref.watch(currentPathProvider);

  if (currentPath == null) return [];
  return service.getLessonsForPath(currentPath.id);
});

// Progress for current path
final progressProvider =
    FutureProvider<Map<String, LessonProgress>>((ref) async {
  final service = ref.watch(lessonsServiceProvider);
  final currentPath = ref.watch(currentPathProvider);
  final user = ref.watch(currentUserProvider).value;

  if (currentPath == null || user == null) return {};
  return service.getProgressForPath(user.uid, currentPath.id);
});

// Current lesson provider
final currentLessonProvider = StateProvider<LessonModel?>((ref) => null);

// Lesson download state
final lessonDownloadingProvider = StateProvider<Set<String>>((ref) => {});

// Download lesson action
final downloadLessonProvider =
    FutureProvider.family<bool, String>((ref, lessonId) async {
  final service = ref.watch(lessonsServiceProvider);
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return false;

  // Mark as downloading
  final downloading = ref.read(lessonDownloadingProvider.notifier);
  downloading.state = {...downloading.state, lessonId};

  final result = await service.downloadLesson(lessonId, user.uid);

  // Remove from downloading
  downloading.state = downloading.state.where((id) => id != lessonId).toSet();

  // Refresh progress
  ref.invalidate(progressProvider);

  return result;
});

// Check if lesson is downloaded
final isLessonDownloadedProvider = Provider.family<bool, String>((ref, lessonId) {
  final service = ref.watch(lessonsServiceProvider);
  return service.isLessonDownloaded(lessonId);
});

// Downloaded lessons list
final downloadedLessonsProvider = Provider<List<LessonModel>>((ref) {
  final service = ref.watch(lessonsServiceProvider);
  return service.getDownloadedLessons();
});

// Computed: Path progress percentage
final pathProgressProvider = Provider<double>((ref) {
  final progress = ref.watch(progressProvider).value ?? {};
  final lessons = ref.watch(lessonsProvider).value ?? [];

  if (lessons.isEmpty) return 0.0;

  final completed =
      progress.values.where((p) => p.isCompleted).length;
  return completed / lessons.length;
});

// Computed: Completed lessons count
final completedLessonsCountProvider = Provider<int>((ref) {
  final progress = ref.watch(progressProvider).value ?? {};
  return progress.values.where((p) => p.isCompleted).length;
});

// Get lesson state (locked, available, downloaded, completed)
enum LessonState { locked, available, downloaded, completed }

final lessonStateProvider =
    Provider.family<LessonState, String>((ref, lessonId) {
  final progress = ref.watch(progressProvider).value ?? {};
  final lessons = ref.watch(lessonsProvider).value ?? [];
  final isDownloaded = ref.watch(isLessonDownloadedProvider(lessonId));

  final lessonProgress = progress[lessonId];

  // Check if completed
  if (lessonProgress?.isCompleted == true) {
    return LessonState.completed;
  }

  // Check if downloaded
  if (isDownloaded) {
    return LessonState.downloaded;
  }

  // Check if lesson is available (first lesson or previous is completed)
  final lessonIndex = lessons.indexWhere((l) => l.id == lessonId);
  if (lessonIndex == 0) {
    return LessonState.available;
  }

  if (lessonIndex > 0) {
    final previousLesson = lessons[lessonIndex - 1];
    final previousProgress = progress[previousLesson.id];
    if (previousProgress?.isCompleted == true) {
      return LessonState.available;
    }
  }

  return LessonState.locked;
});
