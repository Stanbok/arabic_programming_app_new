import '../../core/utils/connectivity_util.dart';
import '../models/manifest/manifest_models.dart';
import '../repositories/manifest_repository.dart';
import 'last_update_check_service.dart';
import 'manifest_cache_service.dart';

/// Result of an update check
class UpdateCheckResult {
  final bool updatesAvailable;
  final int pathsUpdated;
  final int modulesUpdated;
  final String? message;

  const UpdateCheckResult({
    required this.updatesAvailable,
    this.pathsUpdated = 0,
    this.modulesUpdated = 0,
    this.message,
  });

  factory UpdateCheckResult.noUpdates() => const UpdateCheckResult(
    updatesAvailable: false,
  );

  factory UpdateCheckResult.skipped() => const UpdateCheckResult(
    updatesAvailable: false,
    message: 'Check skipped (already checked today or offline)',
  );
}

/// Service for background content updates
/// 
/// Implements the non-blocking update flow:
/// 1. Check if update check is needed (once per day only)
/// 2. Fetch global manifest (if online)
/// 3. Compare versions and download updated manifests
/// 4. Validate and atomically update cache
/// 5. Set pending notification flag (no auto-refresh)
/// 
/// GUARANTEES:
/// - Never blocks UI
/// - Silent background download
/// - Shows dismissible popup ONCE per version
/// - No forced refresh or auto screen reload
class ContentUpdateService {
  ContentUpdateService._();
  static final ContentUpdateService instance = ContentUpdateService._();

  final _manifestRepo = ManifestRepository.instance;
  final _cacheService = ManifestCacheService.instance;
  final _updateCheckService = LastUpdateCheckService.instance;

  bool _isChecking = false;

  /// Check for updates (called after UI renders)
  /// Returns update result with details
  /// 
  /// Rules:
  /// - Only checks on first app launch of the day
  /// - Only if internet is available
  /// - Never blocks - returns immediately if conditions not met
  Future<UpdateCheckResult> checkForUpdates() async {
    // Prevent concurrent checks
    if (_isChecking) {
      return UpdateCheckResult.skipped();
    }

    // Check if we should run today
    if (!_updateCheckService.shouldCheckForUpdates()) {
      return UpdateCheckResult.skipped();
    }

    // Check connectivity
    if (!await ConnectivityUtil.hasConnection()) {
      return UpdateCheckResult.skipped();
    }

    _isChecking = true;

    try {
      return await _performUpdateCheck();
    } finally {
      _isChecking = false;
    }
  }

  /// Force update check (bypasses daily limit, for debugging)
  Future<UpdateCheckResult> forceUpdateCheck() async {
    if (_isChecking) {
      return UpdateCheckResult.skipped();
    }

    if (!await ConnectivityUtil.hasConnection()) {
      return UpdateCheckResult.skipped();
    }

    _isChecking = true;

    try {
      return await _performUpdateCheck();
    } finally {
      _isChecking = false;
    }
  }

  /// Internal: Perform the actual update check
  Future<UpdateCheckResult> _performUpdateCheck() async {
    // Step 1: Fetch remote global manifest
    final remoteGlobal = await _manifestRepo.fetchRemoteGlobalManifest();
    if (remoteGlobal == null) {
      // Network error - record check but no updates
      await _updateCheckService.recordUpdateCheck(
        globalManifestVersion: _manifestRepo.getGlobalManifestVersion(),
        updateAvailable: false,
      );
      return UpdateCheckResult.noUpdates();
    }

    // Step 2: Compare global manifest version
    final currentGlobalVersion = _manifestRepo.getGlobalManifestVersion();
    
    if (remoteGlobal.version <= currentGlobalVersion) {
      // No updates available
      await _updateCheckService.recordUpdateCheck(
        globalManifestVersion: currentGlobalVersion,
        updateAvailable: false,
      );
      return UpdateCheckResult.noUpdates();
    }

    // Step 3: Updates available - download and cache
    int pathsUpdated = 0;
    int modulesUpdated = 0;

    // Cache new global manifest
    await _cacheService.cacheGlobalManifest(remoteGlobal);

    // Step 4: Check each path for updates
    for (final pathRef in remoteGlobal.paths) {
      final updated = await _updatePathIfNeeded(pathRef);
      if (updated) {
        pathsUpdated++;
        // Update modules for this path
        modulesUpdated += await _updateModulesForPath(pathRef.id);
      }
    }

    // Step 5: Record update check with notification
    final message = _buildUpdateMessage(pathsUpdated, modulesUpdated);
    await _updateCheckService.recordUpdateCheck(
      globalManifestVersion: remoteGlobal.version,
      updateAvailable: true,
      updateMessage: message,
    );

    return UpdateCheckResult(
      updatesAvailable: true,
      pathsUpdated: pathsUpdated,
      modulesUpdated: modulesUpdated,
      message: message,
    );
  }

