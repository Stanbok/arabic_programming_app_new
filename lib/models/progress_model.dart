import 'package:hive/hive.dart';

part 'progress_model.g.dart';

@HiveType(typeId: 6)
class LessonProgress extends HiveObject {
  @HiveField(0)
  final String lessonId;

  @HiveField(1)
  final bool isCompleted;

  @HiveField(2)
  final bool isDownloaded;

  @HiveField(3)
  final int lastCardIndex;

  @HiveField(4)
  final int? quizScore;

  @HiveField(5)
  final int? totalQuestions;

  @HiveField(6)
  final DateTime? completedAt;

  @HiveField(7)
  final DateTime? downloadedAt;

  LessonProgress({
    required this.lessonId,
    this.isCompleted = false,
    this.isDownloaded = false,
    this.lastCardIndex = 0,
    this.quizScore,
    this.totalQuestions,
    this.completedAt,
    this.downloadedAt,
  });

  LessonProgress copyWith({
    String? lessonId,
    bool? isCompleted,
    bool? isDownloaded,
    int? lastCardIndex,
    int? quizScore,
    int? totalQuestions,
    DateTime? completedAt,
    DateTime? downloadedAt,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      isCompleted: isCompleted ?? this.isCompleted,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastCardIndex: lastCardIndex ?? this.lastCardIndex,
      quizScore: quizScore ?? this.quizScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completedAt: completedAt ?? this.completedAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  factory LessonProgress.fromFirestore(Map<String, dynamic> data) {
    return LessonProgress(
      lessonId: data['lessonId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      isDownloaded: data['isDownloaded'] ?? false,
      lastCardIndex: data['lastCardIndex'] ?? 0,
      quizScore: data['quizScore'],
      totalQuestions: data['totalQuestions'],
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'])
          : null,
      downloadedAt: data['downloadedAt'] != null
          ? DateTime.parse(data['downloadedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'isCompleted': isCompleted,
      'isDownloaded': isDownloaded,
      'lastCardIndex': lastCardIndex,
      'quizScore': quizScore,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt?.toIso8601String(),
      'downloadedAt': downloadedAt?.toIso8601String(),
    };
  }
}
