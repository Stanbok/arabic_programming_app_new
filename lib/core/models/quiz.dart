import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz.g.dart';
part 'quiz.freezed.dart';

enum QuestionType { multipleChoice, fillBlank, codeCompletion, trueFalse }

// used for serialization if needed
QuestionType questionTypeFromString(String type) {
  switch (type) {
    case 'multipleChoice':
      return QuestionType.multipleChoice;
    case 'fillBlank':
      return QuestionType.fillBlank;
    case 'codeCompletion':
      return QuestionType.codeCompletion;
    case 'trueFalse':
      return QuestionType.trueFalse;
    default:
      throw Exception('Unknown question type: $type');
  }
}

@freezed
class Question with _$Question {
  const factory Question.multipleChoice({
    required String prompt,
    required List<String> options,
    required String answer,
    String? explanation,
  }) = MultipleChoiceQuestion;

  const factory Question.fillBlank({
    required String prompt,
    required String answer,
    String? explanation,
  }) = FillBlankQuestion;

  const factory Question.codeCompletion({
    required String prompt,
    required String answer,
    String? explanation,
  }) = CodeCompletionQuestion;

  const factory Question.trueFalse({
    required String prompt,
    required bool answer,
    String? explanation,
  }) = TrueFalseQuestion;
}

@freezed
class Quiz with _$Quiz {
  const factory Quiz({
    required String id,
    required String lessonId,
    required List<Question> questions,
  }) = _Quiz;

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);
}
