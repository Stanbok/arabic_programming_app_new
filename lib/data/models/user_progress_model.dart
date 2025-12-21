import 'package:hive/hive.dart';

part 'user_progress_model.g.dart';

@HiveType(typeId: 0)
class UserProgressModel extends HiveObject {
  @HiveField(0)
  final List<String> completedLessonIds;

  @HiveField(1)
  final List<String> completedPathIds;

  @HiveField(2)
  final String? currentPathId;

  @HiveField(3)
  final String? currentLessonId;

  @HiveField(4)
  final int? currentCardIndex;

  @HiveField(5)
  final DateTime? lastUpdated;

  UserProgressModel({
    this.completedLessonIds = const [],
    this.completedPathIds = const [],
    this.currentPathId,
    this.currentLessonId,
    this.currentCardIndex,
    this.lastUpdated,
  });

  UserProgressModel copyWith({
    List<String>? completedLessonIds,
    List<String>? completedPathIds,
    String? currentPathId,
    String? currentLessonId,
    int? currentCardIndex,
    DateTime? lastUpdated,
  }) {
    return UserProgressModel(
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      completedPathIds: completedPathIds ?? this.completedPathIds,
      currentPathId: currentPathId ?? this.currentPathId,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedLessonIds': completedLessonIds,
      'completedPathIds': completedPathIds,
      'currentPathId': currentPathId,
      'currentLessonId': currentLessonId,
      'currentCardIndex': currentCardIndex,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      completedLessonIds: List<String>.from(json['completedLessonIds'] ?? []),
      completedPathIds: List<String>.from(json['completedPathIds'] ?? []),
      currentPathId: json['currentPathId'],
      currentLessonId: json['currentLessonId'],
      currentCardIndex: json['currentCardIndex'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}
