import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking individual lesson attempts and statistics
class LessonAttemptModel {
  final String id;
  final String lessonId;
  final String userId;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<int> answers;
  final DateTime attemptedAt;
  final int attemptNumber; // 1st, 2nd, 3rd attempt etc.
  final bool isPassed;
  final bool isFirstPass; // True if this is the first time user passed this lesson
  final int xpAwarded;
  final int gemsAwarded;
  final int scoringTimeMs; // Time taken to compute score
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
      'attemptedAt': Timestamp.fromDate(attemptedAt),
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
      score: map['score'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      answers: List<int>.from(map['answers'] ?? []),
      attemptedAt: (map['attemptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attemptNumber: map['attemptNumber'] ?? 1,
      isPassed: map['isPassed'] ?? false,
      isFirstPass: map['isFirstPass'] ?? false,
      xpAwarded: map['xpAwarded'] ?? 0,
      gemsAwarded: map['gemsAwarded'] ?? 0,
      scoringTimeMs: map['scoringTimeMs'] ?? 0,
      status: map['status'] ?? 'failed',
    );
  }

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
}

/// Statistics summary for a lesson
class LessonStatistics {
  final String lessonId;
  final int totalAttempts;
  final int passedAttempts;
  final int failedAttempts;
  final int bestScore;
  final double averageScore;
  final DateTime? firstAttemptAt;
  final DateTime? lastAttemptAt;
  final DateTime? firstPassAt;
  final bool isCompleted;
  final int postPassRetakes; // Number of retakes after first pass

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
    required this.postPassRetakes,
  });

  factory LessonStatistics.fromAttempts(String lessonId, List<LessonAttemptModel> attempts) {
    if (attempts.isEmpty) {
      return LessonStatistics(
        lessonId: lessonId,
        totalAttempts: 0,
        passedAttempts: 0,
        failedAttempts: 0,
        bestScore: 0,
        averageScore: 0.0,
        isCompleted: false,
        postPassRetakes: 0,
      );
    }

    attempts.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    
    final passedAttempts = attempts.where((a) => a.isPassed).length;
    final failedAttempts = attempts.length - passedAttempts;
    final bestScore = attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
    final averageScore = attempts.map((a) => a.score).reduce((a, b) => a + b) / attempts.length;
    final firstPassAt = attempts.firstWhere((a) => a.isPassed, orElse: () => attempts.first).attemptedAt;
    final isCompleted = passedAttempts > 0;
    
    // Count post-pass retakes
    int postPassRetakes = 0;
    bool hasPassedBefore = false;
    for (var attempt in attempts) {
      if (attempt.isPassed && !hasPassedBefore) {
        hasPassedBefore = true;
      } else if (hasPassedBefore) {
        postPassRetakes++;
      }
    }

    return LessonStatistics(
      lessonId: lessonId,
      totalAttempts: attempts.length,
      passedAttempts: passedAttempts,
      failedAttempts: failedAttempts,
      bestScore: bestScore,
      averageScore: averageScore,
      firstAttemptAt: attempts.first.attemptedAt,
      lastAttemptAt: attempts.last.attemptedAt,
      firstPassAt: isCompleted ? firstPassAt : null,
      isCompleted: isCompleted,
      postPassRetakes: postPassRetakes,
    );
  }
}
