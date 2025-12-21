import 'package:hive/hive.dart';

part 'cached_lesson_model.g.dart';

@HiveType(typeId: 3)
class CachedLessonModel extends HiveObject {
  @HiveField(0)
  final String lessonId;

  @HiveField(1)
  final String pathId;

  @HiveField(2)
  final String contentJson;

  @HiveField(3)
  final DateTime cachedAt;

  CachedLessonModel({
    required this.lessonId,
    required this.pathId,
    required this.contentJson,
    required this.cachedAt,
  });
}
