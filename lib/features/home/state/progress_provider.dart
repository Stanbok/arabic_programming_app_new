import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple map from lessonId to completion percentage (0.0-1.0).
class ProgressNotifier extends StateNotifier<Map<String, double>> {
  ProgressNotifier() : super({});

  void markLessonComplete(String lessonId) {
    state = {...state, lessonId: 1.0};
  }

  void setProgress(String lessonId, double pct) {
    state = {...state, lessonId: pct.clamp(0.0, 1.0)};
  }

  double progressFor(String lessonId) => state[lessonId] ?? 0.0;
}

final progressProvider = StateNotifierProvider<ProgressNotifier, Map<String, double>>((ref) {
  return ProgressNotifier();
});
