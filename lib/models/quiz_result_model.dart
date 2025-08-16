import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResultModel {
  final String lessonId;
  final int score; // percentage
  final int correctAnswers;
  final int totalQuestions;
  final List<int> answers; // user's selected answer indices
  final DateTime completedAt;
  final double percentage;

  QuizResultModel({
    required this.lessonId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.answers,
    required this.completedAt,
    double? percentage,
  }) : percentage = percentage ?? score.toDouble();

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'completedAt': Timestamp.fromDate(completedAt),
      'percentage': percentage,
    };
  }

  factory QuizResultModel.fromMap(Map<String, dynamic> map) {
    return QuizResultModel(
      lessonId: map['lessonId'] ?? '',
      score: map['score'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      answers: List<int>.from(map['answers'] ?? []),
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      percentage: (map['percentage'] ?? map['score'] ?? 0).toDouble(),
    );
  }

  bool get isPassed => score >= 70; // 70% to pass

  String get grade {
    if (score >= 90) return 'ممتاز';
    if (score >= 80) return 'جيد جداً';
    if (score >= 70) return 'جيد';
    if (score >= 60) return 'مقبول';
    return 'راسب';
  }

  int get stars {
    if (score >= 90) return 3;
    if (score >= 70) return 2;
    if (score >= 50) return 1;
    return 0;
  }
}
