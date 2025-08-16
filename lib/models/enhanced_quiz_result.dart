class EnhancedQuizResult {
  final String id;
  final String lessonId;
  final String userId;
  final int score;
  final int totalQuestions;
  final double percentage;
  final DateTime completedAt;
  final int timeSpent; // in seconds
  final Map<String, dynamic> questionResults;
  final Map<String, int> questionTypeStats;
  final int hintsUsed;
  final List<String> weakAreas;
  final List<String> strongAreas;
  final double difficultyRating;
  final bool isPassed;

  EnhancedQuizResult({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.completedAt,
    required this.timeSpent,
    required this.questionResults,
    required this.questionTypeStats,
    required this.hintsUsed,
    required this.weakAreas,
    required this.strongAreas,
    required this.difficultyRating,
    required this.isPassed,
  });

  factory EnhancedQuizResult.fromJson(Map<String, dynamic> json) {
    return EnhancedQuizResult(
      id: json['id'] ?? '',
      lessonId: json['lessonId'] ?? '',
      userId: json['userId'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      completedAt: DateTime.parse(json['completedAt'] ?? DateTime.now().toIso8601String()),
      timeSpent: json['timeSpent'] ?? 0,
      questionResults: Map<String, dynamic>.from(json['questionResults'] ?? {}),
      questionTypeStats: Map<String, int>.from(json['questionTypeStats'] ?? {}),
      hintsUsed: json['hintsUsed'] ?? 0,
      weakAreas: List<String>.from(json['weakAreas'] ?? []),
      strongAreas: List<String>.from(json['strongAreas'] ?? []),
      difficultyRating: (json['difficultyRating'] ?? 0.0).toDouble(),
      isPassed: json['isPassed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'completedAt': completedAt.toIso8601String(),
      'timeSpent': timeSpent,
      'questionResults': questionResults,
      'questionTypeStats': questionTypeStats,
      'hintsUsed': hintsUsed,
      'weakAreas': weakAreas,
      'strongAreas': strongAreas,
      'difficultyRating': difficultyRating,
      'isPassed': isPassed,
    };
  }

  EnhancedQuizResult copyWith({
    String? id,
    String? lessonId,
    String? userId,
    int? score,
    int? totalQuestions,
    double? percentage,
    DateTime? completedAt,
    int? timeSpent,
    Map<String, dynamic>? questionResults,
    Map<String, int>? questionTypeStats,
    int? hintsUsed,
    List<String>? weakAreas,
    List<String>? strongAreas,
    double? difficultyRating,
    bool? isPassed,
  }) {
    return EnhancedQuizResult(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      percentage: percentage ?? this.percentage,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      questionResults: questionResults ?? this.questionResults,
      questionTypeStats: questionTypeStats ?? this.questionTypeStats,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      weakAreas: weakAreas ?? this.weakAreas,
      strongAreas: strongAreas ?? this.strongAreas,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      isPassed: isPassed ?? this.isPassed,
    );
  }
}
