// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_lesson_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedLessonModelAdapter extends TypeAdapter<CachedLessonModel> {
  @override
  final int typeId = 3;

  @override
  CachedLessonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedLessonModel(
      lessonId: fields[0] as String,
      pathId: fields[1] as String,
      contentJson: fields[2] as String,
      cachedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedLessonModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lessonId)
      ..writeByte(1)
      ..write(obj.pathId)
      ..writeByte(2)
      ..write(obj.contentJson)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedLessonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
