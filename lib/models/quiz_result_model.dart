class QuizResultModel {
  final String lessonId;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<int> answers;
  final DateTime completedAt;

  QuizResultModel({
    required this.lessonId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.answers,
    required this.completedAt,
  });

  bool get isPassed => score >= 70;
  
  String get grade {
    if (score >= 95) return 'ممتاز';
    if (score >= 85) return 'جيد جداً';
    if (score >= 75) return 'جيد';
    if (score >= 70) return 'مقبول';
    return 'راسب';
  }
  
  int get stars {
    if (score >= 95) return 3;
    if (score >= 85) return 2;
    if (score >= 70) return 1;
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizResultModel.fromMap(Map<String, dynamic> map) {
    return QuizResultModel(
      lessonId: map['lessonId'] ?? '',
      score: map['score'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      answers: List<int>.from(map['answers'] ?? []),
      completedAt: DateTime.parse(map['completedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
