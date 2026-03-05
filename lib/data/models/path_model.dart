/// Model representing a learning path
class PathModel {
  final String id;
  final String name;
  final String description;
  final String level;
  final int order;
  final bool isVIP;
  final bool bundled;
  final String thumbnail;
  final List<String> lessonIds;

  const PathModel({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.order,
    required this.isVIP,
    required this.bundled,
    required this.thumbnail,
    required this.lessonIds,
  });

  factory PathModel.fromJson(Map<String, dynamic> json) {
    return PathModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      level: json['level'] as String,
      order: json['order'] as int,
      isVIP: json['isVIP'] as bool? ?? false,
      bundled: json['bundled'] as bool? ?? false,
      thumbnail: json['thumbnail'] as String,
      lessonIds: List<String>.from(json['lessonIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'order': order,
      'isVIP': isVIP,
      'bundled': bundled,
      'thumbnail': thumbnail,
      'lessonIds': lessonIds,
    };
  }
}
