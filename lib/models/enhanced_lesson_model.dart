class EnhancedLessonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int unit;
  final int order;
  final int xpReward;
  final int gemsReward;
  final bool isPublished;
  final List<LessonSlideModel> slides;
  final LessonSummaryModel? summary;
  final List<QuizBlockModel> finalQuiz;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnhancedLessonModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.unit,
    required this.order,
    required this.xpReward,
    required this.gemsReward,
    required this.isPublished,
    required this.slides,
    this.summary,
    required this.finalQuiz,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnhancedLessonModel.fromJson(Map<String, dynamic> json) {
    return EnhancedLessonModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      unit: json['unit'],
      order: json['order'],
      xpReward: json['xpReward'],
      gemsReward: json['gemsReward'],
      isPublished: json['isPublished'],
      slides: (json['slides'] as List)
          .map((slide) => LessonSlideModel.fromJson(slide))
          .toList(),
      summary: json['summary'] != null 
          ? LessonSummaryModel.fromJson(json['summary']) 
          : null,
      finalQuiz: (json['finalQuiz'] as List)
          .map((quiz) => QuizBlockModel.fromJson(quiz))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class LessonSlideModel {
  final String id;
  final String title;
  final List<LessonBlockModel> blocks;
  final int order;

  LessonSlideModel({
    required this.id,
    required this.title,
    required this.blocks,
    required this.order,
  });

  factory LessonSlideModel.fromJson(Map<String, dynamic> json) {
    return LessonSlideModel(
      id: json['id'],
      title: json['title'],
      blocks: (json['blocks'] as List)
          .map((block) => LessonBlockModel.fromJson(block))
          .toList(),
      order: json['order'],
    );
  }
}

class LessonSummaryModel {
  final String title;
  final List<String> keyPoints;
  final String? imageUrl;

  LessonSummaryModel({
    required this.title,
    required this.keyPoints,
    this.imageUrl,
  });

  factory LessonSummaryModel.fromJson(Map<String, dynamic> json) {
    return LessonSummaryModel(
      title: json['title'],
      keyPoints: json['keyPoints'].cast<String>(),
      imageUrl: json['imageUrl'],
    );
  }
}
