import 'package:hive/hive.dart';
import 'card_model.dart';

part 'lesson_model.g.dart';

@HiveType(typeId: 1)
class LessonModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pathId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final int order;

  @HiveField(5)
  final String? thumbnailUrl;

  @HiveField(6)
  final List<LessonCard> cards;

  @HiveField(7)
  final int totalQuestions;

  @HiveField(8)
  final int estimatedMinutes;

  LessonModel({
    required this.id,
    required this.pathId,
    required this.title,
    required this.description,
    required this.order,
    this.thumbnailUrl,
    required this.cards,
    required this.totalQuestions,
    required this.estimatedMinutes,
  });

  factory LessonModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LessonModel(
      id: id,
      pathId: data['pathId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: data['order'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'],
      cards: (data['cards'] as List<dynamic>?)
              ?.asMap()
              .entries
              .map((entry) => LessonCard.fromFirestore(
                    entry.value as Map<String, dynamic>,
                    '${id}_card_${entry.key}',
                  ))
              .toList() ??
          [],
      totalQuestions: data['totalQuestions'] ?? 0,
      estimatedMinutes: data['estimatedMinutes'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pathId': pathId,
      'title': title,
      'description': description,
      'order': order,
      'thumbnailUrl': thumbnailUrl,
      'cards': cards.map((c) => {
        'id': c.id,
        'type': c.type,
        'title': c.title,
        'content': c.content,
        'codeBlock': c.codeBlock,
        'codeLanguage': c.codeLanguage,
        'questions': c.questions?.map((q) => {
          'id': q.id,
          'type': q.type,
          'question': q.question,
          'options': q.options,
          'correctAnswer': q.correctAnswer,
          'explanation': q.explanation,
          'codeSnippet': q.codeSnippet,
          'hint': q.hint,
        }).toList(),
        'order': c.order,
      }).toList(),
      'totalQuestions': totalQuestions,
      'estimatedMinutes': estimatedMinutes,
    };
  }
}
