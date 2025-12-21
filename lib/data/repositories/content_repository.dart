import '../models/path_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_content_model.dart';
import '../services/asset_loader_service.dart';
import '../services/hive_service.dart';
import '../services/firebase_storage_service.dart';
import '../../core/constants/app_constants.dart';

/// Repository for accessing learning content
class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  final _assetLoader = AssetLoaderService.instance;
  final _hiveService = HiveService.instance;
  final _storageService = FirebaseStorageService.instance;

  /// Get all paths
  Future<List<PathModel>> getPaths() async {
    return _assetLoader.loadPaths();
  }

  /// Get a specific path by ID
  Future<PathModel?> getPath(String pathId) async {
    final paths = await getPaths();
    try {
      return paths.firstWhere((p) => p.id == pathId);
    } catch (e) {
      return null;
    }
  }

  /// Get lessons for a path
  Future<List<LessonModel>> getLessonsForPath(String pathId) async {
    return _assetLoader.loadLessonsForPath(pathId);
  }

  /// Get a specific lesson by ID
  Future<LessonModel?> getLesson(String pathId, String lessonId) async {
    final lessons = await getLessonsForPath(pathId);
    try {
      return lessons.firstWhere((l) => l.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  /// Get lesson content
  /// - For Path 1: Loads from bundled assets
  /// - For Path 2+: Loads from Hive cache
  Future<LessonContentModel?> getLessonContent(String lessonId, String pathId) async {
    // Check if it's a bundled lesson (Path 1)
    if (pathId == AppConstants.path1Id) {
      return _assetLoader.loadBundledLessonContent(lessonId);
    }

    // For Path 2+, check cache
    return _hiveService.getCachedLessonContent(lessonId);
  }

  /// Check if lesson content is available offline
  bool isLessonAvailableOffline(String lessonId, String pathId) {
    if (pathId == AppConstants.path1Id) {
      return true; // Path 1 is always available
    }
    return _hiveService.isLessonCached(lessonId);
  }

  /// Cache lesson content (for Path 2+)
  Future<void> cacheLessonContent({
    required String lessonId,
    required String pathId,
    required LessonContentModel content,
  }) async {
    await _hiveService.cacheLessonContent(
      lessonId: lessonId,
      pathId: pathId,
      content: content,
    );
  }

  /// Get download status for a path
  /// Returns: (downloaded count, total count)
  Future<(int, int)> getPathDownloadStatus(String pathId) async {
    if (pathId == AppConstants.path1Id) {
      final lessons = await getLessonsForPath(pathId);
      return (lessons.length, lessons.length); // All downloaded
    }

    final lessons = await getLessonsForPath(pathId);
    final cachedIds = _hiveService.getCachedLessonIdsForPath(pathId);
    return (cachedIds.length, lessons.length);
  }

  /// Check if all lessons in a path are downloaded
  Future<bool> isPathFullyDownloaded(String pathId) async {
    final (downloaded, total) = await getPathDownloadStatus(pathId);
    return downloaded == total;
  }

  /// Download a single lesson from Firebase Storage and cache it
  /// Returns the downloaded content or null if failed
  Future<LessonContentModel?> downloadAndCacheLesson({
    required String lessonId,
    required String pathId,
  }) async {
    // Download from Firebase Storage
    final content = await _storageService.downloadLessonContent(
      lessonId: lessonId,
      pathId: pathId,
    );

    if (content == null) return null;

    // Cache in Hive
    await _hiveService.cacheLessonContent(
      lessonId: lessonId,
      pathId: pathId,
      content: content,
    );

    return content;
  }

  /// Download all lessons for a path from Firebase Storage
  /// Returns count of successfully downloaded lessons
  Future<int> downloadAllLessonsForPath({
    required String pathId,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    // Get lesson IDs for this path
    final lessons = await getLessonsForPath(pathId);
    final lessonIds = lessons.map((l) => l.id).toList();
    
    // Filter out already cached lessons
    final uncachedIds = lessonIds.where(
      (id) => !_hiveService.isLessonCached(id)
    ).toList();

    if (uncachedIds.isEmpty) {
      onProgress?.call(lessonIds.length, lessonIds.length);
      return lessonIds.length;
    }

    int downloadedCount = lessonIds.length - uncachedIds.length;

    // Download uncached lessons
    final downloaded = await _storageService.downloadAllLessonsForPath(
      pathId: pathId,
      lessonIds: uncachedIds,
      onProgress: (current, total) {
        onProgress?.call(downloadedCount + current, lessonIds.length);
      },
    );

    // Cache downloaded content
    for (final entry in downloaded.entries) {
      await _hiveService.cacheLessonContent(
        lessonId: entry.key,
        pathId: pathId,
        content: entry.value,
      );
      downloadedCount++;
    }

    return downloadedCount;
  }
}
