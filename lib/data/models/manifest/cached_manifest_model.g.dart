// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_manifest_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedManifestModelAdapter extends TypeAdapter<CachedManifestModel> {
  @override
  final int typeId = 10;

  @override
  CachedManifestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedManifestModel(
      manifestId: fields[0] as String,
      manifestType: fields[1] as String,
      version: fields[2] as int,
      contentJson: fields[3] as String,
      cachedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedManifestModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.manifestId)
      ..writeByte(1)
      ..write(obj.manifestType)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.contentJson)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedManifestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
