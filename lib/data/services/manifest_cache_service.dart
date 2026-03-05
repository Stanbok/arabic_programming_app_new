import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../models/manifest/manifest_models.dart';

/// Service for managing versioned manifest cache with atomic updates
/// 
/// Responsibilities:
/// - Store and retrieve manifests from Hive
/// - Validate JSON before caching
/// - Version tracking for each manifest
/// - Atomic replacement (only if validation passes)
/// - Rollback capability on failure
/// 
/// Cache Structure:
/// - Global manifest: key = "global_manifest"
/// - Path manifests: key = "path_{pathId}"
/// - Module lessons: key = "module_{moduleId}"
class ManifestCacheService {
  ManifestCacheService._();
  static final ManifestCacheService instance = ManifestCacheService._();

  Box<CachedManifestModel>? _cacheBox;

  Box<CachedManifestModel> get _box {
    _cacheBox ??= Hive.box<CachedManifestModel>(HiveBoxes.cachedManifests);
    return _cacheBox!;
  }

  // ===== GLOBAL MANIFEST =====

  /// Get cached global manifest
  GlobalManifestModel? getGlobalManifest() {
    final cached = _box.get(HiveKeys.globalManifest);
    if (cached == null) return null;

    try {
      final jsonMap = json.decode(cached.contentJson) as Map<String, dynamic>;
      return GlobalManifestModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Get cached global manifest version
  int getGlobalManifestVersion() {
    final cached = _box.get(HiveKeys.globalManifest);
    return cached?.version ?? 0;
  }

  /// Cache global manifest with validation
  /// Returns true if successfully cached, false if validation failed
  Future<bool> cacheGlobalManifest(GlobalManifestModel manifest) async {
    try {
      final jsonString = json.encode(manifest.toJson());
      
      // Validate JSON is parseable
      json.decode(jsonString);

      final cached = CachedManifestModel(
        manifestId: HiveKeys.globalManifest,
        manifestType: ManifestType.global,
        version: manifest.version,
        contentJson: jsonString,
        cachedAt: DateTime.now(),
      );

      await _box.put(HiveKeys.globalManifest, cached);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== PATH MANIFESTS =====

  /// Get cached path manifest
  PathManifestModel? getPathManifest(String pathId) {
    final key = ManifestKeys.pathManifest(pathId);
    final cached = _box.get(key);
    if (cached == null) return null;

    try {
      final jsonMap = json.decode(cached.contentJson) as Map<String, dynamic>;
      return PathManifestModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Get cached path manifest version
  int getPathManifestVersion(String pathId) {
    final key = ManifestKeys.pathManifest(pathId);
    final cached = _box.get(key);
    return cached?.version ?? 0;
  }

  /// Cache path manifest with validation
  Future<bool> cachePathManifest(PathManifestModel manifest) async {
    try {
      final jsonString = json.encode(manifest.toJson());
      
      // Validate
      json.decode(jsonString);

      final key = ManifestKeys.pathManifest(manifest.pathId);
      final cached = CachedManifestModel(
        manifestId: key,
        manifestType: ManifestType.path,
        version: manifest.version,
        contentJson: jsonString,
        cachedAt: DateTime.now(),
      );

      await _box.put(key, cached);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all cached path IDs
  List<String> getAllCachedPathIds() {
    return _box.values
        .where((c) => c.manifestType == ManifestType.path)
        .map((c) => c.manifestId.replaceFirst('path_', ''))
        .toList();
  }

  // ===== MODULE LESSONS =====

  /// Get cached module lessons
  ModuleLessonsModel? getModuleLessons(String moduleId) {
    final key = ManifestKeys.moduleLessons(moduleId);
    final cached = _box.get(key);
    if (cached == null) return null;

    try {
      final jsonMap = json.decode(cached.contentJson) as Map<String, dynamic>;
      return ModuleLessonsModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Get cached module lessons version
  int getModuleLessonsVersion(String moduleId) {
    final key = ManifestKeys.moduleLessons(moduleId);
    final cached = _box.get(key);
    return cached?.version ?? 0;
  }

  /// Cache module lessons with validation
  Future<bool> cacheModuleLessons(String moduleId, ModuleLessonsModel lessons) async {
    try {
      final jsonString = json.encode(lessons.toJson());
      
      // Validate
      json.decode(jsonString);

      final key = ManifestKeys.moduleLessons(moduleId);
      final cached = CachedManifestModel(
        manifestId: key,
        manifestType: ManifestType.moduleLessons,
        version: lessons.version,
        contentJson: jsonString,
        cachedAt: DateTime.now(),
      );

      await _box.put(key, cached);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all cached module IDs for a path
  List<String> getCachedModuleIdsForPath(String pathId) {
    final pathManifest = getPathManifest(pathId);
    if (pathManifest == null) return [];
    
    return pathManifest.modules
        .map((m) => m.id)
        .where((id) => _box.containsKey(ManifestKeys.moduleLessons(id)))
        .toList();
  }

  // ===== UTILITY METHODS =====

  /// Check if manifest exists in cache
  bool hasManifest(String key) {
    return _box.containsKey(key);
  }

  /// Get cache timestamp for a manifest
  DateTime? getCacheTimestamp(String key) {
    return _box.get(key)?.cachedAt;
  }

  /// Delete a specific manifest from cache
  Future<void> deleteManifest(String key) async {
    await _box.delete(key);
  }

  /// Delete all module lessons for a path
  Future<void> deleteModuleLessonsForPath(String pathId) async {
    final moduleIds = getCachedModuleIdsForPath(pathId);
    for (final moduleId in moduleIds) {
      await _box.delete(ManifestKeys.moduleLessons(moduleId));
    }
  }

  /// Clear all manifest cache
  Future<void> clearAllCache() async {
    await _box.clear();
  }

  /// Get total cache entry count
  int getCacheEntryCount() {
    return _box.length;
  }

  /// Atomic update: only replace if new version is valid
  /// Returns true if update was applied
  Future<bool> atomicUpdate<T>({
    required String key,
    required String manifestType,
    required int newVersion,
    required String newContentJson,
    required T Function(Map<String, dynamic>) validator,
  }) async {
    try {
      // Step 1: Validate new JSON is parseable
      final jsonMap = json.decode(newContentJson) as Map<String, dynamic>;
      
      // Step 2: Validate it creates a valid model
      validator(jsonMap);

      // Step 3: Only update if version is newer
      final currentVersion = _box.get(key)?.version ?? 0;
      if (newVersion <= currentVersion) {
        return false; // No update needed
      }

      // Step 4: Atomic write
      final cached = CachedManifestModel(
        manifestId: key,
        manifestType: manifestType,
        version: newVersion,
        contentJson: newContentJson,
        cachedAt: DateTime.now(),
      );

      await _box.put(key, cached);
      return true;
    } catch (e) {
      // Validation failed - keep existing cache
      return false;
    }
  }
}
