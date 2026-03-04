// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_empty_else, duplicate_ignore, comment_references, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas

import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part of 'lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ContentBlock _$ContentBlockFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType'] as String?) {
    case 'text':
      return TextBlock.fromJson(json);
    case 'code':
      return CodeBlock.fromJson(json);
    case 'tip':
      return TipBlock.fromJson(json);
    case 'warning':
      return WarningBlock.fromJson(json);
    case 'interactive':
      return InteractiveExampleBlock.fromJson(json);
    case 'list':
      return ListBlock.fromJson(json);
    case 'image':
      return ImageBlock.fromJson(json);
    case 'video':
      return VideoBlock.fromJson(json);
    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ContentBlock',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ContentBlock {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String value) text,
    required TResult Function(String value) code,
    required TResult Function(String value) tip,
    required TResult Function(String value) warning,
    required TResult Function(Map<String, dynamic> payload) interactive,
    required TResult Function(List<String> items) list,
    required TResult Function(String url) image,
    required TResult Function(String url) video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String value)? text,
    TResult? Function(String value)? code,
    TResult? Function(String value)? tip,
    TResult? Function(String value)? warning,
    TResult? Function(Map<String, dynamic> payload)? interactive,
    TResult? Function(List<String> items)? list,
    TResult? Function(String url)? image,
    TResult? Function(String url)? video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String value)? text,
    TResult Function(String value)? code,
    TResult Function(String value)? tip,
    TResult Function(String value)? warning,
    TResult Function(Map<String, dynamic> payload)? interactive,
    TResult Function(List<String> items)? list,
    TResult Function(String url)? image,
    TResult Function(String url)? video,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentBlockCopyWith<$Res> {
  factory $ContentBlockCopyWith(
          ContentBlock value, $Res Function(ContentBlock) then) =
      _$ContentBlockCopyWithImpl<$Res>;
}

/// @nodoc
class _$ContentBlockCopyWithImpl<$Res> implements $ContentBlockCopyWith<$Res> {
  _$ContentBlockCopyWithImpl(this._value, this._then);

  final ContentBlock _value;

  // ignore: unused_field
  final $Res Function(ContentBlock) _then;
}

/// @nodoc
abstract class _$$TextBlockCopyWith<$Res> {
  factory _$$TextBlockCopyWith(
          _$TextBlock value, $Res Function(_$TextBlock) then) =
      __$$TextBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$TextBlockCopyWithImpl<$Res>
    implements _$$TextBlockCopyWith<$Res> {
  __$$TextBlockCopyWithImpl(this._value, this._then);

  final _$TextBlock _value;

  // ignore: unused_field
  final $Res Function(_$TextBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$TextBlock(
      value == null ? _value.value : value as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TextBlock implements TextBlock {
  const _$TextBlock(this.value, {final String? $type})
      : $type = $type ?? 'text';

  factory _$TextBlock.fromJson(Map<String, dynamic> json) =>
      _$$TextBlockFromJson(json);

  @override
  final String value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ContentBlock.text(value: $value)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextBlock &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TextBlockCopyWith<_$TextBlock> get copyWith =>
      __$$TextBlockCopyWithImpl<_$TextBlock>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String value) text,
    required TResult Function(String value) code,
    required TResult Function(String value) tip,
    required TResult Function(String value) warning,
    required TResult Function(Map<String, dynamic> payload) interactive,
    required TResult Function(List<String> items) list,
    required TResult Function(String url) image,
    required TResult Function(String url) video,
  }) {
    return text(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String value)? text,
    TResult? Function(String value)? code,
    TResult? Function(String value)? tip,
    TResult? Function(String value)? warning,
    TResult? Function(Map<String, dynamic> payload)? interactive,
    TResult? Function(List<String> items)? list,
    TResult? Function(String url)? image,
    TResult? Function(String url)? video,
  }) {
    return text?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String value)? text,
    TResult Function(String value)? code,
    TResult Function(String value)? tip,
    TResult Function(String value)? warning,
    TResult Function(Map<String, dynamic> payload)? interactive,
    TResult Function(List<String> items)? list,
    TResult Function(String url)? image,
    TResult Function(String url)? video,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(value);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$TextBlockToJson(this);
}

abstract class TextBlock implements ContentBlock {
  const factory TextBlock(String value) = _$TextBlock;

