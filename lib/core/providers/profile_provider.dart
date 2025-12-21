import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/user_profile_model.dart';
import '../constants/hive_boxes.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfileModel>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<UserProfileModel> {
  late Box<UserProfileModel> _box;

  ProfileNotifier() : super(UserProfileModel()) {
    _init();
  }

  void _init() {
    _box = Hive.box<UserProfileModel>(HiveBoxes.userProfile);
    final profile = _box.get(HiveKeys.profile);
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> updateName(String name) async {
    state = state.copyWith(name: name);
    await _box.put(HiveKeys.profile, state);
  }

  Future<void> updateAvatar(int avatarId) async {
    state = state.copyWith(avatarId: avatarId);
    await _box.put(HiveKeys.profile, state);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    await _box.put(HiveKeys.profile, state);
  }

  Future<void> linkAccount({
    required String email,
    required String firebaseUid,
  }) async {
    state = state.copyWith(
      isLinked: true,
      email: email,
      firebaseUid: firebaseUid,
    );
    await _box.put(HiveKeys.profile, state);
  }

  Future<void> setPremium({
    required bool isPremium,
    DateTime? expiryDate,
  }) async {
    state = state.copyWith(
      isPremium: isPremium,
      premiumExpiryDate: expiryDate,
    );
    await _box.put(HiveKeys.profile, state);
  }

  Future<void> clearProfile() async {
    state = UserProfileModel();
    await _box.delete(HiveKeys.profile);
  }

  Future<void> setLinked(bool isLinked) async {
    state = state.copyWith(isLinked: isLinked);
    await _box.put(HiveKeys.profile, state);
  }
}
