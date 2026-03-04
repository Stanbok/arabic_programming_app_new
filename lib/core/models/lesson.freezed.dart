// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_empty_else, duplicate_ignore, comment_references, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas

part of 'lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

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
class _$ContentBlockCopyWithImpl<$Res>
    implements $ContentBlockCopyWith<$Res> {
  _$ContentBlockCopyWithImpl(this._value, this._then);

  final ContentBlock _value;
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

/// @nodoc
abstract class _$$CodeBlockCopyWith<$Res> {
  factory _$$CodeBlockCopyWith(
          _$CodeBlock value, $Res Function(_$CodeBlock) then) =
      __$$CodeBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$CodeBlockCopyWithImpl<$Res>
    implements _$$CodeBlockCopyWith<$Res> {
  __$$CodeBlockCopyWithImpl(this._value, this._then);

  final _$CodeBlock _value;
  final $Res Function(_$CodeBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$CodeBlock(
      value == null ? _value.value : value as String,
    ));
  }
}

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
  String toString() {
    return 'ContentBlock.code(value: $value)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodeBlock &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CodeBlockCopyWith<_$CodeBlock> get copyWith =>
      __$$CodeBlockCopyWithImpl<_$CodeBlock>(this, _$identity);

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
    return code(value);
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
    return code?.call(value);
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
    if (code != null) {
      return code(value);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$CodeBlockToJson(this);
}

abstract class CodeBlock implements ContentBlock {
  const factory CodeBlock(String value) = _$CodeBlock;

  String get value;
  @JsonKey(ignore: true)
  _$$CodeBlockCopyWith<_$CodeBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TipBlockCopyWith<$Res> {
  factory _$$TipBlockCopyWith(
          _$TipBlock value, $Res Function(_$TipBlock) then) =
      __$$TipBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$TipBlockCopyWithImpl<$Res>
    implements _$$TipBlockCopyWith<$Res> {
  __$$TipBlockCopyWithImpl(this._value, this._then);

  final _$TipBlock _value;
  final $Res Function(_$TipBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$TipBlock(
      value == null ? _value.value : value as String,
    ));
  }
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
  String toString() {
    return 'ContentBlock.tip(value: $value)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TipBlock &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TipBlockCopyWith<_$TipBlock> get copyWith =>
      __$$TipBlockCopyWithImpl<_$TipBlock>(this, _$identity);

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
    return tip(value);
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
    return tip?.call(value);
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
    if (tip != null) {
      return tip(value);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$TipBlockToJson(this);
}

abstract class TipBlock implements ContentBlock {
  const factory TipBlock(String value) = _$TipBlock;

  String get value;
  @JsonKey(ignore: true)
  _$$TipBlockCopyWith<_$TipBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WarningBlockCopyWith<$Res> {
  factory _$$WarningBlockCopyWith(
          _$WarningBlock value, $Res Function(_$WarningBlock) then) =
      __$$WarningBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$WarningBlockCopyWithImpl<$Res>
    implements _$$WarningBlockCopyWith<$Res> {
  __$$WarningBlockCopyWithImpl(this._value, this._then);

  final _$WarningBlock _value;
  final $Res Function(_$WarningBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$WarningBlock(
      value == null ? _value.value : value as String,
    ));
  }
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
  String toString() {
    return 'ContentBlock.warning(value: $value)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarningBlock &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WarningBlockCopyWith<_$WarningBlock> get copyWith =>
      __$$WarningBlockCopyWithImpl<_$WarningBlock>(this, _$identity);

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
    return warning(value);
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
    return warning?.call(value);
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
    if (warning != null) {
      return warning(value);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$WarningBlockToJson(this);
}

abstract class WarningBlock implements ContentBlock {
  const factory WarningBlock(String value) = _$WarningBlock;

  String get value;
  @JsonKey(ignore: true)
  _$$WarningBlockCopyWith<_$WarningBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InteractiveExampleBlockCopyWith<$Res> {
  factory _$$InteractiveExampleBlockCopyWith(_$InteractiveExampleBlock value,
          $Res Function(_$InteractiveExampleBlock) then) =
      __$$InteractiveExampleBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> payload});
}

/// @nodoc
class __$$InteractiveExampleBlockCopyWithImpl<$Res>
    implements _$$InteractiveExampleBlockCopyWith<$Res> {
  __$$InteractiveExampleBlockCopyWithImpl(this._value, this._then);

  final _$InteractiveExampleBlock _value;
  final $Res Function(_$InteractiveExampleBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
  }) {
    return _then(_$InteractiveExampleBlock(
      payload == null ? _value.payload : payload as Map<String, dynamic>,
    ));
  }
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
  String toString() {
    return 'ContentBlock.interactive(payload: $payload)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InteractiveExampleBlock &&
            const DeepCollectionEquality().equals(other.payload, payload));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(payload));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InteractiveExampleBlockCopyWith<_$InteractiveExampleBlock> get copyWith =>
      __$$InteractiveExampleBlockCopyWithImpl<_$InteractiveExampleBlock>(
          this, _$identity);

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
    return interactive(payload);
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
    return interactive?.call(payload);
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
    if (interactive != null) {
      return interactive(payload);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$InteractiveExampleBlockToJson(this);
}

abstract class InteractiveExampleBlock implements ContentBlock {
  const factory InteractiveExampleBlock(Map<String, dynamic> payload) =
      _$InteractiveExampleBlock;

  Map<String, dynamic> get payload;
  @JsonKey(ignore: true)
  _$$InteractiveExampleBlockCopyWith<_$InteractiveExampleBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ListBlockCopyWith<$Res> {
  factory _$$ListBlockCopyWith(
          _$ListBlock value, $Res Function(_$ListBlock) then) =
      __$$ListBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> items});
}

/// @nodoc
class __$$ListBlockCopyWithImpl<$Res>
    implements _$$ListBlockCopyWith<$Res> {
  __$$ListBlockCopyWithImpl(this._value, this._then);

  final _$ListBlock _value;
  final $Res Function(_$ListBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$ListBlock(
      items == null ? _value.items : items as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ListBlock implements ListBlock {
  const _$ListBlock(this.items, {final String? $type})
      : $type = $type ?? 'list';

  factory _$ListBlock.fromJson(Map<String, dynamic> json) =>
      _$$ListBlockFromJson(json);

  @override
  final List<String> items;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ContentBlock.list(items: $items)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListBlock &&
            const DeepCollectionEquality().equals(other.items, items));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ListBlockCopyWith<_$ListBlock> get copyWith =>
      __$$ListBlockCopyWithImpl<_$ListBlock>(this, _$identity);

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
    return list(items);
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
    return list?.call(items);
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
    if (list != null) {
      return list(items);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$ListBlockToJson(this);
}

abstract class ListBlock implements ContentBlock {
  const factory ListBlock(List<String> items) = _$ListBlock;

  List<String> get items;
  @JsonKey(ignore: true)
  _$$ListBlockCopyWith<_$ListBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImageBlockCopyWith<$Res> {
  factory _$$ImageBlockCopyWith(
          _$ImageBlock value, $Res Function(_$ImageBlock) then) =
      __$$ImageBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({String url});
}

/// @nodoc
class __$$ImageBlockCopyWithImpl<$Res>
    implements _$$ImageBlockCopyWith<$Res> {
  __$$ImageBlockCopyWithImpl(this._value, this._then);

  final _$ImageBlock _value;
  final $Res Function(_$ImageBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
  }) {
    return _then(_$ImageBlock(
      url == null ? _value.url : url as String,
    ));
  }
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
  String toString() {
    return 'ContentBlock.image(url: $url)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageBlock &&
            (identical(other.url, url) || other.url == url));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageBlockCopyWith<_$ImageBlock> get copyWith =>
      __$$ImageBlockCopyWithImpl<_$ImageBlock>(this, _$identity);

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
    return image(url);
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
    return image?.call(url);
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
    if (image != null) {
      return image(url);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$ImageBlockToJson(this);
}

abstract class ImageBlock implements ContentBlock {
  const factory ImageBlock(String url) = _$ImageBlock;

  String get url;
  @JsonKey(ignore: true)
  _$$ImageBlockCopyWith<_$ImageBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoBlockCopyWith<$Res> {
  factory _$$VideoBlockCopyWith(
          _$VideoBlock value, $Res Function(_$VideoBlock) then) =
      __$$VideoBlockCopyWithImpl<$Res>;
  @useResult
  $Res call({String url});
}

/// @nodoc
class __$$VideoBlockCopyWithImpl<$Res>
    implements _$$VideoBlockCopyWith<$Res> {
  __$$VideoBlockCopyWithImpl(this._value, this._then);

  final _$VideoBlock _value;
  final $Res Function(_$VideoBlock) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
  }) {
    return _then(_$VideoBlock(
      url == null ? _value.url : url as String,
    ));
  }
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
  String toString() {
    return 'ContentBlock.video(url: $url)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoBlock &&
            (identical(other.url, url) || other.url == url));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoBlockCopyWith<_$VideoBlock> get copyWith =>
      __$$VideoBlockCopyWithImpl<_$VideoBlock>(this, _$identity);

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
    return video(url);
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
    return video?.call(url);
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
    if (video != null) {
      return video(url);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$VideoBlockToJson(this);
}

abstract class VideoBlock implements ContentBlock {
  const factory VideoBlock(String url) = _$VideoBlock;

  String get url;
  @JsonKey(ignore: true)
  _$$VideoBlockCopyWith<_$VideoBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Lesson {
  String get id => throw _privateConstructorUsedError;
  String get unitId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<ContentBlock> get content => throw _privateConstructorUsedError;
  String? get quizId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LessonCopyWith<Lesson> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonCopyWith<$Res> {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) then) =
      _$LessonCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String id,
      String unitId,
      String title,
      List<ContentBlock> content,
      String? quizId});
}

/// @nodoc
class _$LessonCopyWithImpl<$Res> implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._value, this._then);

  final Lesson _value;
  final $Res Function(Lesson) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? title = null,
    Object? content = null,
    Object? quizId = freezedUnnamed,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      unitId: null == unitId ? _value.unitId : unitId as String,
      title: null == title ? _value.title : title as String,
      content: null == content ? _value.content : content as List<ContentBlock>,
      quizId: freezedUnnamed == quizId ? _value.quizId : quizId as String?,
    ));
  }
}

/// @nodoc
abstract class _$$LessonCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$$LessonCopyWith(_$Lesson value, $Res Function(_$Lesson) then) =
      __$$LessonCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String unitId,
      String title,
      List<ContentBlock> content,
      String? quizId});
}

