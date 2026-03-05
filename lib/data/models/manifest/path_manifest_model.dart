/// Path manifest model - Contains path metadata and module references
/// Loaded instantly from cache, updated only if global manifest reports newer version
class PathManifestModel {
  final String pathId;
  final int version;
  final String title;
  final String description;
  final String level;
  final int order;
  final bool isVIP;
  final String thumbnail;
  final List<ModuleReference> modules;

  const PathManifestModel({
    required this.pathId,
    required this.version,
    required this.title,
    required this.description,
    required this.level,
    required this.order,
    required this.isVIP,
    required this.thumbnail,
    required this.modules,
  });

  factory PathManifestModel.fromJson(Map<String, dynamic> json) {
    return PathManifestModel(
      pathId: json['pathId'] as String,
      version: json['version'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      level: json['level'] as String? ?? 'beginner',
      order: json['order'] as int? ?? 0,
      isVIP: json['isVIP'] as bool? ?? false,
      thumbnail: json['thumbnail'] as String? ?? '',
      modules: (json['modules'] as List<dynamic>)
          .map((m) => ModuleReference.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pathId': pathId,
      'version': version,
      'title': title,
      'description': description,
      'level': level,
      'order': order,
      'isVIP': isVIP,
      'thumbnail': thumbnail,
      'modules': modules.map((m) => m.toJson()).toList(),
    };
  }

  /// Creates an empty path manifest
  factory PathManifestModel.empty(String pathId) {
    return PathManifestModel(
      pathId: pathId,
      version: 0,
      title: '',
      description: '',
      level: 'beginner',
      order: 0,
      isVIP: false,
      thumbnail: '',
      modules: [],
    );
  }

  bool get isEmpty => version == 0 && modules.isEmpty;
}

/// Reference to a module within a path manifest
class ModuleReference {
  final String id;
  final String title;
  final int version;
  final int order;
  final String lessonsUrl;

  const ModuleReference({
    required this.id,
    required this.title,
    required this.version,
    required this.order,
    required this.lessonsUrl,
  });

  factory ModuleReference.fromJson(Map<String, dynamic> json) {
    return ModuleReference(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      version: json['version'] as int,
      order: json['order'] as int? ?? 0,
      lessonsUrl: json['lessons_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'version': version,
      'order': order,
      'lessons_url': lessonsUrl,
    };
  }
}
