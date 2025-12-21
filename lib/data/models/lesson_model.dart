/// Model representing a lesson within a path
class LessonModel {
  final String id;
  final String pathId;
  final String title;
  final int order;
  final String thumbnail;
  final bool bundled;

  const LessonModel({
    required this.id,
    required this.pathId,
    required this.title,
    required this.order,
    required this.thumbnail,
    required this.bundled,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      pathId: json['pathId'] as String,
      title: json['title'] as String,
      order: json['order'] as int,
      thumbnail: json['thumbnail'] as String,
      bundled: json['bundled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pathId': pathId,
      'title': title,
      'order': order,
      'thumbnail': thumbnail,
      'bundled': bundled,
    };
  }
}
