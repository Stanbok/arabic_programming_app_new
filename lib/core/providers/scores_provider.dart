import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores quiz scores per lessonId as integer percentage (0-100)
class ScoresNotifier extends StateNotifier<Map<String, int>> {
  ScoresNotifier() : super({});

  void setScore(String lessonId, int percent) {
    final p = percent.clamp(0, 100);
    state = {...state, lessonId: p};
  }

  int scoreFor(String lessonId) => state[lessonId] ?? 0;
}

final scoresProvider = StateNotifierProvider<ScoresNotifier, Map<String, int>>((ref) {
  return ScoresNotifier();
});
