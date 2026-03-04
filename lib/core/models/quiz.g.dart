// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType'] as String?) {
    case 'multipleChoice':
      return MultipleChoiceQuestion.fromJson(json);
    case 'fillBlank':
      return FillBlankQuestion.fromJson(json);
    case 'codeCompletion':
      return CodeCompletionQuestion.fromJson(json);
    case 'trueFalse':
      return TrueFalseQuestion.fromJson(json);
    default:
      throw Exception('Unknown Question type: ${json['runtimeType']}');
  }
}

Map<String, dynamic> _$QuestionToJson(Question instance) {
  return instance.toJson();
}

_$MultipleChoiceQuestion _$$MultipleChoiceQuestionFromJson(
        Map<String, dynamic> json) =>
    _$MultipleChoiceQuestion(
      prompt: json['prompt'] as String,
      options: List<String>.from(json['options'] as List<dynamic>),
      answer: json['answer'] as String,
      explanation: json['explanation'] as String?,
      $type: json['runtimeType'] as String? ?? 'multipleChoice',
    );

Map<String, dynamic> _$$MultipleChoiceQuestionToJson(
        _$MultipleChoiceQuestion instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'options': instance.options,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'runtimeType': instance.$type,
    };

_$FillBlankQuestion _$$FillBlankQuestionFromJson(Map<String, dynamic> json) =>
    _$FillBlankQuestion(
      prompt: json['prompt'] as String,
      answer: json['answer'] as String,
      explanation: json['explanation'] as String?,
      $type: json['runtimeType'] as String? ?? 'fillBlank',
    );

Map<String, dynamic> _$$FillBlankQuestionToJson(_$FillBlankQuestion instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'runtimeType': instance.$type,
    };

_$CodeCompletionQuestion _$$CodeCompletionQuestionFromJson(
        Map<String, dynamic> json) =>
    _$CodeCompletionQuestion(
      prompt: json['prompt'] as String,
      answer: json['answer'] as String,
      explanation: json['explanation'] as String?,
      $type: json['runtimeType'] as String? ?? 'codeCompletion',
    );

Map<String, dynamic> _$$CodeCompletionQuestionToJson(
        _$CodeCompletionQuestion instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'runtimeType': instance.$type,
    };

_$TrueFalseQuestion _$$TrueFalseQuestionFromJson(Map<String, dynamic> json) =>
    _$TrueFalseQuestion(
      prompt: json['prompt'] as String,
      answer: json['answer'] as bool,
      explanation: json['explanation'] as String?,
      $type: json['runtimeType'] as String? ?? 'trueFalse',
    );

Map<String, dynamic> _$$TrueFalseQuestionToJson(_$TrueFalseQuestion instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'runtimeType': instance.$type,
    };

_$Quiz _$$QuizFromJson(Map<String, dynamic> json) => _$Quiz(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$QuizToJson(_$Quiz instance) => <String, dynamic>{
      'id': instance.id,
      'lessonId': instance.lessonId,
      'questions': instance.questions,
    };
