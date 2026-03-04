// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_empty_else, duplicate_ignore, comment_references, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas

part of 'quiz.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

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
      throw CheckedFromJsonException(json, 'runtimeType', 'Question',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$Question {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String prompt, List<String> options,
            String answer, String? explanation)
        multipleChoice,
    required TResult Function(
            String prompt, String answer, String? explanation)
        fillBlank,
    required TResult Function(
            String prompt, String answer, String? explanation)
        codeCompletion,
    required TResult Function(String prompt, bool answer, String? explanation)
        trueFalse,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult? Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult? Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult? Function(String prompt, bool answer, String? explanation)?
        trueFalse,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult Function(String prompt, bool answer, String? explanation)?
        trueFalse,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionCopyWith<$Res> {
  factory $QuestionCopyWith(Question value, $Res Function(Question) then) =
      _$QuestionCopyWithImpl<$Res>;
}

/// @nodoc
class _$QuestionCopyWithImpl<$Res> implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._value, this._then);

  final Question _value;
  final $Res Function(Question) _then;
}

/// @nodoc
abstract class _$$MultipleChoiceQuestionCopyWith<$Res> {
  factory _$$MultipleChoiceQuestionCopyWith(_$MultipleChoiceQuestion value,
          $Res Function(_$MultipleChoiceQuestion) then) =
      __$$MultipleChoiceQuestionCopyWithImpl<$Res>;
  @useResult
  $Res call({String prompt, List<String> options, String answer, String? explanation});
}

