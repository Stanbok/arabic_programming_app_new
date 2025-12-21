import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/app_settings_model.dart';
import '../constants/hive_boxes.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsModel>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettingsModel> {
  late Box<AppSettingsModel> _box;

  SettingsNotifier() : super(AppSettingsModel()) {
    _init();
  }

  void _init() {
    _box = Hive.box<AppSettingsModel>(HiveBoxes.appSettings);
    final settings = _box.get(HiveKeys.settings);
    if (settings != null) {
      state = settings;
    } else {
      _box.put(HiveKeys.settings, state);
    }
  }

  Future<void> updateThemeMode(int themeModeIndex) async {
    state = state.copyWith(themeModeIndex: themeModeIndex);
    await _box.put(HiveKeys.settings, state);
  }

  Future<void> updateFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _box.put(HiveKeys.settings, state);
  }

  Future<void> updateDailyReminder(bool enabled) async {
    state = state.copyWith(dailyReminderEnabled: enabled);
    await _box.put(HiveKeys.settings, state);
  }

  Future<void> updateAchievementNotifications(bool enabled) async {
    state = state.copyWith(achievementNotificationsEnabled: enabled);
    await _box.put(HiveKeys.settings, state);
  }

  Future<void> updateUpdateNotifications(bool enabled) async {
    state = state.copyWith(updateNotificationsEnabled: enabled);
    await _box.put(HiveKeys.settings, state);
  }

  Future<void> updateReminderTime(String time) async {
    state = state.copyWith(reminderTime: time);
    await _box.put(HiveKeys.settings, state);
  }
}
