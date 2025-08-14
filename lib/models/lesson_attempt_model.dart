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

  // Calculate grade based on score
  String get grade {
    if (score >= 95) return 'ممتاز';
    if (score >= 85) return 'جيد جداً';
    if (score >= 75) return 'جيد';
    if (score >= 70) return 'مقبول';
    return 'راسب';
  }

  // Get number of stars based on score
  int get stars {
    if (score >= 90) return 3;
    if (score >= 80) return 2;
    if (score >= 70) return 1;
    return 0;
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'attemptedAt': attemptedAt.toIso8601String(),
      'attemptNumber': attemptNumber,
      'isPassed': isPassed,
      'isFirstPass': isFirstPass,
      'xpAwarded': xpAwarded,
      'gemsAwarded': gemsAwarded,
      'scoringTimeMs': scoringTimeMs,
      'status': status,
    };
  }

  // Create from Map
  factory LessonAttemptModel.fromMap(Map<String, dynamic> map) {
    return LessonAttemptModel(
      id: map['id'] ?? '',
      lessonId: map['lessonId'] ?? '',
      userId: map['userId'] ?? '',
      score: map['score'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      answers: List<int>.from(map['answers'] ?? []),
      attemptedAt: DateTime.parse(map['attemptedAt'] ?? DateTime.now().toIso8601String()),
      attemptNumber: map['attemptNumber'] ?? 1,
      isPassed: map['isPassed'] ?? false,
      isFirstPass: map['isFirstPass'] ?? false,
      xpAwarded: map['xpAwarded'] ?? 0,
      gemsAwarded: map['gemsAwarded'] ?? 0,
      scoringTimeMs: map['scoringTimeMs'] ?? 0,
      status: map['status'] ?? 'failed',
    );
  }

  @override
  String toString() {
    return 'LessonAttemptModel(id: $id, lessonId: $lessonId, score: $score%, isPassed: $isPassed, isFirstPass: $isFirstPass, xpAwarded: $xpAwarded, gemsAwarded: $gemsAwarded)';
  }
}

/// Statistics for a specific lesson
class LessonStatistics {
  final String lessonId;
  final int totalAttempts;
  final int passedAttempts;
  final int failedAttempts;
  final double averageScore;
  final int bestScore;
  final int totalXPEarned;
  final int totalGemsEarned;
  final bool isCompleted;
  final DateTime? firstAttemptAt;
  final DateTime? lastAttemptAt;
  final DateTime? firstPassAt;

  LessonStatistics({
    required this.lessonId,
    required this.totalAttempts,
    required this.passedAttempts,
    required this.failedAttempts,
    required this.averageScore,
    required this.bestScore,
    required this.totalXPEarned,
    required this.totalGemsEarned,
    required this.isCompleted,
    this.firstAttemptAt,
    this.lastAttemptAt,
    this.firstPassAt,
  });

  // Create statistics from list of attempts
  factory LessonStatistics.fromAttempts(String lessonId, List<LessonAttemptModel> attempts) {
    if (attempts.isEmpty) {
      return LessonStatistics(
        lessonId: lessonId,
        totalAttempts: 0,
        passedAttempts: 0,
        failedAttempts: 0,
        averageScore: 0.0,
        bestScore: 0,
        totalXPEarned: 0,
        totalGemsEarned: 0,
        isCompleted: false,
      );
    }

    final passedAttempts = attempts.where((a) => a.isPassed).length;
    final failedAttempts = attempts.where((a) => !a.isPassed).length;
    final totalScore = attempts.map((a) => a.score).reduce((a, b) => a + b);
    final averageScore = totalScore / attempts.length;
    final bestScore = attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
    final totalXP = attempts.map((a) => a.xpAwarded).reduce((a, b) => a + b);
    final totalGems = attempts.map((a) => a.gemsAwarded).reduce((a, b) => a + b);
    final isCompleted = attempts.any((a) => a.isPassed);
    
    attempts.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    final firstAttemptAt = attempts.first.attemptedAt;
    final lastAttemptAt = attempts.last.attemptedAt;
    final firstPassAt = attempts.where((a) => a.isPassed).isNotEmpty
        ? attempts.where((a) => a.isPassed).first.attemptedAt
        : null;

    return LessonStatistics(
      lessonId: lessonId,
      totalAttempts: attempts.length,
      passedAttempts: passedAttempts,
      failedAttempts: failedAttempts,
      averageScore: averageScore,
      bestScore: bestScore,
      totalXPEarned: totalXP,
      totalGemsEarned: totalGems,
      isCompleted: isCompleted,
      firstAttemptAt: firstAttemptAt,
      lastAttemptAt: lastAttemptAt,
      firstPassAt: firstPassAt,
    );
  }

  // Success rate percentage
  double get successRate {
    if (totalAttempts == 0) return 0.0;
    return (passedAttempts / totalAttempts) * 100;
  }

  @override
  String toString() {
    return 'LessonStatistics(lessonId: $lessonId, totalAttempts: $totalAttempts, isCompleted: $isCompleted, averageScore: ${averageScore.toStringAsFixed(1)}%, bestScore: $bestScore%)';
  }
}
