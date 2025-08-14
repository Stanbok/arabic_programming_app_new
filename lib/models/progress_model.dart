import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressModel {
  final String lessonId;
  final List<String> slidesCompleted;
  final int timeSpent; // in seconds
  final DateTime? completedAt;
  final bool isCompleted;
  final int? unit;
  final int? order;

  ProgressModel({
    required this.lessonId,
    this.slidesCompleted = const [],
    this.timeSpent = 0,
    this.completedAt,
    this.isCompleted = false,
    this.unit,
    this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'slidesCompleted': slidesCompleted,
      'timeSpent': timeSpent,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
      'unit': unit,
      'order': order,
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
      unit: map['unit'],
      order: map['order'],
    );
  }

  ProgressModel copyWith({
    String? lessonId,
    List<String>? slidesCompleted,
    int? timeSpent,
    DateTime? completedAt,
    bool? isCompleted,
    int? unit,
    int? order,
  }) {
    return ProgressModel(
      lessonId: lessonId ?? this.lessonId,
      slidesCompleted: slidesCompleted ?? this.slidesCompleted,
      timeSpent: timeSpent ?? this.timeSpent,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      unit: unit ?? this.unit,
      order: order ?? this.order,
    );
  }

  List<String> get completedSlides => slidesCompleted;

  void addCompletedSlide(String slideId) {
    if (!slidesCompleted.contains(slideId)) {
      slidesCompleted.add(slideId);
    }
  }

  double getProgressPercentage(int totalSlides) {
    if (totalSlides <= 0) return 0.0;
    return (slidesCompleted.length / totalSlides).clamp(0.0, 1.0);
  }

  @deprecated
  double get progressPercentage => getProgressPercentage(10);
}
