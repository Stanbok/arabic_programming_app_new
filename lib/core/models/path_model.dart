class PathModel {
  final String id;
  final String name;
  final String description;
  final int level;
  final int orderIndex;
  final List<String> lessonIds;
  final String thumbnailUrl;

  PathModel({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.orderIndex,
    required this.lessonIds,
    required this.thumbnailUrl,
  });

  factory PathModel.fromMap(Map<String, dynamic> map, String id) {
    return PathModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      level: map['level'] ?? 1,
      orderIndex: map['orderIndex'] ?? 0,
      lessonIds: (map['lessonIds'] as List<dynamic>?)?.cast<String>() ?? [],
      thumbnailUrl: map['thumbnailUrl'] ?? '',
    );
  }

  double get xpMultiplier {
    switch (level) {
      case 1: return 1.0;
      case 2: return 1.25;
      case 3: return 1.5;
      default: return 1.0;
    }
  }
}
