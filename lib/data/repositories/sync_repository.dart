import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../../core/utils/connectivity_util.dart';
import '../models/user_progress_model.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_progress_service.dart';
import 'auth_repository.dart';

/// Repository for syncing data with Supabase (linked users only)
/// 
/// Migrated from Firestore to Supabase.
/// Uses firebase_uid as plain string identifier (NOT Supabase Auth).
/// 
/// Sync Strategy:
/// - Local-first: Hive is always the source of truth for immediate reads
/// - Background sync: Push/pull to Supabase when online
/// - Merge logic: Union of completed items, latest timestamp wins for position
class SyncRepository {
  SyncRepository._();
  static final SyncRepository instance = SyncRepository._();

  final _supabaseService = SupabaseProgressService.instance;
  final _authRepo = AuthRepository.instance;

  Box<UserProgressModel>? _progressBox;
  Box<UserProfileModel>? _profileBox;

  Box<UserProgressModel> get _progressBoxInstance {
    _progressBox ??= Hive.box<UserProgressModel>(HiveBoxes.userProgress);
    return _progressBox!;
  }

  Box<UserProfileModel> get _profileBoxInstance {
    _profileBox ??= Hive.box<UserProfileModel>(HiveBoxes.userProfile);
    return _profileBox!;
  }

  /// Check if sync is enabled (user is linked)
  bool get isSyncEnabled {
    final profile = _profileBoxInstance.get(HiveKeys.profile);
    return profile?.isLinked ?? false;
  }

  /// Get Firebase UID for Supabase operations
  String? get _firebaseUid => _authRepo.currentUser?.uid;

  /// Sync progress to Supabase (background, non-blocking)
  Future<void> syncProgress() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final uid = _firebaseUid;
    if (uid == null) return;

    try {
      final progress = _progressBoxInstance.get(HiveKeys.progress);
      if (progress == null) return;

      await _supabaseService.saveProgress(
        firebaseUid: uid,
        progress: progress,
      );
    } catch (e) {
      // Silent fail - sync will retry later
    }
  }

  /// Sync profile to Supabase (name, avatar)
  Future<void> syncProfile() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final uid = _firebaseUid;
    if (uid == null) return;

    try {
      final profile = _profileBoxInstance.get(HiveKeys.profile);
      if (profile == null) return;

      await _supabaseService.saveProfile(
        firebaseUid: uid,
        profile: profile,
      );
    } catch (e) {
      // Silent fail
    }
  }

  /// Fetch progress from Supabase and merge with local
  Future<void> fetchAndMergeProgress() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final uid = _firebaseUid;
    if (uid == null) return;

    try {
      final remoteProgress = await _supabaseService.fetchProgress(uid);
      if (remoteProgress == null) return;

      final localProgress = _progressBoxInstance.get(HiveKeys.progress);
      if (localProgress == null) {
        // No local progress - use remote
        await _progressBoxInstance.put(HiveKeys.progress, remoteProgress);
        return;
      }

      // Merge local and remote
      final merged = _supabaseService.mergeProgress(
        local: localProgress,
        remote: remoteProgress,
      );

      await _progressBoxInstance.put(HiveKeys.progress, merged);
    } catch (e) {
      // Silent fail
    }
  }

  /// Fetch profile from Supabase
  Future<void> fetchAndMergeProfile() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final uid = _firebaseUid;
    if (uid == null) return;

    try {
      final remoteProfile = await _supabaseService.fetchProfile(uid);
      if (remoteProfile == null) return;

      final localProfile = _profileBoxInstance.get(HiveKeys.profile);
      
      // Keep local isLinked status, update name/avatar from remote
      final merged = UserProfileModel(
        name: (remoteProfile.name?.isNotEmpty ?? false)
            ? remoteProfile.name 
            : (localProfile?.name ?? ''),
        avatarId: remoteProfile.avatarId,
        isLinked: localProfile?.isLinked ?? false,
      );

      await _profileBoxInstance.put(HiveKeys.profile, merged);
    } catch (e) {
      // Silent fail
    }
  }

  /// Full sync (fetch and push)
  Future<void> fullSync() async {
    await fetchAndMergeProgress();
    await syncProgress();
    await fetchAndMergeProfile();
    await syncProfile();
  }

  /// Delete all user data from Supabase
  Future<void> deleteUserData() async {
    final uid = _firebaseUid;
    if (uid == null) return;

    try {
      await _supabaseService.deleteUserData(uid);
    } catch (e) {
      // Silent fail
    }
  }

  /// Called when user links their account
  Future<void> onAccountLinked() async {
    // Immediately sync all local data to Supabase
    await fullSync();
  }

  /// Called when user unlinks their account
  Future<void> onAccountUnlinked() async {
    // Optionally delete remote data
    // await deleteUserData();
  }
}
