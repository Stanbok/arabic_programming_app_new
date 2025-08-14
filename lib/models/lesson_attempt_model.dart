class LessonAttemptModel {
  final String id;
  final String lessonId;
  final String userId;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<int> answers;
  final DateTime attemptedAt;
  final int attemptNumber;
  final bool isPassed;
  final bool isFirstPass;
  final int xpAwarded;
  final int gemsAwarded;
  final int scoringTimeMs;
  final String status; // 'passed', 'failed', 'retake_after_pass'

  LessonAttemptModel({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.answers,
    required this.attemptedAt,
    required this.attemptNumber,
    required this.isPassed,
    required this.isFirstPass,
    required this.xpAwarded,
    required this.gemsAwarded,
    required this.scoringTimeMs,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'attemptedAt': attemptedAt.millisecondsSinceEpoch,
      'attemptNumber': attemptNumber,
      'isPassed': isPassed,
      'isFirstPass': isFirstPass,
      'xpAwarded': xpAwarded,
      'gemsAwarded': gemsAwarded,
      'scoringTimeMs': scoringTimeMs,
      'status': status,
    };
  }

  factory LessonAttemptModel.fromMap(Map<String, dynamic> map) {
    return LessonAttemptModel(
      id: map['id'] ?? '',
      lessonId: map['lessonId'] ?? '',
      userId: map['userId'] ?? '',
      score: map['score']?.toInt() ?? 0,
      correctAnswers: map['correctAnswers']?.toInt() ?? 0,
      totalQuestions: map['totalQuestions']?.toInt() ?? 0,
      answers: List<int>.from(map['answers'] ?? []),
      attemptedAt: DateTime.fromMillisecondsSinceEpoch(map['attemptedAt'] ?? 0),
      attemptNumber: map['attemptNumber']?.toInt() ?? 1,
      isPassed: map['isPassed'] ?? false,
      isFirstPass: map['isFirstPass'] ?? false,
      xpAwarded: map['xpAwarded']?.toInt() ?? 0,
      gemsAwarded: map['gemsAwarded']?.toInt() ?? 0,
      scoringTimeMs: map['scoringTimeMs']?.toInt() ?? 0,
      status: map['status'] ?? 'failed',
    );
  }
}

class LessonStatistics {
  final String lessonId;
  final int totalAttempts;
  final int passedAttempts;
  final int failedAttempts;
  final double bestScore;
  final double averageScore;
  final DateTime? firstAttemptAt;
  final DateTime? lastAttemptAt;
  final DateTime? firstPassAt;
  final bool isCompleted;
  final int totalXPEarned;
  final int totalGemsEarned;
  final double averageScoringTime;

  LessonStatistics({
    required this.lessonId,
    required this.totalAttempts,
    required this.passedAttempts,
    required this.failedAttempts,
    required this.bestScore,
    required this.averageScore,
    this.firstAttemptAt,
    this.lastAttemptAt,
    this.firstPassAt,
    required this.isCompleted,
    required this.totalXPEarned,
    required this.totalGemsEarned,
    required this.averageScoringTime,
  });

  factory LessonStatistics.fromAttempts(String lessonId, List<LessonAttemptModel> attempts) {
    if (attempts.isEmpty) {
      return LessonStatistics(
        lessonId: lessonId,
        totalAttempts: 0,
        passedAttempts: 0,
        failedAttempts: 0,
        bestScore: 0.0,
        averageScore: 0.0,
        isCompleted: false,
        totalXPEarned: 0,
        totalGemsEarned: 0,
        averageScoringTime: 0.0,
      );
    }

    final passedAttempts = attempts.where((a) => a.isPassed).length;
    final failedAttempts = attempts.length - passedAttempts;
    final bestScore = attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b).toDouble();
    final averageScore = attempts.map((a) => a.score).reduce((a, b) => a + b) / attempts.length;
    final totalXP = attempts.map((a) => a.xpAwarded).reduce((a, b) => a + b);
    final totalGems = attempts.map((a) => a.gemsAwarded).reduce((a, b) => a + b);
    final averageScoringTime = attempts.map((a) => a.scoringTimeMs).reduce((a, b) => a + b) / attempts.length;
    
    attempts.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    final firstPass = attempts.where((a) => a.isPassed).firstOrNull;

    return LessonStatistics(
      lessonId: lessonId,
      totalAttempts: attempts.length,
      passedAttempts: passedAttempts,
      failedAttempts: failedAttempts,
      bestScore: bestScore,
      averageScore: averageScore,
      firstAttemptAt: attempts.first.attemptedAt,
      lastAttemptAt: attempts.last.attemptedAt,
      firstPassAt: firstPass?.attemptedAt,
      isCompleted: passedAttempts > 0,
      totalXPEarned: totalXP,
      totalGemsEarned: totalGems,
      averageScoringTime: averageScoringTime,
    );
  }
}
