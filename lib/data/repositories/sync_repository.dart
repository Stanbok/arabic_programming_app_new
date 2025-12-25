import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/hive_boxes.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/utils/connectivity_util.dart';
import '../models/user_progress_model.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_service.dart';
import 'auth_repository.dart';

/// Repository for syncing data with Supabase (linked users only)
class SyncRepository {
  SyncRepository._();
  static final SyncRepository instance = SyncRepository._();

  final _authRepo = AuthRepository.instance;
  SyncNotifier? _syncNotifier;

  Box<UserProgressModel>? _progressBox;
  Box<UserProfileModel>? _profileBox;

  SupabaseClient get _supabase => SupabaseService.clientInstance;

  Box<UserProgressModel> get _progressBoxInstance {
    _progressBox ??= Hive.box<UserProgressModel>(HiveBoxes.userProgress);
    return _progressBox!;
  }

  Box<UserProfileModel> get _profileBoxInstance {
    _profileBox ??= Hive.box<UserProfileModel>(HiveBoxes.userProfile);
    return _profileBox!;
  }

  void initialize(SyncNotifier notifier) {
    _syncNotifier = notifier;
  }

  /// Check if sync is enabled (user is linked)
  bool get isSyncEnabled {
    final profile = _profileBoxInstance.get(HiveKeys.profile);
    return profile?.isLinked ?? false;
  }

  /// Get current user ID
  String? get _userId => _authRepo.currentUser?.id;

  /// Sync progress to Supabase (background, non-blocking)
  Future<void> syncProgress() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final userId = _userId;
    if (userId == null) return;

    _syncNotifier?.startSync();

    try {
      final progress = _progressBoxInstance.get(HiveKeys.progress);
      if (progress == null) return;

      // Upsert each completed lesson as individual progress records
      for (final lessonId in progress.completedLessonIds) {
        await _supabase.from(SupabaseConstants.userProgressTable).upsert({
          'user_id': userId,
          'lesson_id': lessonId,
          'path_id': _getPathIdFromLessonId(lessonId),
          'is_completed': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,lesson_id');
      }

      // Update current position
      if (progress.currentLessonId != null) {
        await _supabase.from(SupabaseConstants.userProgressTable).upsert({
          'user_id': userId,
          'lesson_id': progress.currentLessonId!,
          'path_id': progress.currentPathId ?? '',
          'last_card_index': progress.currentCardIndex ?? 0,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,lesson_id');
      }
      
      _syncNotifier?.endSync();
    } catch (e) {
      debugPrint('Sync progress failed: $e');
      _syncNotifier?.endSync(success: false, error: e.toString());
    }
  }

  /// Helper to extract path_id from lesson_id (e.g., "lesson_1_1" -> "path_1")
  String _getPathIdFromLessonId(String lessonId) {
    final parts = lessonId.split('_');
    if (parts.length >= 2) {
      return 'path_${parts[1]}';
    }
    return 'path_1';
  }

  /// Sync profile to Supabase
  Future<void> syncProfile() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final userId = _userId;
    if (userId == null) return;

    try {
      final profile = _profileBoxInstance.get(HiveKeys.profile);
      if (profile == null) return;

      await _supabase.from(SupabaseConstants.profilesTable).upsert({
        'id': userId,
        'display_name': profile.name,
        'avatar_url': 'avatar_${profile.avatarId}',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Sync profile failed: $e');
      // Silent fail
    }
  }

  /// Fetch progress from Supabase and merge with local
  Future<void> fetchAndMergeProgress() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final userId = _userId;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from(SupabaseConstants.userProgressTable)
          .select()
          .eq('user_id', userId);

      if (response.isEmpty) return;

      final remoteCompletedLessons = <String>[];
      final remoteCompletedPaths = <String>{};
      String? remoteCurrentLessonId;
      String? remoteCurrentPathId;
      int? remoteCurrentCardIndex;
      DateTime? latestUpdate;

      for (final record in response) {
        final lessonId = record['lesson_id'] as String;
        final pathId = record['path_id'] as String;
        final isCompleted = record['is_completed'] as bool? ?? false;
        final lastCardIndex = record['last_card_index'] as int?;
        final updatedAt = record['updated_at'] != null
            ? DateTime.parse(record['updated_at'])
            : null;

        if (isCompleted) {
          remoteCompletedLessons.add(lessonId);
        }

        // Track latest position
        if (updatedAt != null && (latestUpdate == null || updatedAt.isAfter(latestUpdate))) {
          latestUpdate = updatedAt;
          remoteCurrentLessonId = lessonId;
          remoteCurrentPathId = pathId;
          remoteCurrentCardIndex = lastCardIndex;
        }
      }

      // Calculate completed paths
      final pathLessonCounts = <String, int>{};
      final pathCompletedCounts = <String, int>{};
      for (final lessonId in remoteCompletedLessons) {
        final pathId = _getPathIdFromLessonId(lessonId);
        pathCompletedCounts[pathId] = (pathCompletedCounts[pathId] ?? 0) + 1;
      }

      final localProgress = _progressBoxInstance.get(HiveKeys.progress);

      // Merge: keep the union of completed items
      final mergedCompletedLessons = <String>{
        ...localProgress?.completedLessonIds ?? [],
        ...remoteCompletedLessons,
      }.toList();

      final mergedCompletedPaths = <String>{
        ...localProgress?.completedPathIds ?? [],
        ...remoteCompletedPaths,
      }.toList();

      // Use the most recent position
      final useRemotePosition = latestUpdate != null &&
          latestUpdate.isAfter(localProgress?.lastUpdated ?? DateTime(2000));

      final merged = UserProgressModel(
        completedLessonIds: mergedCompletedLessons,
        completedPathIds: mergedCompletedPaths,
        currentPathId: useRemotePosition
            ? remoteCurrentPathId
            : localProgress?.currentPathId,
        currentLessonId: useRemotePosition
            ? remoteCurrentLessonId
            : localProgress?.currentLessonId,
        currentCardIndex: useRemotePosition
            ? remoteCurrentCardIndex
            : localProgress?.currentCardIndex,
        lastUpdated: DateTime.now(),
      );

      await _progressBoxInstance.put(HiveKeys.progress, merged);
    } catch (e) {
      debugPrint('Fetch and merge progress failed: $e');
      // Silent fail
    }
  }

  /// Full sync (fetch and push)
  Future<void> fullSync() async {
    _syncNotifier?.startSync();
    try {
      await fetchAndMergeProgress();
      await syncProgress();
      await syncProfile();
      _syncNotifier?.endSync();
    } catch (e) {
      _syncNotifier?.endSync(success: false, error: e.toString());
    }
  }

  /// Delete all user data from Supabase
  Future<void> deleteUserData() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _supabase
          .from(SupabaseConstants.userProgressTable)
          .delete()
          .eq('user_id', userId);
      await _supabase
          .from(SupabaseConstants.profilesTable)
          .delete()
          .eq('id', userId);
    } catch (e) {
      debugPrint('Delete user data failed: $e');
      // Silent fail
    }
  }
}
