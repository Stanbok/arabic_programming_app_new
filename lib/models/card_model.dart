import 'package:hive/hive.dart';

part 'card_model.g.dart';

enum CardType {
  explanation,
  summary,
  quiz,
}

@HiveType(typeId: 5)
class LessonCard {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'explanation', 'summary', 'quiz'

  @HiveField(2)
  final String? title;

  @HiveField(3)
  final String? content;

  @HiveField(4)
  final String? codeBlock;

  @HiveField(5)
  final String? codeLanguage;

  @HiveField(6)
  final List<QuizQuestion>? questions;

  @HiveField(7)
  final int order;

  LessonCard({
    required this.id,
    required this.type,
    this.title,
    this.content,
    this.codeBlock,
    this.codeLanguage,
    this.questions,
    required this.order,
  });

  CardType get cardType {
    switch (type) {
      case 'summary':
        return CardType.summary;
      case 'quiz':
        return CardType.quiz;
      default:
        return CardType.explanation;
    }
  }

  factory LessonCard.fromFirestore(Map<String, dynamic> data, String docId) {
    return LessonCard(
      id: docId,
      type: data['type'] ?? 'explanation',
      title: data['title'],
      content: data['content'],
      codeBlock: data['codeBlock'],
      codeLanguage: data['codeLanguage'] ?? 'python',
      questions: data['questions'] != null
          ? (data['questions'] as List)
              .map((q) => QuizQuestion.fromMap(q))
              .toList()
          : null,
      order: data['order'] ?? 0,
    );
  }
}

@HiveType(typeId: 6)
class QuizQuestion {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // mcq, true_false, fill_blank, order, match, multi_select, code_complete, spot_error

  @HiveField(2)
  final String question;

  @HiveField(3)
  final List<String>? options;

  @HiveField(4)
  final dynamic correctAnswer; // String, bool, List<String>, Map<String, String>

  @HiveField(5)
  final String? explanation;

  @HiveField(6)
  final String? codeSnippet;

  @HiveField(7)
  final String? hint;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.codeSnippet,
    this.hint,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      id: data['id'] ?? '',
      type: data['type'] ?? 'mcq',
      question: data['question'] ?? '',
      options: data['options'] != null ? List<String>.from(data['options']) : null,
      correctAnswer: data['correctAnswer'],
      explanation: data['explanation'],
      codeSnippet: data['codeSnippet'],
      hint: data['hint'],
    );
  }
}
