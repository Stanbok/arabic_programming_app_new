import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/user_progress_model.dart';
import '../constants/hive_boxes.dart';

final progressProvider =
    StateNotifierProvider<ProgressNotifier, UserProgressModel>((ref) {
  return ProgressNotifier();
});

class ProgressNotifier extends StateNotifier<UserProgressModel> {
  late Box<UserProgressModel> _box;

  ProgressNotifier() : super(UserProgressModel()) {
    _init();
  }

  void _init() {
    _box = Hive.box<UserProgressModel>(HiveBoxes.userProgress);
    final progress = _box.get(HiveKeys.progress);
    if (progress != null) {
      state = progress;
    }
  }

  Future<void> completeLesson(String lessonId) async {
    if (!state.completedLessonIds.contains(lessonId)) {
      final updatedList = [...state.completedLessonIds, lessonId];
      state = state.copyWith(
        completedLessonIds: updatedList,
        lastUpdated: DateTime.now(),
      );
      await _box.put(HiveKeys.progress, state);
    }
  }

  Future<void> completePath(String pathId) async {
    if (!state.completedPathIds.contains(pathId)) {
      final updatedList = [...state.completedPathIds, pathId];
      state = state.copyWith(
        completedPathIds: updatedList,
        lastUpdated: DateTime.now(),
      );
      await _box.put(HiveKeys.progress, state);
    }
  }

  Future<void> setCurrentPosition({
    required String pathId,
    required String lessonId,
    int? cardIndex,
  }) async {
    state = state.copyWith(
      currentPathId: pathId,
      currentLessonId: lessonId,
      currentCardIndex: cardIndex ?? 0,
      lastUpdated: DateTime.now(),
    );
    await _box.put(HiveKeys.progress, state);
  }

  Future<void> updateCardIndex(int cardIndex) async {
    state = state.copyWith(
      currentCardIndex: cardIndex,
      lastUpdated: DateTime.now(),
    );
    await _box.put(HiveKeys.progress, state);
  }

  bool isLessonCompleted(String lessonId) {
    return state.completedLessonIds.contains(lessonId);
  }

  bool isPathCompleted(String pathId) {
    return state.completedPathIds.contains(pathId);
  }

  Future<void> clearProgress() async {
    state = UserProgressModel();
    await _box.delete(HiveKeys.progress);
  }
}
