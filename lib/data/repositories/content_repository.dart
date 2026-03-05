import '../models/path_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_content_model.dart';
import '../services/asset_loader_service.dart';
import '../services/hive_service.dart';
import '../services/supabase_storage_service.dart';
import '../../core/constants/app_constants.dart';
import 'manifest_repository.dart';

/// Repository for accessing learning content
/// 
/// Refactored to use ManifestRepository for hierarchical content loading.
/// Maintains backward compatibility with existing interface.
/// 
/// Content Loading Priority:
/// 1. Bundled assets (Path 1 lesson content)
/// 2. Hive cache (downloaded lesson content)
/// 3. On-demand download from Supabase (if online)
class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  final _manifestRepo = ManifestRepository.instance;
  final _assetLoader = AssetLoaderService.instance;
  final _hiveService = HiveService.instance;
  final _storageService = SupabaseStorageService.instance;

  /// Get all paths (from manifests or bundled assets)
  Future<List<PathModel>> getPaths() async {
    return _manifestRepo.getPaths();
  }

  /// Get a specific path by ID
  Future<PathModel?> getPath(String pathId) async {
    return _manifestRepo.getPath(pathId);
  }

  /// Get lessons for a path (from manifests or bundled assets)
  Future<List<LessonModel>> getLessonsForPath(String pathId) async {
    return _manifestRepo.getLessonsForPath(pathId);
  }

  /// Get a specific lesson by ID
  Future<LessonModel?> getLesson(String pathId, String lessonId) async {
    return _manifestRepo.getLesson(pathId, lessonId);
  }

  /// Get lesson content
  /// Priority:
  /// 1. Bundled assets (Path 1)
  /// 2. Hive cache
  /// 3. On-demand download (if contentUrl available)
  Future<LessonContentModel?> getLessonContent(String lessonId, String pathId) async {
    // For bundled Path 1, always load from assets
    if (pathId == AppConstants.path1Id) {
      final bundledContent = await _assetLoader.loadBundledLessonContent(lessonId);
      if (bundledContent != null) return bundledContent;
    }

    // Check Hive cache
    final cachedContent = _hiveService.getCachedLessonContent(lessonId);
    if (cachedContent != null) return cachedContent;

    // Try on-demand download using content URL from manifest
    final contentUrl = _manifestRepo.getLessonContentUrl(pathId, lessonId);
    if (contentUrl != null) {
      final downloadedContent = await _storageService.downloadLessonContentByUrl(contentUrl);
      if (downloadedContent != null) {
        // Cache the downloaded content
        await _hiveService.cacheLessonContent(
          lessonId: lessonId,
          pathId: pathId,
          content: downloadedContent,
        );
        return downloadedContent;
      }
    }

    return null;
  }

  /// Check if lesson content is available offline
  bool isLessonAvailableOffline(String lessonId, String pathId) {
    // Path 1 bundled content is always available
    if (pathId == AppConstants.path1Id) {
      return true;
    }
    return _hiveService.isLessonCached(lessonId);
  }

  /// Cache lesson content (for downloaded lessons)
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
    // Path 1 is fully bundled
    if (pathId == AppConstants.path1Id) {
      final lessons = await getLessonsForPath(pathId);
      return (lessons.length, lessons.length);
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

  /// Download a single lesson using content URL from manifest
  /// Returns the downloaded content or null if failed
  Future<LessonContentModel?> downloadAndCacheLesson({
    required String lessonId,
    required String pathId,
  }) async {
    // Get content URL from manifest
    final contentUrl = _manifestRepo.getLessonContentUrl(pathId, lessonId);
    if (contentUrl == null) return null;

    // Download from Supabase
    final content = await _storageService.downloadLessonContentByUrl(contentUrl);
    if (content == null) return null;

    // Cache in Hive
    await _hiveService.cacheLessonContent(
      lessonId: lessonId,
      pathId: pathId,
      content: content,
    );

    return content;
  }

  /// Download all lessons for a path
  /// Returns count of successfully downloaded lessons
  Future<int> downloadAllLessonsForPath({
    required String pathId,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    final lessons = await getLessonsForPath(pathId);
    
    // Filter out already cached lessons
    final uncachedLessons = lessons.where(
      (l) => !_hiveService.isLessonCached(l.id)
    ).toList();

    if (uncachedLessons.isEmpty) {
      onProgress?.call(lessons.length, lessons.length);
      return lessons.length;
    }

    int downloadedCount = lessons.length - uncachedLessons.length;

    // Download uncached lessons
    for (int i = 0; i < uncachedLessons.length; i++) {
      final lesson = uncachedLessons[i];
      
      if (lesson.contentUrl != null) {
        final content = await _storageService.downloadLessonContentByUrl(lesson.contentUrl!);
        if (content != null) {
          await _hiveService.cacheLessonContent(
            lessonId: lesson.id,
            pathId: pathId,
            content: content,
          );
          downloadedCount++;
        }
      }
      
      onProgress?.call(downloadedCount, lessons.length);
    }

    return downloadedCount;
  }

  /// Get modules for a path
  List<dynamic> getModulesForPath(String pathId) {
    return _manifestRepo.getModulesForPath(pathId);
  }

  /// Clear all cached content (for debugging/reset)
  Future<void> clearAllCache() async {
    await _hiveService.clearAllCache();
  }
}
