import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';
import '../models/progress_model.dart';

/// خدمة المزامنة في الخلفية
class SyncService {
  final FirestoreService _firestoreService;
  final ConnectivityService _connectivityService;
  final String _userId;

  SyncService({
    required FirestoreService firestoreService,
    required ConnectivityService connectivityService,
    required String userId,
  })  : _firestoreService = firestoreService,
        _connectivityService = connectivityService,
        _userId = userId;

  /// مزامنة التقدم المعلق
  Future<void> syncPendingProgress() async {
    if (!_connectivityService.isOnline) return;

    final queue = CacheService.getSyncQueue();
    if (queue.isEmpty) return;

    for (final lessonId in queue.toList()) {
      try {
        final progress = CacheService.getLocalProgress(lessonId);
        if (progress != null) {
          await _firestoreService.saveProgress(_userId, lessonId, progress);
          if (progress.completed) {
            await _firestoreService.incrementCompletedLessons(_userId);
          }
          await CacheService.removeFromSyncQueue(lessonId);
        }
      } catch (e) {
        debugPrint('فشل مزامنة التقدم للدرس $lessonId: $e');
      }
    }
  }

  /// جلب التقدم من الخادم ودمجه محلياً
  Future<void> pullServerProgress() async {
    if (!_connectivityService.isOnline) return;

    try {
      final serverProgress = await _firestoreService.getUserProgress(_userId);
      await CacheService.mergeProgress(serverProgress);
    } catch (e) {
      debugPrint('فشل جلب التقدم من الخادم: $e');
    }
  }

  /// التهيئة الأولى - جلب جميع البيانات
  Future<void> initialSync() async {
    if (!_connectivityService.isOnline) return;
    if (CacheService.isInitialSyncDone()) return;

    try {
      // جلب المسارات
      final paths = await _firestoreService.getPaths();
      await CacheService.cachePaths(paths);

      // جلب الدروس لكل مسار
      for (final path in paths) {
        final lessons = await _firestoreService.getLessonsForPath(path.id);
        await CacheService.cacheLessonsMetadata(path.id, lessons);
      }

      // جلب التقدم
      final progress = await _firestoreService.getUserProgress(_userId);
      await CacheService.mergeProgress(progress);

      await CacheService.markInitialSyncDone();
    } catch (e) {
      debugPrint('فشل التهيئة الأولى: $e');
    }
  }

  /// مزامنة كاملة (pull ثم push)
  Future<void> fullSync() async {
    await pullServerProgress();
    await syncPendingProgress();
  }
}
