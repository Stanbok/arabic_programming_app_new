import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/hive_boxes.dart';

// Onboarding state
final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final box = await Hive.openBox<bool>(HiveBoxes.settings);
    state = box.get('onboardingCompleted', defaultValue: false) ?? false;
  }

  Future<void> completeOnboarding() async {
    final box = await Hive.openBox<bool>(HiveBoxes.settings);
    await box.put('onboardingCompleted', true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    final box = await Hive.openBox<bool>(HiveBoxes.settings);
    await box.put('onboardingCompleted', false);
    state = false;
  }
}

// Temporary onboarding data (name and avatar selection)
final onboardingNameProvider = StateProvider<String>((ref) => '');
final onboardingAvatarProvider = StateProvider<int>((ref) => 0);