/// @nodoc
class __$$LessonCopyWithImpl<$Res> implements _$$LessonCopyWith<$Res> {
  __$$LessonCopyWithImpl(this._value, this._then);

  final _$Lesson _value;
  final $Res Function(_$Lesson) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? title = null,
    Object? content = null,
    Object? quizId = freezedUnnamed,
  }) {
    return _then(_$Lesson(
      id: null == id ? _value.id : id as String,
      unitId: null == unitId ? _value.unitId : unitId as String,
      title: null == title ? _value.title : title as String,
      content: null == content ? _value.content : content as List<ContentBlock>,
      quizId: freezedUnnamed == quizId ? _value.quizId : quizId as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Lesson implements Lesson {
  const _$Lesson(
      {required this.id,
      required this.unitId,
      required this.title,
      required this.content,
      this.quizId});

  factory _$Lesson.fromJson(Map<String, dynamic> json) =>
      _$$LessonFromJson(json);

  @override
  final String id;
  @override
  final String unitId;
  @override
  final String title;
  @override
  final List<ContentBlock> content;
  @override
  final String? quizId;

  @override
  String toString() {
    return 'Lesson(id: $id, unitId: $unitId, title: $title, content: $content, quizId: $quizId)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Lesson &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.quizId, quizId) || other.quizId == quizId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, unitId, title,
      const DeepCollectionEquality().hash(content), quizId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonCopyWith<_$Lesson> get copyWith =>
      __$$LessonCopyWithImpl<_$Lesson>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LessonToJson(this);
  }
}

abstract class _Lesson implements Lesson {
  const factory _Lesson(
      {required final String id,
      required final String unitId,
      required final String title,
      required final List<ContentBlock> content,
      final String? quizId}) = _$Lesson;

  factory _Lesson.fromJson(Map<String, dynamic> json) = _$Lesson.fromJson;

  @override
  String get id;
  @override
  String get unitId;
  @override
  String get title;
  @override
  List<ContentBlock> get content;
  @override
  String? get quizId;
  @override
  @JsonKey(ignore: true)
  _$$LessonCopyWith<_$Lesson> get copyWith =>
      throw _privateConstructorUsedError;
}

// Freezed utility constant
const Object freezedUnnamed = Object();
