import 'package:hive/hive.dart';

part 'path_model.g.dart';

@HiveType(typeId: 5)
class PathModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? iconUrl;

  @HiveField(4)
  final int order;

  @HiveField(5)
  final int totalLessons;

  @HiveField(6)
  final String color; // hex color for path theme

  PathModel({
    required this.id,
    required this.title,
    required this.description,
    this.iconUrl,
    required this.order,
    required this.totalLessons,
    required this.color,
  });

  factory PathModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PathModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconUrl: data['iconUrl'],
      order: data['order'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
      color: data['color'] ?? '#6C63FF',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'order': order,
      'totalLessons': totalLessons,
      'color': color,
    };
  }
}
