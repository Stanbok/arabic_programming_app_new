// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$Unit _$$UnitFromJson(Map<String, dynamic> json) => _$Unit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      lessons: List<String>.from(json['lessons'] as List<dynamic>),
      unlockRequirement: json['unlockRequirement'] == null
          ? null
          : UnlockRequirement.fromJson(
              json['unlockRequirement'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UnitToJson(_$Unit instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'lessons': instance.lessons,
      'unlockRequirement': instance.unlockRequirement,
    };

_$UnlockRequirement _$$UnlockRequirementFromJson(Map<String, dynamic> json) =>
    _$UnlockRequirement(
      previousUnitId: json['previousUnitId'] as String?,
      minScore: json['minScore'] as int?,
    );

Map<String, dynamic> _$$UnlockRequirementToJson(
        _$UnlockRequirement instance) =>
    <String, dynamic>{
      'previousUnitId': instance.previousUnitId,
      'minScore': instance.minScore,
    };
