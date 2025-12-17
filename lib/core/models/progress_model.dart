class ProgressModel {
  final String lessonId;
  final bool completed;
  final DateTime? completedAt;
  final int quizScore;
  final int totalQuestions;

  ProgressModel({
    required this.lessonId,
    required this.completed,
    this.completedAt,
    required this.quizScore,
    required this.totalQuestions,
  });

  factory ProgressModel.fromMap(Map<String, dynamic> map, String lessonId) {
    return ProgressModel(
      lessonId: lessonId,
      completed: map['completed'] ?? false,
      completedAt: map['completedAt']?.toDate(),
      quizScore: map['quizScore'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'completedAt': completedAt,
      'quizScore': quizScore,
      'totalQuestions': totalQuestions,
    };
  }

  double get percentage => totalQuestions > 0 ? quizScore / totalQuestions : 0;
}
