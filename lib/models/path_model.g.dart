// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PathModelAdapter extends TypeAdapter<PathModel> {
  @override
  final int typeId = 5;

  @override
  PathModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PathModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      iconUrl: fields[3] as String?,
      order: fields[4] as int,
      totalLessons: fields[5] as int,
      color: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PathModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconUrl)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.totalLessons)
      ..writeByte(6)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
