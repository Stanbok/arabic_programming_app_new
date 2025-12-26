import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';
import '../../core/utils/connectivity_util.dart';
import '../models/user_progress_model.dart';
import '../models/user_profile_model.dart';

/// Service for syncing user progress with Supabase
/// 
/// IMPORTANT: Uses firebase_uid as a PLAIN STRING identifier.
/// NO Supabase Auth is used - we only store/retrieve data keyed by firebase_uid.
/// 
/// This service handles:
/// - Progress sync (completed lessons, paths, current position)
/// - Profile sync (name, avatar)
/// - Merge logic for offline/online progress
class SupabaseProgressService {
  SupabaseProgressService._();
  static final SupabaseProgressService instance = SupabaseProgressService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Save progress to Supabase
  /// Uses firebase_uid as plain string identifier (not JWT auth)
  Future<bool> saveProgress({
    required String firebaseUid,
    required UserProgressModel progress,
  }) async {
    if (!await ConnectivityUtil.hasConnection()) return false;

    try {
      await _client.from(SupabaseConstants.userProgressTable).upsert({
        'firebase_uid': firebaseUid,
        'completed_lesson_ids': progress.completedLessonIds,
        'completed_path_ids': progress.completedPathIds,
        'current_path_id': progress.currentPathId,
        'current_lesson_id': progress.currentLessonId,
        'current_card_index': progress.currentCardIndex,
        'last_updated': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch progress from Supabase
  Future<UserProgressModel?> fetchProgress(String firebaseUid) async {
    if (!await ConnectivityUtil.hasConnection()) return null;

    try {
      final response = await _client
          .from(SupabaseConstants.userProgressTable)
          .select()
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();

      if (response == null) return null;

      return UserProgressModel(
        completedLessonIds: List<String>.from(response['completed_lesson_ids'] ?? []),
        completedPathIds: List<String>.from(response['completed_path_ids'] ?? []),
        currentPathId: response['current_path_id'] as String?,
        currentLessonId: response['current_lesson_id'] as String?,
        currentCardIndex: response['current_card_index'] as int?,
        lastUpdated: response['last_updated'] != null
            ? DateTime.parse(response['last_updated'])
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save profile to Supabase
  Future<bool> saveProfile({
    required String firebaseUid,
    required UserProfileModel profile,
  }) async {
    if (!await ConnectivityUtil.hasConnection()) return false;

    try {
      await _client.from(SupabaseConstants.userProfilesTable).upsert({
        'firebase_uid': firebaseUid,
        'name': profile.name,
        'avatar_id': profile.avatarId,
        'is_linked': profile.isLinked,
        'last_updated': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch profile from Supabase
  Future<UserProfileModel?> fetchProfile(String firebaseUid) async {
    if (!await ConnectivityUtil.hasConnection()) return null;

    try {
      final response = await _client
          .from(SupabaseConstants.userProfilesTable)
          .select()
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();

      if (response == null) return null;

      return UserProfileModel(
        name: response['name'] as String? ?? '',
        avatarId: response['avatar_id'] as int? ?? 0,
        isLinked: response['is_linked'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Merge local and remote progress (union of completed items)
  UserProgressModel mergeProgress({
    required UserProgressModel local,
    required UserProgressModel remote,
  }) {
    // Union of completed items
    final mergedCompletedLessons = <String>{
      ...local.completedLessonIds,
      ...remote.completedLessonIds,
    }.toList();

    final mergedCompletedPaths = <String>{
      ...local.completedPathIds,
      ...remote.completedPathIds,
    }.toList();

    // Use the most recent position
    final useRemote = (remote.lastUpdated ?? DateTime(2000))
        .isAfter(local.lastUpdated ?? DateTime(2000));

    return UserProgressModel(
      completedLessonIds: mergedCompletedLessons,
      completedPathIds: mergedCompletedPaths,
      currentPathId: useRemote ? remote.currentPathId : local.currentPathId,
      currentLessonId: useRemote ? remote.currentLessonId : local.currentLessonId,
      currentCardIndex: useRemote ? remote.currentCardIndex : local.currentCardIndex,
      lastUpdated: DateTime.now(),
    );
  }

  /// Delete all user data from Supabase
  Future<bool> deleteUserData(String firebaseUid) async {
    if (!await ConnectivityUtil.hasConnection()) return false;

    try {
      await _client
          .from(SupabaseConstants.userProgressTable)
          .delete()
          .eq('firebase_uid', firebaseUid);
      
      await _client
          .from(SupabaseConstants.userProfilesTable)
          .delete()
          .eq('firebase_uid', firebaseUid);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
