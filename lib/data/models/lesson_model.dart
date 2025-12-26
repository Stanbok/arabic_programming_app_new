/// Model representing a lesson within a path
/// Added contentUrl and moduleId for hierarchical manifest support
class LessonModel {
  final String id;
  final String pathId;
  final String? moduleId;
  final String title;
  final int order;
  final String thumbnail;
  final bool bundled;
  final String? contentUrl;

  const LessonModel({
    required this.id,
    required this.pathId,
    this.moduleId,
    required this.title,
    required this.order,
    required this.thumbnail,
    required this.bundled,
    this.contentUrl,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      pathId: json['pathId'] as String,
      moduleId: json['moduleId'] as String?,
      title: json['title'] as String,
      order: json['order'] as int,
      thumbnail: json['thumbnail'] as String,
      bundled: json['bundled'] as bool? ?? false,
      contentUrl: json['content_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pathId': pathId,
      if (moduleId != null) 'moduleId': moduleId,
      'title': title,
      'order': order,
      'thumbnail': thumbnail,
      'bundled': bundled,
      if (contentUrl != null) 'content_url': contentUrl,
    };
  }

  /// Factory to create from LessonReference in manifest
  factory LessonModel.fromReference({
    required String id,
    required String pathId,
    required String moduleId,
    required String title,
    required int order,
    required String thumbnail,
    required String contentUrl,
  }) {
    return LessonModel(
      id: id,
      pathId: pathId,
      moduleId: moduleId,
      title: title,
      order: order,
      thumbnail: thumbnail,
      bundled: false,
      contentUrl: contentUrl,
    );
  }
}