/// @nodoc
class __$$MultipleChoiceQuestionCopyWithImpl<$Res>
    implements _$$MultipleChoiceQuestionCopyWith<$Res> {
  __$$MultipleChoiceQuestionCopyWithImpl(this._value, this._then);

  final _$MultipleChoiceQuestion _value;
  final $Res Function(_$MultipleChoiceQuestion) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt = null,
    Object? options = null,
    Object? answer = null,
    Object? explanation = freezedUnnamed,
  }) {
    return _then(_$MultipleChoiceQuestion(
      prompt: null == prompt ? _value.prompt : prompt as String,
      options: null == options ? _value.options : options as List<String>,
      answer: null == answer ? _value.answer : answer as String,
      explanation: freezedUnnamed == explanation ? _value.explanation : explanation as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MultipleChoiceQuestion implements MultipleChoiceQuestion {
  const _$MultipleChoiceQuestion(
      {required this.prompt,
      required this.options,
      required this.answer,
      this.explanation,
      final String? $type})
      : $type = $type ?? 'multipleChoice';

  factory _$MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) =>
      _$$MultipleChoiceQuestionFromJson(json);

  @override
  final String prompt;
  @override
  final List<String> options;
  @override
  final String answer;
  @override
  final String? explanation;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Question.multipleChoice(prompt: $prompt, options: $options, answer: $answer, explanation: $explanation)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MultipleChoiceQuestion &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            const DeepCollectionEquality().equals(other.options, options) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @override
  int get hashCode => Object.hash(runtimeType, prompt,
      const DeepCollectionEquality().hash(options), answer, explanation);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MultipleChoiceQuestionCopyWith<_$MultipleChoiceQuestion> get copyWith =>
      __$$MultipleChoiceQuestionCopyWithImpl<_$MultipleChoiceQuestion>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String prompt, List<String> options,
            String answer, String? explanation)
        multipleChoice,
    required TResult Function(
            String prompt, String answer, String? explanation)
        fillBlank,
    required TResult Function(
            String prompt, String answer, String? explanation)
        codeCompletion,
    required TResult Function(String prompt, bool answer, String? explanation)
        trueFalse,
  }) {
    return multipleChoice(prompt, options, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult? Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult? Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult? Function(String prompt, bool answer, String? explanation)?
        trueFalse,
  }) {
    return multipleChoice?.call(prompt, options, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult Function(String prompt, bool answer, String? explanation)?
        trueFalse,
    required TResult orElse(),
  }) {
    if (multipleChoice != null) {
      return multipleChoice(prompt, options, answer, explanation);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$MultipleChoiceQuestionToJson(this);
}

abstract class MultipleChoiceQuestion implements Question {
  const factory MultipleChoiceQuestion(
      {required final String prompt,
      required final List<String> options,
      required final String answer,
      final String? explanation}) = _$MultipleChoiceQuestion;

  String get prompt;
  List<String> get options;
  String get answer;
  String? get explanation;
  @JsonKey(ignore: true)
  _$$MultipleChoiceQuestionCopyWith<_$MultipleChoiceQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FillBlankQuestionCopyWith<$Res> {
  factory _$$FillBlankQuestionCopyWith(_$FillBlankQuestion value,
          $Res Function(_$FillBlankQuestion) then) =
      __$$FillBlankQuestionCopyWithImpl<$Res>;
  @useResult
  $Res call({String prompt, String answer, String? explanation});
}

/// @nodoc
class __$$FillBlankQuestionCopyWithImpl<$Res>
    implements _$$FillBlankQuestionCopyWith<$Res> {
  __$$FillBlankQuestionCopyWithImpl(this._value, this._then);

  final _$FillBlankQuestion _value;
  final $Res Function(_$FillBlankQuestion) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt = null,
    Object? answer = null,
    Object? explanation = freezedUnnamed,
  }) {
    return _then(_$FillBlankQuestion(
      prompt: null == prompt ? _value.prompt : prompt as String,
      answer: null == answer ? _value.answer : answer as String,
      explanation: freezedUnnamed == explanation ? _value.explanation : explanation as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FillBlankQuestion implements FillBlankQuestion {
  const _$FillBlankQuestion(
      {required this.prompt,
      required this.answer,
      this.explanation,
      final String? $type})
      : $type = $type ?? 'fillBlank';

  factory _$FillBlankQuestion.fromJson(Map<String, dynamic> json) =>
      _$$FillBlankQuestionFromJson(json);

  @override
  final String prompt;
  @override
  final String answer;
  @override
  final String? explanation;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Question.fillBlank(prompt: $prompt, answer: $answer, explanation: $explanation)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FillBlankQuestion &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, prompt, answer, explanation);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FillBlankQuestionCopyWith<_$FillBlankQuestion> get copyWith =>
      __$$FillBlankQuestionCopyWithImpl<_$FillBlankQuestion>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String prompt, List<String> options,
            String answer, String? explanation)
        multipleChoice,
    required TResult Function(
            String prompt, String answer, String? explanation)
        fillBlank,
    required TResult Function(
            String prompt, String answer, String? explanation)
        codeCompletion,
    required TResult Function(String prompt, bool answer, String? explanation)
        trueFalse,
  }) {
    return fillBlank(prompt, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult? Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult? Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult? Function(String prompt, bool answer, String? explanation)?
        trueFalse,
  }) {
    return fillBlank?.call(prompt, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult Function(String prompt, bool answer, String? explanation)?
        trueFalse,
    required TResult orElse(),
  }) {
    if (fillBlank != null) {
      return fillBlank(prompt, answer, explanation);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$FillBlankQuestionToJson(this);
}

abstract class FillBlankQuestion implements Question {
  const factory FillBlankQuestion(
      {required final String prompt,
      required final String answer,
      final String? explanation}) = _$FillBlankQuestion;

  String get prompt;
  String get answer;
  String? get explanation;
  @JsonKey(ignore: true)
  _$$FillBlankQuestionCopyWith<_$FillBlankQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CodeCompletionQuestionCopyWith<$Res> {
  factory _$$CodeCompletionQuestionCopyWith(_$CodeCompletionQuestion value,
          $Res Function(_$CodeCompletionQuestion) then) =
      __$$CodeCompletionQuestionCopyWithImpl<$Res>;
  @useResult
  $Res call({String prompt, String answer, String? explanation});
}

/// @nodoc
class __$$CodeCompletionQuestionCopyWithImpl<$Res>
    implements _$$CodeCompletionQuestionCopyWith<$Res> {
  __$$CodeCompletionQuestionCopyWithImpl(this._value, this._then);

  final _$CodeCompletionQuestion _value;
  final $Res Function(_$CodeCompletionQuestion) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt = null,
    Object? answer = null,
    Object? explanation = freezedUnnamed,
  }) {
    return _then(_$CodeCompletionQuestion(
      prompt: null == prompt ? _value.prompt : prompt as String,
      answer: null == answer ? _value.answer : answer as String,
      explanation: freezedUnnamed == explanation ? _value.explanation : explanation as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CodeCompletionQuestion implements CodeCompletionQuestion {
  const _$CodeCompletionQuestion(
      {required this.prompt,
      required this.answer,
      this.explanation,
      final String? $type})
      : $type = $type ?? 'codeCompletion';

  factory _$CodeCompletionQuestion.fromJson(Map<String, dynamic> json) =>
      _$$CodeCompletionQuestionFromJson(json);

  @override
  final String prompt;
  @override
  final String answer;
  @override
  final String? explanation;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Question.codeCompletion(prompt: $prompt, answer: $answer, explanation: $explanation)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodeCompletionQuestion &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, prompt, answer, explanation);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CodeCompletionQuestionCopyWith<_$CodeCompletionQuestion> get copyWith =>
      __$$CodeCompletionQuestionCopyWithImpl<_$CodeCompletionQuestion>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String prompt, List<String> options,
            String answer, String? explanation)
        multipleChoice,
    required TResult Function(
            String prompt, String answer, String? explanation)
        fillBlank,
    required TResult Function(
            String prompt, String answer, String? explanation)
        codeCompletion,
    required TResult Function(String prompt, bool answer, String? explanation)
        trueFalse,
  }) {
    return codeCompletion(prompt, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult? Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult? Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult? Function(String prompt, bool answer, String? explanation)?
        trueFalse,
  }) {
    return codeCompletion?.call(prompt, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult Function(String prompt, bool answer, String? explanation)?
        trueFalse,
    required TResult orElse(),
  }) {
    if (codeCompletion != null) {
      return codeCompletion(prompt, answer, explanation);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$CodeCompletionQuestionToJson(this);
}

abstract class CodeCompletionQuestion implements Question {
  const factory CodeCompletionQuestion(
      {required final String prompt,
      required final String answer,
      final String? explanation}) = _$CodeCompletionQuestion;

  String get prompt;
  String get answer;
  String? get explanation;
  @JsonKey(ignore: true)
  _$$CodeCompletionQuestionCopyWith<_$CodeCompletionQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TrueFalseQuestionCopyWith<$Res> {
  factory _$$TrueFalseQuestionCopyWith(_$TrueFalseQuestion value,
          $Res Function(_$TrueFalseQuestion) then) =
      __$$TrueFalseQuestionCopyWithImpl<$Res>;
  @useResult
  $Res call({String prompt, bool answer, String? explanation});
}

/// @nodoc
class __$$TrueFalseQuestionCopyWithImpl<$Res>
    implements _$$TrueFalseQuestionCopyWith<$Res> {
  __$$TrueFalseQuestionCopyWithImpl(this._value, this._then);

  final _$TrueFalseQuestion _value;
  final $Res Function(_$TrueFalseQuestion) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt = null,
    Object? answer = null,
    Object? explanation = freezedUnnamed,
  }) {
    return _then(_$TrueFalseQuestion(
      prompt: null == prompt ? _value.prompt : prompt as String,
      answer: null == answer ? _value.answer : answer as bool,
      explanation: freezedUnnamed == explanation ? _value.explanation : explanation as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrueFalseQuestion implements TrueFalseQuestion {
  const _$TrueFalseQuestion(
      {required this.prompt,
      required this.answer,
      this.explanation,
      final String? $type})
      : $type = $type ?? 'trueFalse';

  factory _$TrueFalseQuestion.fromJson(Map<String, dynamic> json) =>
      _$$TrueFalseQuestionFromJson(json);

  @override
  final String prompt;
  @override
  final bool answer;
  @override
  final String? explanation;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Question.trueFalse(prompt: $prompt, answer: $answer, explanation: $explanation)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrueFalseQuestion &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, prompt, answer, explanation);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TrueFalseQuestionCopyWith<_$TrueFalseQuestion> get copyWith =>
      __$$TrueFalseQuestionCopyWithImpl<_$TrueFalseQuestion>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String prompt, List<String> options,
            String answer, String? explanation)
        multipleChoice,
    required TResult Function(
            String prompt, String answer, String? explanation)
        fillBlank,
    required TResult Function(
            String prompt, String answer, String? explanation)
        codeCompletion,
    required TResult Function(String prompt, bool answer, String? explanation)
        trueFalse,
  }) {
    return trueFalse(prompt, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult? Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult? Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult? Function(String prompt, bool answer, String? explanation)?
        trueFalse,
  }) {
    return trueFalse?.call(prompt, answer, explanation);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String prompt, List<String> options, String answer,
            String? explanation)?
        multipleChoice,
    TResult Function(String prompt, String answer, String? explanation)?
        fillBlank,
    TResult Function(String prompt, String answer, String? explanation)?
        codeCompletion,
    TResult Function(String prompt, bool answer, String? explanation)?
        trueFalse,
    required TResult orElse(),
  }) {
    if (trueFalse != null) {
      return trueFalse(prompt, answer, explanation);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() => _$$TrueFalseQuestionToJson(this);
}

abstract class TrueFalseQuestion implements Question {
  const factory TrueFalseQuestion(
      {required final String prompt,
      required final bool answer,
      final String? explanation}) = _$TrueFalseQuestion;

  String get prompt;
  bool get answer;
  String? get explanation;
  @JsonKey(ignore: true)
  _$$TrueFalseQuestionCopyWith<_$TrueFalseQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Quiz {
  String get id => throw _privateConstructorUsedError;
  String get lessonId => throw _privateConstructorUsedError;
  List<Question> get questions => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuizCopyWith<Quiz> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizCopyWith<$Res> {
  factory $QuizCopyWith(Quiz value, $Res Function(Quiz) then) =
      _$QuizCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, String lessonId, List<Question> questions});
}

/// @nodoc
class _$QuizCopyWithImpl<$Res> implements $QuizCopyWith<$Res> {
  _$QuizCopyWithImpl(this._value, this._then);

  final Quiz _value;
  final $Res Function(Quiz) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? questions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      lessonId: null == lessonId ? _value.lessonId : lessonId as String,
      questions: null == questions ? _value.questions : questions as List<Question>,
    ));
  }
}

