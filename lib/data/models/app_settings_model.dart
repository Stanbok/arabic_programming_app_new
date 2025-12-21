import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

@HiveType(typeId: 2)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  final int themeModeIndex; // 0=system, 1=light, 2=dark

  @HiveField(1)
  final double fontSize; // 0.8 to 1.4 scale

  @HiveField(2)
  final bool dailyReminderEnabled;

  @HiveField(3)
  final bool achievementNotificationsEnabled;

  @HiveField(4)
  final bool updateNotificationsEnabled;

  @HiveField(5)
  final String? reminderTime; // HH:mm format

  AppSettingsModel({
    this.themeModeIndex = 0,
    this.fontSize = 1.0,
    this.dailyReminderEnabled = true,
    this.achievementNotificationsEnabled = true,
    this.updateNotificationsEnabled = true,
    this.reminderTime = '09:00',
  });

  ThemeMode get themeMode {
    switch (themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettingsModel copyWith({
    int? themeModeIndex,
    double? fontSize,
    bool? dailyReminderEnabled,
    bool? achievementNotificationsEnabled,
    bool? updateNotificationsEnabled,
    String? reminderTime,
  }) {
    return AppSettingsModel(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      fontSize: fontSize ?? this.fontSize,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      achievementNotificationsEnabled:
          achievementNotificationsEnabled ?? this.achievementNotificationsEnabled,
      updateNotificationsEnabled:
          updateNotificationsEnabled ?? this.updateNotificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
