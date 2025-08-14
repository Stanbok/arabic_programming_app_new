import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int unit; // تغيير من level إلى unit
  final int order;
  final int xpReward;
  final int gemsReward;
  final bool isPublished;
  final List<SlideModel> slides;
  final List<QuizQuestionModel> quiz;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.unit,
    required this.order,
    this.xpReward = 50,
    this.gemsReward = 2,
    this.isPublished = true,
    this.slides = const [],
    this.quiz = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'unit': unit, // استخدام unit فقط في التخزين
      'order': order,
      'xpReward': xpReward,
      'gemsReward': gemsReward,
      'isPublished': isPublished,
      'slides': slides.map((slide) => slide.toMap()).toList(),
      'quiz': quiz.map((question) => question.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      unit: _parseUnit(map),
      order: map['order'] ?? 0,
      xpReward: map['xpReward'] ?? 50,
      gemsReward: map['gemsReward'] ?? 2,
      isPublished: map['isPublished'] ?? true,
      slides: (map['slides'] as List<dynamic>?)
          ?.map((slide) => SlideModel.fromMap(slide))
          .toList() ?? [],
      quiz: (map['quiz'] as List<dynamic>?)
          ?.map((question) => QuizQuestionModel.fromMap(question))
          .toList() ?? [],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static int _parseUnit(Map<String, dynamic> map) {
    // أولوية للـ unit الجديد
    if (map.containsKey('unit') && map['unit'] != null) {
      return map['unit'] as int;
    }
    
    // التوافق مع level القديم
    if (map.containsKey('level') && map['level'] != null) {
      return map['level'] as int;
    }
    
    // القيمة الافتراضية
    return 1;
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    } else if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else {
      return DateTime.now();
    }
  }

  @deprecated
  int get level => unit;

  bool get isValid {
    return id.isNotEmpty && 
           title.isNotEmpty && 
           unit > 0 && 
           order >= 0;
  }

  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? unit,
    int? order,
    int? xpReward,
    int? gemsReward,
    bool? isPublished,
    List<SlideModel>? slides,
    List<QuizQuestionModel>? quiz,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      order: order ?? this.order,
      xpReward: xpReward ?? this.xpReward,
      gemsReward: gemsReward ?? this.gemsReward,
      isPublished: isPublished ?? this.isPublished,
      slides: slides ?? this.slides,
      quiz: quiz ?? this.quiz,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SlideModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? codeExample;
  final int order;

  SlideModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.codeExample,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'codeExample': codeExample,
      'order': order,
    };
  }

  factory SlideModel.fromMap(Map<String, dynamic> map) {
    return SlideModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      codeExample: map['codeExample'],
      order: map['order'] ?? 0,
    );
  }
}

class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }
}