/// @nodoc
abstract class _$$QuizCopyWith<$Res> implements $QuizCopyWith<$Res> {
  factory _$$QuizCopyWith(_$Quiz value, $Res Function(_$Quiz) then) =
      __$$QuizCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String lessonId, List<Question> questions});
}

/// @nodoc
class __$$QuizCopyWithImpl<$Res> implements _$$QuizCopyWith<$Res> {
  __$$QuizCopyWithImpl(this._value, this._then);

  final _$Quiz _value;
  final $Res Function(_$Quiz) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? questions = null,
  }) {
    return _then(_$Quiz(
      id: null == id ? _value.id : id as String,
      lessonId: null == lessonId ? _value.lessonId : lessonId as String,
      questions: null == questions ? _value.questions : questions as List<Question>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Quiz implements Quiz {
  const _$Quiz(
      {required this.id, required this.lessonId, required this.questions});

  factory _$Quiz.fromJson(Map<String, dynamic> json) =>
      _$$QuizFromJson(json);

  @override
  final String id;
  @override
  final String lessonId;
  @override
  final List<Question> questions;

  @override
  String toString() {
    return 'Quiz(id: $id, lessonId: $lessonId, questions: $questions)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Quiz &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lessonId, lessonId) ||
                other.lessonId == lessonId) &&
            const DeepCollectionEquality()
                .equals(other.questions, questions));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, lessonId,
      const DeepCollectionEquality().hash(questions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizCopyWith<_$Quiz> get copyWith =>
      __$$QuizCopyWithImpl<_$Quiz>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizToJson(this);
  }
}

abstract class _Quiz implements Quiz {
  const factory _Quiz(
      {required final String id,
      required final String lessonId,
      required final List<Question> questions}) = _$Quiz;

  factory _Quiz.fromJson(Map<String, dynamic> json) = _$Quiz.fromJson;

  @override
  String get id;
  @override
  String get lessonId;
  @override
  List<Question> get questions;
  @override
  @JsonKey(ignore: true)
  _$$QuizCopyWith<_$Quiz> get copyWith => throw _privateConstructorUsedError;
}

// Freezed utility constant
const Object freezedUnnamed = Object();
