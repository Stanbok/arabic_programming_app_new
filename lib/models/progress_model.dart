import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressModel {
  final String lessonId;
  final List<String> slidesCompleted;
  final int timeSpent; // in seconds
  final DateTime? completedAt;
  final bool isCompleted;

  ProgressModel({
    required this.lessonId,
    this.slidesCompleted = const [],
    this.timeSpent = 0,
    this.completedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'slidesCompleted': slidesCompleted,
      'timeSpent': timeSpent,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
    };
  }

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      lessonId: map['lessonId'] ?? '',
      slidesCompleted: List<String>.from(map['slidesCompleted'] ?? []),
      timeSpent: map['timeSpent'] ?? 0,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  ProgressModel copyWith({
    String? lessonId,
    List<String>? slidesCompleted,
    int? timeSpent,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return ProgressModel(
      lessonId: lessonId ?? this.lessonId,
      slidesCompleted: slidesCompleted ?? this.slidesCompleted,
      timeSpent: timeSpent ?? this.timeSpent,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  List<String> get completedSlides => slidesCompleted;

  void addCompletedSlide(String slideId) {
    if (!slidesCompleted.contains(slideId)) {
      slidesCompleted.add(slideId);
    }
  }

  double get progressPercentage {
    // This would be calculated based on total slides in lesson
    // For now, return a simple calculation
    return slidesCompleted.length / 10.0; // Assuming 10 slides per lesson
  }
}
