import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_repository.dart';
import '../../data/services/content_update_service.dart';
import 'content_provider.dart';

/// Handles app startup tasks:
/// 1. Seed manifest cache if empty (first run)
/// 2. Fetch and merge progress from cloud (if linked)
/// 3. Check for content updates (once per day, background)
/// 
/// All operations are non-blocking - UI renders immediately from cache
class AppStartupService {
  static bool _initialized = false;

  /// Initialize app (called once after first frame)
  static Future<void> initialize(WidgetRef ref) async {
    if (_initialized) return;
    _initialized = true;

    // Run all startup tasks in parallel (non-blocking)
    await Future.wait([
      _seedCacheIfEmpty(),
      _syncProgressFromCloud(),
      _checkForUpdates(ref),
    ]);
  }

  /// Seed manifest cache on first run
  static Future<void> _seedCacheIfEmpty() async {
    try {
      await ContentUpdateService.instance.seedCacheIfEmpty();
    } catch (e) {
      // Silent fail - bundled assets will be used
    }
  }

  /// Fetch and merge progress from Supabase
  static Future<void> _syncProgressFromCloud() async {
    try {
      await ProgressRepository.instance.fetchAndMergeFromCloud();
    } catch (e) {
      // Silent fail - local progress is used
    }
  }

  /// Check for content updates (daily)
  static Future<void> _checkForUpdates(WidgetRef ref) async {
    try {
      final result = await ContentUpdateService.instance.checkForUpdates();
      if (result.updatesAvailable) {
        // Refresh the notification provider
        ref.read(updateNotificationProvider.notifier).refresh();
      }
    } catch (e) {
      // Silent fail - no updates shown
    }
  }

  /// Reset initialization state (for testing)
  static void reset() {
    _initialized = false;
  }
}
