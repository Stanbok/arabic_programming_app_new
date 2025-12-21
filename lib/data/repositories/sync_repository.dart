import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../../core/utils/connectivity_util.dart';
import '../models/user_progress_model.dart';
import '../models/user_profile_model.dart';
import 'auth_repository.dart';

/// Repository for syncing data with Firestore (linked users only)
class SyncRepository {
  SyncRepository._();
  static final SyncRepository instance = SyncRepository._();

  final _firestore = FirebaseFirestore.instance;
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

  /// Get Firestore document reference for current user
  DocumentReference? get _userDoc {
    final uid = _authRepo.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  /// Sync progress to Firestore (background, non-blocking)
  Future<void> syncProgress() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final doc = _userDoc;
    if (doc == null) return;

    try {
      final progress = _progressBoxInstance.get(HiveKeys.progress);
      if (progress == null) return;

      await doc.set({
        'progress': progress.toJson(),
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silent fail - sync will retry later
    }
  }

  /// Sync profile to Firestore (name only)
  Future<void> syncProfile() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final doc = _userDoc;
    if (doc == null) return;

    try {
      final profile = _profileBoxInstance.get(HiveKeys.profile);
      if (profile == null) return;

      await doc.set({
        'name': profile.name,
        'avatarId': profile.avatarId,
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silent fail
    }
  }

  /// Fetch progress from Firestore and merge with local
  Future<void> fetchAndMergeProgress() async {
    if (!isSyncEnabled) return;
    if (!await ConnectivityUtil.hasConnection()) return;

    final doc = _userDoc;
    if (doc == null) return;

    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || data['progress'] == null) return;

      final remoteProgress = UserProgressModel.fromJson(data['progress']);
      final localProgress = _progressBoxInstance.get(HiveKeys.progress);

      // Merge: keep the union of completed items
      final mergedCompletedLessons = <String>{
        ...localProgress?.completedLessonIds ?? [],
        ...remoteProgress.completedLessonIds,
      }.toList();

      final mergedCompletedPaths = <String>{
        ...localProgress?.completedPathIds ?? [],
        ...remoteProgress.completedPathIds,
      }.toList();

      // Use the most recent position
      final useRemotePosition = (remoteProgress.lastUpdated ?? DateTime(2000))
          .isAfter(localProgress?.lastUpdated ?? DateTime(2000));

      final merged = UserProgressModel(
        completedLessonIds: mergedCompletedLessons,
        completedPathIds: mergedCompletedPaths,
        currentPathId: useRemotePosition
            ? remoteProgress.currentPathId
            : localProgress?.currentPathId,
        currentLessonId: useRemotePosition
            ? remoteProgress.currentLessonId
            : localProgress?.currentLessonId,
        currentCardIndex: useRemotePosition
            ? remoteProgress.currentCardIndex
            : localProgress?.currentCardIndex,
        lastUpdated: DateTime.now(),
      );

      await _progressBoxInstance.put(HiveKeys.progress, merged);
    } catch (e) {
      // Silent fail
    }
  }

  /// Full sync (fetch and push)
  Future<void> fullSync() async {
    await fetchAndMergeProgress();
    await syncProgress();
    await syncProfile();
  }

  /// Delete all user data from Firestore
  Future<void> deleteUserData() async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      await doc.delete();
    } catch (e) {
      // Silent fail
    }
  }
}
