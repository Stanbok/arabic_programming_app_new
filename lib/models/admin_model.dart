import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_model.dart'; // إضافة import للنماذج الأساسية

class AdminModel {
  final String id;
  final String name;
  final String email;
  final List<String> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastAccessAt;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    this.permissions = const ['lessons', 'users', 'analytics'],
    this.isActive = true,
    required this.createdAt,
    this.lastAccessAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastAccessAt': lastAccessAt != null ? Timestamp.fromDate(lastAccessAt!) : null,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastAccessAt: map['lastAccessAt'] != null 
          ? (map['lastAccessAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

class LessonUploadModel {
  final String title;
  final String description;
  final String? imageUrl;
  final int level;
  final int order;
  final int xpReward;
  final int gemsReward;
  final List<SlideUploadModel> slides;
  final List<QuizUploadModel> quiz;

  LessonUploadModel({
    required this.title,
    required this.description,
    this.imageUrl,
    required this.level,
    required this.order,
    this.xpReward = 50,
    this.gemsReward = 2,
    this.slides = const [],
    this.quiz = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'level': level,
      'order': order,
      'xpReward': xpReward,
      'gemsReward': gemsReward,
      'slides': slides.map((slide) => slide.toMap()).toList(),
      'quiz': quiz.map((question) => question.toMap()).toList(),
    };
  }
}

class SlideUploadModel {
  final String title;
  final String content;
  final String? imageUrl;
  final String? codeExample;
  final int order;

  SlideUploadModel({
    required this.title,
    required this.content,
    this.imageUrl,
    this.codeExample,
    required this.order,
  });

  factory SlideUploadModel.fromSlideModel(SlideModel slide) {
    return SlideUploadModel(
      title: slide.title,
      content: slide.content,
      imageUrl: slide.imageUrl,
      codeExample: slide.codeExample,
      order: slide.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'codeExample': codeExample,
      'order': order,
    };
  }
}

class QuizUploadModel {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuizUploadModel({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory QuizUploadModel.fromQuizQuestionModel(QuizQuestionModel quiz) {
    return QuizUploadModel(
      question: quiz.question,
      options: List<String>.from(quiz.options),
      correctAnswerIndex: quiz.correctAnswerIndex,
      explanation: quiz.explanation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}
