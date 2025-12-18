import 'package:hive/hive.dart';

part 'quiz_result_model.g.dart';

@HiveType(typeId: 7)
class QuizResultModel extends HiveObject {
  @HiveField(0)
  final String lessonId;

  @HiveField(1)
  final int totalQuestions;

  @HiveField(2)
  final int correctAnswers;

  @HiveField(3)
  final int wrongAnswers;

  @HiveField(4)
  final int skippedAnswers;

  @HiveField(5)
  final int timeTakenSeconds;

  @HiveField(6)
  final DateTime completedAt;

  @HiveField(7)
  final List<QuestionResult> questionResults;

  QuizResultModel({
    required this.lessonId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.timeTakenSeconds,
    required this.completedAt,
    required this.questionResults,
  });

  double get scorePercentage => 
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  bool get isPassed => scorePercentage >= 70;

  int get starsEarned {
    if (scorePercentage >= 90) return 3;
    if (scorePercentage >= 70) return 2;
    if (scorePercentage >= 50) return 1;
    return 0;
  }

  String get formattedTime {
    final minutes = timeTakenSeconds ~/ 60;
    final seconds = timeTakenSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

@HiveType(typeId: 8)
class QuestionResult extends HiveObject {
  @HiveField(0)
  final String questionId;

  @HiveField(1)
  final String questionText;

  @HiveField(2)
  final String userAnswer;

  @HiveField(3)
  final String correctAnswer;

  @HiveField(4)
  final bool isCorrect;

  @HiveField(5)
  final bool isSkipped;

  QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.isSkipped,
  });
}