  String get value;
  @JsonKey(ignore: true)
  _$$TextBlockCopyWith<_$TextBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

// Similar implementations for other block types...

/// @nodoc
@JsonSerializable()
class _$CodeBlock implements CodeBlock {
  const _$CodeBlock(this.value, {final String? $type})
      : $type = $type ?? 'code';

  factory _$CodeBlock.fromJson(Map<String, dynamic> json) =>
      _$$CodeBlockFromJson(json);

  @override
  final String value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$CodeBlockToJson(this);
}

abstract class CodeBlock implements ContentBlock {
  const factory CodeBlock(String value) = _$CodeBlock;

  String get value;
}

/// @nodoc
@JsonSerializable()
class _$TipBlock implements TipBlock {
  const _$TipBlock(this.value, {final String? $type})
      : $type = $type ?? 'tip';

  factory _$TipBlock.fromJson(Map<String, dynamic> json) =>
      _$$TipBlockFromJson(json);

  @override
  final String value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$TipBlockToJson(this);
}

abstract class TipBlock implements ContentBlock {
  const factory TipBlock(String value) = _$TipBlock;

  String get value;
}

/// @nodoc
@JsonSerializable()
class _$WarningBlock implements WarningBlock {
  const _$WarningBlock(this.value, {final String? $type})
      : $type = $type ?? 'warning';

  factory _$WarningBlock.fromJson(Map<String, dynamic> json) =>
      _$$WarningBlockFromJson(json);

  @override
  final String value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$WarningBlockToJson(this);
}

abstract class WarningBlock implements ContentBlock {
  const factory WarningBlock(String value) = _$WarningBlock;

  String get value;
}

/// @nodoc
@JsonSerializable()
class _$InteractiveExampleBlock implements InteractiveExampleBlock {
  const _$InteractiveExampleBlock(this.payload, {final String? $type})
      : $type = $type ?? 'interactive';

  factory _$InteractiveExampleBlock.fromJson(Map<String, dynamic> json) =>
      _$$InteractiveExampleBlockFromJson(json);

  @override
  final Map<String, dynamic> payload;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$InteractiveExampleBlockToJson(this);
}

abstract class InteractiveExampleBlock implements ContentBlock {
  const factory InteractiveExampleBlock(Map<String, dynamic> payload) =
      _$InteractiveExampleBlock;

  Map<String, dynamic> get payload;
}

/// @nodoc
@JsonSerializable()
class _$ListBlock implements ListBlock {
  const _$ListBlock(final List<String> items, {final String? $type})
      : _items = items,
        $type = $type ?? 'list';

  factory _$ListBlock.fromJson(Map<String, dynamic> json) =>
      _$$ListBlockFromJson(json);

  final List<String> _items;

  @override
  List<String> get items {
    return List<String>.unmodifiable(_items);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$ListBlockToJson(this);
}

abstract class ListBlock implements ContentBlock {
  const factory ListBlock(List<String> items) = _$ListBlock;

  List<String> get items;
}

/// @nodoc
@JsonSerializable()
class _$ImageBlock implements ImageBlock {
  const _$ImageBlock(this.url, {final String? $type})
      : $type = $type ?? 'image';

  factory _$ImageBlock.fromJson(Map<String, dynamic> json) =>
      _$$ImageBlockFromJson(json);

  @override
  final String url;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$ImageBlockToJson(this);
}

abstract class ImageBlock implements ContentBlock {
  const factory ImageBlock(String url) = _$ImageBlock;

  String get url;
}

/// @nodoc
@JsonSerializable()
class _$VideoBlock implements VideoBlock {
  const _$VideoBlock(this.url, {final String? $type})
      : $type = $type ?? 'video';

  factory _$VideoBlock.fromJson(Map<String, dynamic> json) =>
      _$$VideoBlockFromJson(json);

  @override
  final String url;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  Map<String, dynamic> toJson() => _$$VideoBlockToJson(this);
}

abstract class VideoBlock implements ContentBlock {
  const factory VideoBlock(String url) = _$VideoBlock;

  String get url;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      title: json['title'] as String,
      content: (json['content'] as List<dynamic>)
          .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      quizId: json['quizId'] as String?,
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'title': instance.title,
      'content': instance.content,
      'quizId': instance.quizId,
    };
