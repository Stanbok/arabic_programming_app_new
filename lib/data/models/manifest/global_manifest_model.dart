/// Global manifest model - Entry point for all content
/// Checked once per day only, on first app launch of the day
class GlobalManifestModel {
  final int version;
  final DateTime updatedAt;
  final List<PathReference> paths;

  const GlobalManifestModel({
    required this.version,
    required this.updatedAt,
    required this.paths,
  });

  factory GlobalManifestModel.fromJson(Map<String, dynamic> json) {
    return GlobalManifestModel(
      version: json['version'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      paths: (json['paths'] as List<dynamic>)
          .map((p) => PathReference.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'updated_at': updatedAt.toIso8601String().split('T').first,
      'paths': paths.map((p) => p.toJson()).toList(),
    };
  }

  /// Creates an empty manifest for initial state
  factory GlobalManifestModel.empty() {
    return GlobalManifestModel(
      version: 0,
      updatedAt: DateTime(2000),
      paths: [],
    );
  }

  bool get isEmpty => version == 0 && paths.isEmpty;
}

/// Reference to a path manifest within the global manifest
class PathReference {
  final String id;
  final int version;
  final String manifestUrl;

  const PathReference({
    required this.id,
    required this.version,
    required this.manifestUrl,
  });

  factory PathReference.fromJson(Map<String, dynamic> json) {
    return PathReference(
      id: json['id'] as String,
      version: json['version'] as int,
      manifestUrl: json['manifest_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'manifest_url': manifestUrl,
    };
  }
}
