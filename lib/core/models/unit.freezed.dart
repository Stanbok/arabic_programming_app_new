// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_empty_else, duplicate_ignore, comment_references, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas

import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part of 'unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

const Object freezedUnnamed = Object();

Unit _$UnitFromJson(Map<String, dynamic> json) {
  return _Unit.fromJson(json);
}

UnlockRequirement _$UnlockRequirementFromJson(Map<String, dynamic> json) {
  return _UnlockRequirement.fromJson(json);
}

/// @nodoc
mixin _$Unit {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get lessons => throw _privateConstructorUsedError;
  UnlockRequirement? get unlockRequirement => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UnitCopyWith<Unit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnitCopyWith<$Res> {
  factory $UnitCopyWith(Unit value, $Res Function(Unit) then) =
      _$UnitCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      List<String> lessons,
      UnlockRequirement? unlockRequirement});

  $UnlockRequirementCopyWith<$Res>? get unlockRequirement;
}

/// @nodoc
class _$UnitCopyWithImpl<$Res> implements $UnitCopyWith<$Res> {
  _$UnitCopyWithImpl(this._value, this._then);

  final Unit _value;
  // ignore: unused_field
  final $Res Function(Unit) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? lessons = null,
    Object? unlockRequirement = freezedUnnamed,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      title: null == title ? _value.title : title as String,
      description: null == description ? _value.description : description as String,
      lessons: null == lessons ? _value.lessons : lessons as List<String>,
      unlockRequirement: freezedUnnamed == unlockRequirement
          ? _value.unlockRequirement
          : unlockRequirement as UnlockRequirement?,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $UnlockRequirementCopyWith<$Res>? get unlockRequirement {
    if (_value.unlockRequirement == null) {
      return null;
    }

    return $UnlockRequirementCopyWith<$Res>(_value.unlockRequirement!,
        (value) => call(unlockRequirement: value));
  }
}

/// @nodoc
abstract class _$$UnitCopyWith<$Res> implements $UnitCopyWith<$Res> {
  factory _$$UnitCopyWith(_$Unit value, $Res Function(_$Unit) then) =
      __$$UnitCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      List<String> lessons,
      UnlockRequirement? unlockRequirement});

  @override
  $UnlockRequirementCopyWith<$Res>? get unlockRequirement;
}

/// @nodoc
class __$$UnitCopyWithImpl<$Res> implements _$$UnitCopyWith<$Res> {
  __$$UnitCopyWithImpl(this._value, this._then);

  final _$Unit _value;
  // ignore: unused_field
  final $Res Function(_$Unit) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? lessons = null,
    Object? unlockRequirement = freezedUnnamed,
  }) {
    return _then(_$Unit(
      id: null == id ? _value.id : id as String,
      title: null == title ? _value.title : title as String,
      description: null == description
          ? _value.description
          : description as String,
      lessons: null == lessons ? _value.lessons : lessons as List<String>,
      unlockRequirement: freezedUnnamed == unlockRequirement
          ? _value.unlockRequirement
          : unlockRequirement as UnlockRequirement?,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $UnlockRequirementCopyWith<$Res>? get unlockRequirement {
    if (_value.unlockRequirement == null) {
      return null;
    }

    return $UnlockRequirementCopyWith<$Res>(_value.unlockRequirement!,
        (value) => call(unlockRequirement: value));
  }
}

/// @nodoc
@JsonSerializable()
class _$Unit implements Unit {
  const _$Unit(
      {required this.id,
      required this.title,
      required this.description,
      required this.lessons,
      this.unlockRequirement});

  factory _$Unit.fromJson(Map<String, dynamic> json) =>
      _$$UnitFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final List<String> lessons;
  @override
  final UnlockRequirement? unlockRequirement;

  @override
  String toString() {
    return 'Unit(id: $id, title: $title, description: $description, lessons: $lessons, unlockRequirement: $unlockRequirement)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Unit &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.lessons, lessons) &&
            (identical(other.unlockRequirement, unlockRequirement) ||
                other.unlockRequirement == unlockRequirement));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, description,
      const DeepCollectionEquality().hash(lessons), unlockRequirement);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UnitCopyWith<_$Unit> get copyWith =>
      __$$UnitCopyWithImpl<_$Unit>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnitToJson(this);
  }
}

