// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressModelAdapter extends TypeAdapter<UserProgressModel> {
  @override
  final int typeId = 0;

  @override
  UserProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgressModel(
      completedLessonIds: (fields[0] as List?)?.cast<String>() ?? [],
      completedPathIds: (fields[1] as List?)?.cast<String>() ?? [],
      currentPathId: fields[2] as String?,
      currentLessonId: fields[3] as String?,
      currentCardIndex: fields[4] as int?,
      lastUpdated: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgressModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.completedLessonIds)
      ..writeByte(1)
      ..write(obj.completedPathIds)
      ..writeByte(2)
      ..write(obj.currentPathId)
      ..writeByte(3)
      ..write(obj.currentLessonId)
      ..writeByte(4)
      ..write(obj.currentCardIndex)
      ..writeByte(5)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
