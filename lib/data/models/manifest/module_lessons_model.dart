/// Module lessons model - Contains lesson metadata within a module
/// Cached locally, version-checked only when parent path/module updates
class ModuleLessonsModel {
  final String moduleId;
  final int version;
  final List<LessonReference> lessons;

  const ModuleLessonsModel({
    required this.moduleId,
    required this.version,
    required this.lessons,
  });

  factory ModuleLessonsModel.fromJson(Map<String, dynamic> json) {
    return ModuleLessonsModel(
      moduleId: json['moduleId'] as String? ?? '',
      version: json['version'] as int,
      lessons: (json['lessons'] as List<dynamic>)
          .map((l) => LessonReference.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'version': version,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }

  /// Creates an empty module lessons model
  factory ModuleLessonsModel.empty(String moduleId) {
    return ModuleLessonsModel(
      moduleId: moduleId,
      version: 0,
      lessons: [],
    );
  }

  bool get isEmpty => version == 0 && lessons.isEmpty;
}

/// Lesson reference within module lessons
/// Content is on-demand only - downloaded when user opens lesson
class LessonReference {
  final String id;
  final String title;
  final int order;
  final String thumbnail;
  final String contentUrl;

  const LessonReference({
    required this.id,
    required this.title,
    required this.order,
    required this.thumbnail,
    required this.contentUrl,
  });

  factory LessonReference.fromJson(Map<String, dynamic> json) {
    return LessonReference(
      id: json['id'] as String,
      title: json['title'] as String,
      order: json['order'] as int,
      thumbnail: json['thumbnail'] as String? ?? '',
      contentUrl: json['content_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'order': order,
      'thumbnail': thumbnail,
      'content_url': contentUrl,
    };
  }
}
