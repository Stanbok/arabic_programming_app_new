class QuizUploadModel {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuizUploadModel({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizUploadModel.fromMap(Map<String, dynamic> map) {
    return QuizUploadModel(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }

  factory QuizUploadModel.fromQuizQuestionModel(dynamic quiz) {
    return QuizUploadModel(
      question: quiz.question,
      options: List<String>.from(quiz.options),
      correctAnswerIndex: quiz.correctAnswerIndex,
      explanation: quiz.explanation,
    );
  }
}
