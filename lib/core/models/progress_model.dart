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
      completedAt: map['completedAt'] is DateTime 
          ? map['completedAt'] 
          : (map['completedAt'] != null 
              ? (map['completedAt'].toDate != null 
                  ? map['completedAt'].toDate() 
                  : DateTime.tryParse(map['completedAt'].toString()))
              : null),
      quizScore: map['quizScore'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'quizScore': quizScore,
      'totalQuestions': totalQuestions,
    };
  }

  double get percentage => totalQuestions > 0 ? quizScore / totalQuestions : 0;
}
