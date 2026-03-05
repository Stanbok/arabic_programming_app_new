// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_check_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UpdateCheckModelAdapter extends TypeAdapter<UpdateCheckModel> {
  @override
  final int typeId = 11;

  @override
  UpdateCheckModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UpdateCheckModel(
      lastCheckDate: fields[0] as DateTime,
      lastGlobalVersion: fields[1] as int,
      updateAvailable: fields[2] as bool? ?? false,
      updateMessage: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UpdateCheckModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lastCheckDate)
      ..writeByte(1)
      ..write(obj.lastGlobalVersion)
      ..writeByte(2)
      ..write(obj.updateAvailable)
      ..writeByte(3)
      ..write(obj.updateMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateCheckModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