abstract class _Unit implements Unit {
  const factory _Unit(
      {required final String id,
      required final String title,
      required final String description,
      required final List<String> lessons,
      final UnlockRequirement? unlockRequirement}) = _$Unit;

  factory _Unit.fromJson(Map<String, dynamic> json) = _$Unit.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  List<String> get lessons;
  @override
  UnlockRequirement? get unlockRequirement;
  @override
  @JsonKey(ignore: true)
  _$$UnitCopyWith<_$Unit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$UnlockRequirement {
  String? get previousUnitId => throw _privateConstructorUsedError;
  int? get minScore => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UnlockRequirementCopyWith<UnlockRequirement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnlockRequirementCopyWith<$Res> {
  factory $UnlockRequirementCopyWith(UnlockRequirement value,
          $Res Function(UnlockRequirement) then) =
      _$UnlockRequirementCopyWithImpl<$Res>;
  @useResult
  $Res call({String? previousUnitId, int? minScore});
}

/// @nodoc
class _$UnlockRequirementCopyWithImpl<$Res>
    implements $UnlockRequirementCopyWith<$Res> {
  _$UnlockRequirementCopyWithImpl(this._value, this._then);

  final UnlockRequirement _value;
  // ignore: unused_field
  final $Res Function(UnlockRequirement) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? previousUnitId = freezedUnnamed,
    Object? minScore = freezedUnnamed,
  }) {
    return _then(_value.copyWith(
      previousUnitId: freezedUnnamed == previousUnitId
          ? _value.previousUnitId
          : previousUnitId as String?,
      minScore:
          freezedUnnamed == minScore ? _value.minScore : minScore as int?,
    ));
  }
}

/// @nodoc
abstract class _$$UnlockRequirementCopyWith<$Res>
    implements $UnlockRequirementCopyWith<$Res> {
  factory _$$UnlockRequirementCopyWith(_$UnlockRequirement value,
          $Res Function(_$UnlockRequirement) then) =
      __$$UnlockRequirementCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? previousUnitId, int? minScore});
}

/// @nodoc
class __$$UnlockRequirementCopyWithImpl<$Res>
    implements _$$UnlockRequirementCopyWith<$Res> {
  __$$UnlockRequirementCopyWithImpl(this._value, this._then);

  final _$UnlockRequirement _value;
  // ignore: unused_field
  final $Res Function(_$UnlockRequirement) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? previousUnitId = freezedUnnamed,
    Object? minScore = freezedUnnamed,
  }) {
    return _then(_$UnlockRequirement(
      previousUnitId: freezedUnnamed == previousUnitId
          ? _value.previousUnitId
          : previousUnitId as String?,
      minScore:
          freezedUnnamed == minScore ? _value.minScore : minScore as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UnlockRequirement implements UnlockRequirement {
  const _$UnlockRequirement({this.previousUnitId, this.minScore});

  factory _$UnlockRequirement.fromJson(Map<String, dynamic> json) =>
      _$$UnlockRequirementFromJson(json);

  @override
  final String? previousUnitId;
  @override
  final int? minScore;

  @override
  String toString() {
    return 'UnlockRequirement(previousUnitId: $previousUnitId, minScore: $minScore)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnlockRequirement &&
            (identical(other.previousUnitId, previousUnitId) ||
                other.previousUnitId == previousUnitId) &&
            (identical(other.minScore, minScore) ||
                other.minScore == minScore));
  }

  @override
  int get hashCode => Object.hash(runtimeType, previousUnitId, minScore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UnlockRequirementCopyWith<_$UnlockRequirement> get copyWith =>
      __$$UnlockRequirementCopyWithImpl<_$UnlockRequirement>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnlockRequirementToJson(this);
  }
}

abstract class _UnlockRequirement implements UnlockRequirement {
  const factory _UnlockRequirement({
    final String? previousUnitId,
    final int? minScore,
  }) = _$UnlockRequirement;

  factory _UnlockRequirement.fromJson(Map<String, dynamic> json) =
      _$UnlockRequirement.fromJson;

  @override
  String? get previousUnitId;
  @override
  int? get minScore;
  @override
  @JsonKey(ignore: true)
  _$$UnlockRequirementCopyWith<_$UnlockRequirement> get copyWith =>
      throw _privateConstructorUsedError;
}
