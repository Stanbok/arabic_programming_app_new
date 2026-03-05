// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 2;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      themeModeIndex: fields[0] as int? ?? 0,
      fontSize: fields[1] as double? ?? 1.0,
      dailyReminderEnabled: fields[2] as bool? ?? true,
      achievementNotificationsEnabled: fields[3] as bool? ?? true,
      updateNotificationsEnabled: fields[4] as bool? ?? true,
      reminderTime: fields[5] as String? ?? '09:00',
      codeThemeIndex: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.themeModeIndex)
      ..writeByte(1)
      ..write(obj.fontSize)
      ..writeByte(2)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(3)
      ..write(obj.achievementNotificationsEnabled)
      ..writeByte(4)
      ..write(obj.updateNotificationsEnabled)
      ..writeByte(5)
      ..write(obj.reminderTime)
      ..writeByte(6)
      ..write(obj.codeThemeIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
