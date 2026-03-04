import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit.g.dart';
part 'unit.freezed.dart';

@freezed
class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String title,
    required String description,
    required List<String> lessons,
    UnlockRequirement? unlockRequirement,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}

@freezed
class UnlockRequirement with _$UnlockRequirement {
  const factory UnlockRequirement({
    String? previousUnitId,
    int? minScore,
  }) = _UnlockRequirement;

  factory UnlockRequirement.fromJson(Map<String, dynamic> json) => _$UnlockRequirementFromJson(json);
}