  /// Update path manifest if version is newer
  Future<bool> _updatePathIfNeeded(PathReference pathRef) async {
    final currentVersion = _cacheService.getPathManifestVersion(pathRef.id);
    
    if (pathRef.version <= currentVersion) {
      return false; // Already up to date
    }

    // Fetch and cache new path manifest
    final remotePathManifest = await _manifestRepo.fetchRemotePathManifest(pathRef.id);
    if (remotePathManifest == null) {
      return false; // Network error - keep existing
    }

    // Validate and cache
    return await _cacheService.cachePathManifest(remotePathManifest);
  }

  /// Update all modules for a path
  Future<int> _updateModulesForPath(String pathId) async {
    final pathManifest = _cacheService.getPathManifest(pathId);
    if (pathManifest == null) return 0;

    int updated = 0;

    for (final moduleRef in pathManifest.modules) {
      final currentVersion = _cacheService.getModuleLessonsVersion(moduleRef.id);
      
      if (moduleRef.version > currentVersion) {
        final remoteLessons = await _manifestRepo.fetchRemoteModuleLessons(
          pathId: pathId,
          moduleId: moduleRef.id,
        );
        
        if (remoteLessons != null) {
          final success = await _cacheService.cacheModuleLessons(
            moduleRef.id,
            remoteLessons,
          );
          if (success) updated++;
        }
      }
    }

    return updated;
  }

  /// Build user-friendly update message
  String _buildUpdateMessage(int pathsUpdated, int modulesUpdated) {
    if (pathsUpdated == 0 && modulesUpdated == 0) {
      return 'تم تحديث المحتوى. يرجى إعادة تشغيل التطبيق لتطبيق التغييرات.';
    }
    
    final parts = <String>[];
    if (pathsUpdated > 0) {
      parts.add('$pathsUpdated مسار');
    }
    if (modulesUpdated > 0) {
      parts.add('$modulesUpdated وحدة');
    }
    
    return 'تم تحديث ${parts.join(' و ')}. يرجى إعادة تشغيل التطبيق لتطبيق التغييرات.';
  }

  /// Check if there's a pending update notification
  bool hasPendingUpdateNotification() {
    return _updateCheckService.hasPendingUpdateNotification();
  }

  /// Get pending update message
  String? getPendingUpdateMessage() {
    return _updateCheckService.getPendingUpdateMessage();
  }

  /// Dismiss update notification
  Future<void> dismissUpdateNotification() async {
    await _updateCheckService.clearUpdateNotification();
  }

  /// Initial content setup (first app run)
  /// Seeds cache from bundled assets if empty
  Future<void> seedCacheIfEmpty() async {
    // Check if we have any cached manifests
    if (_cacheService.getCacheEntryCount() > 0) {
      return; // Cache already populated
    }

    // No cache - try to fetch from Supabase
    if (await ConnectivityUtil.hasConnection()) {
      final result = await forceUpdateCheck();
      if (result.updatesAvailable) {
        // Clear the notification for initial seed
        await _updateCheckService.clearUpdateNotification();
      }
    }
    // If offline, bundled assets will be used as fallback
  }
}
