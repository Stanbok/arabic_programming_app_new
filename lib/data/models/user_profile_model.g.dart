// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 1;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      name: fields[0] as String?,
      avatarId: fields[1] as int? ?? 0,
      isLinked: fields[2] as bool? ?? false,
      isPremium: fields[3] as bool? ?? false,
      email: fields[4] as String?,
      firebaseUid: fields[5] as String?,
      premiumExpiryDate: fields[6] as DateTime?,
      hasCompletedOnboarding: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.avatarId)
      ..writeByte(2)
      ..write(obj.isLinked)
      ..writeByte(3)
      ..write(obj.isPremium)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.firebaseUid)
      ..writeByte(6)
      ..write(obj.premiumExpiryDate)
      ..writeByte(7)
      ..write(obj.hasCompletedOnboarding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
