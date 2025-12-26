import 'package:hive/hive.dart';

part 'cached_manifest_model.g.dart';

/// Cached manifest wrapper for Hive storage
/// Stores JSON string with version and cache timestamp
@HiveType(typeId: 10)
class CachedManifestModel extends HiveObject {
  @HiveField(0)
  final String manifestId;

  @HiveField(1)
  final String manifestType;

  @HiveField(2)
  final int version;

  @HiveField(3)
  final String contentJson;

  @HiveField(4)
  final DateTime cachedAt;

  CachedManifestModel({
    required this.manifestId,
    required this.manifestType,
    required this.version,
    required this.contentJson,
    required this.cachedAt,
  });
}

/// Manifest type identifiers
class ManifestType {
  ManifestType._();

  static const String global = 'global';
  static const String path = 'path';
  static const String moduleLessons = 'module_lessons';
}
