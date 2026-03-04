// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      throw Exception('Unknown ContentBlock type: ${json['runtimeType']}');
  }
}

Map<String, dynamic> _$ContentBlockToJson(ContentBlock instance) {
  return instance.toJson();
}

_$TextBlock _$TextBlockFromJson(Map<String, dynamic> json) => _$TextBlock(
      json['value'] as String,
      $type: json['runtimeType'] as String? ?? 'text',
    );

Map<String, dynamic> _$$TextBlockToJson(_$TextBlock instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$CodeBlock _$CodeBlockFromJson(Map<String, dynamic> json) => _$CodeBlock(
      json['value'] as String,
      $type: json['runtimeType'] as String? ?? 'code',
    );

Map<String, dynamic> _$$CodeBlockToJson(_$CodeBlock instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$TipBlock _$TipBlockFromJson(Map<String, dynamic> json) => _$TipBlock(
      json['value'] as String,
      $type: json['runtimeType'] as String? ?? 'tip',
    );

Map<String, dynamic> _$$TipBlockToJson(_$TipBlock instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$WarningBlock _$WarningBlockFromJson(Map<String, dynamic> json) =>
    _$WarningBlock(
      json['value'] as String,
      $type: json['runtimeType'] as String? ?? 'warning',
    );

Map<String, dynamic> _$$WarningBlockToJson(_$WarningBlock instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$InteractiveExampleBlock _$InteractiveExampleBlockFromJson(
        Map<String, dynamic> json) =>
    _$InteractiveExampleBlock(
      Map<String, dynamic>.from(json['payload'] as Map),
      $type: json['runtimeType'] as String? ?? 'interactive',
    );

Map<String, dynamic> _$$InteractiveExampleBlockToJson(
        _$InteractiveExampleBlock instance) =>
    <String, dynamic>{
      'payload': instance.payload,
      'runtimeType': instance.$type,
    };

_$ListBlock _$ListBlockFromJson(Map<String, dynamic> json) => _$ListBlock(
      List<String>.from(json['items'] as List),
      $type: json['runtimeType'] as String? ?? 'list',
    );

Map<String, dynamic> _$$ListBlockToJson(_$ListBlock instance) =>
    <String, dynamic>{
      'items': instance.items,
      'runtimeType': instance.$type,
    };

_$ImageBlock _$ImageBlockFromJson(Map<String, dynamic> json) => _$ImageBlock(
      json['url'] as String,
      $type: json['runtimeType'] as String? ?? 'image',
    );

Map<String, dynamic> _$$ImageBlockToJson(_$ImageBlock instance) =>
    <String, dynamic>{
      'url': instance.url,
      'runtimeType': instance.$type,
    };

_$VideoBlock _$VideoBlockFromJson(Map<String, dynamic> json) => _$VideoBlock(
      json['url'] as String,
      $type: json['runtimeType'] as String? ?? 'video',
    );

Map<String, dynamic> _$$VideoBlockToJson(_$VideoBlock instance) =>
    <String, dynamic>{
      'url': instance.url,
      'runtimeType': instance.$type,
    };

_$Lesson _$LessonFromJson(Map<String, dynamic> json) => _$Lesson(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      title: json['title'] as String,
      content: (json['content'] as List<dynamic>)
          .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      quizId: json['quizId'] as String?,
    );

Map<String, dynamic> _$$LessonToJson(_$Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'title': instance.title,
      'content': instance.content,
      'quizId': instance.quizId,
    };
