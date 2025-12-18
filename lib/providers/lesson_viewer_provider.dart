import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/card_model.dart';
import '../models/lesson_model.dart';
import '../core/constants/hive_boxes.dart';

// Current lesson being viewed
final currentLessonProvider = StateProvider<LessonModel?>((ref) => null);

// Cards for current lesson
final lessonCardsProvider = FutureProvider.family<List<LessonCard>, String>((ref, lessonId) async {
  final box = Hive.box<LessonCard>(HiveBoxes.lessonCards);
  final cards = box.values.where((c) => c.id.startsWith(lessonId)).toList();
  cards.sort((a, b) => a.order.compareTo(b.order));
  return cards;
});

// Current card index
final currentCardIndexProvider = StateProvider<int>((ref) => 0);

// Card progress tracking
class CardProgressNotifier extends StateNotifier<Map<String, bool>> {
  CardProgressNotifier() : super({});

  void markCompleted(String cardId) {
    state = {...state, cardId: true};
  }

  bool isCompleted(String cardId) => state[cardId] ?? false;

  int get completedCount => state.values.where((v) => v).length;

  void reset() {
    state = {};
  }
}

final cardProgressProvider = StateNotifierProvider<CardProgressNotifier, Map<String, bool>>(
  (ref) => CardProgressNotifier(),
);

// Quiz answer tracking
class QuizAnswersNotifier extends StateNotifier<Map<String, dynamic>> {
  QuizAnswersNotifier() : super({});

  void setAnswer(String questionId, dynamic answer) {
    state = {...state, questionId: answer};
  }

  dynamic getAnswer(String questionId) => state[questionId];

  void reset() {
    state = {};
  }
}

final quizAnswersProvider = StateNotifierProvider<QuizAnswersNotifier, Map<String, dynamic>>(
  (ref) => QuizAnswersNotifier(),
);

// Quiz results
class QuizResult {
  final int correct;
  final int total;
  final double percentage;

  QuizResult({required this.correct, required this.total})
      : percentage = total > 0 ? (correct / total) * 100 : 0;

  bool get passed => percentage >= 70;
}

final quizResultProvider = StateProvider<QuizResult?>((ref) => null);
