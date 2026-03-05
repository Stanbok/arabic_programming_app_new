import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../models/manifest/manifest_models.dart';
import '../models/path_model.dart';
import '../models/lesson_model.dart';
import '../services/manifest_cache_service.dart';
import '../services/supabase_storage_service.dart';

/// Repository for hierarchical manifest loading
/// 
/// Implements the manifest hierarchy:
/// Global Manifest → Path Manifests → Module Lessons → Lesson Content
/// 
/// Loading Strategy:
/// 1. Always load from cache first (offline-first)
/// 2. Cache is populated by ContentUpdateService
/// 3. Falls back to bundled assets for Path 1 if no cache exists
/// 
/// This repository NEVER blocks UI - it returns cached data immediately.
class ManifestRepository {
  ManifestRepository._();
  static final ManifestRepository instance = ManifestRepository._();

  final _cacheService = ManifestCacheService.instance;
  final _storageService = SupabaseStorageService.instance;

  // ===== GLOBAL MANIFEST =====

  /// Get global manifest from cache
  /// Returns empty manifest if no cache exists
  GlobalManifestModel getGlobalManifest() {
    return _cacheService.getGlobalManifest() ?? GlobalManifestModel.empty();
  }

  /// Get current global manifest version
  int getGlobalManifestVersion() {
    return _cacheService.getGlobalManifestVersion();
  }

  // ===== PATH DATA =====

  /// Get all paths from cached manifests
  /// Falls back to bundled assets if no manifest cache exists
  Future<List<PathModel>> getPaths() async {
    final globalManifest = getGlobalManifest();
    
    // If no manifest cache, fall back to bundled assets
    if (globalManifest.isEmpty) {
      return _loadBundledPaths();
    }

    // Build PathModels from cached path manifests
    final paths = <PathModel>[];
    for (final pathRef in globalManifest.paths) {
      final pathManifest = _cacheService.getPathManifest(pathRef.id);
      if (pathManifest != null) {
        paths.add(_pathManifestToPathModel(pathManifest));
      }
    }

    // If no path manifests cached, fall back to bundled
    if (paths.isEmpty) {
      return _loadBundledPaths();
    }

    // Sort by order
    paths.sort((a, b) => a.order.compareTo(b.order));
    return paths;
  }

  /// Get a specific path by ID
  Future<PathModel?> getPath(String pathId) async {
    // First try cached path manifest
    final pathManifest = _cacheService.getPathManifest(pathId);
    if (pathManifest != null) {
      return _pathManifestToPathModel(pathManifest);
    }

    // Fall back to bundled paths for Path 1
    if (pathId == AppConstants.path1Id) {
      final bundledPaths = await _loadBundledPaths();
      try {
        return bundledPaths.firstWhere((p) => p.id == pathId);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Get path manifest version
  int getPathVersion(String pathId) {
    return _cacheService.getPathManifestVersion(pathId);
  }

  // ===== LESSON DATA =====

  /// Get lessons for a path
  /// Aggregates lessons from all modules in the path
  Future<List<LessonModel>> getLessonsForPath(String pathId) async {
    final pathManifest = _cacheService.getPathManifest(pathId);
    
    // If no path manifest, fall back to bundled lessons for Path 1
    if (pathManifest == null) {
      if (pathId == AppConstants.path1Id) {
        return _loadBundledLessonsForPath(pathId);
      }
      return [];
    }

    // Aggregate lessons from all modules
    final lessons = <LessonModel>[];
    for (final moduleRef in pathManifest.modules) {
      final moduleLessons = _cacheService.getModuleLessons(moduleRef.id);
      if (moduleLessons != null) {
        for (final lessonRef in moduleLessons.lessons) {
          lessons.add(LessonModel.fromReference(
            id: lessonRef.id,
            pathId: pathId,
            moduleId: moduleRef.id,
            title: lessonRef.title,
            order: lessonRef.order,
            thumbnail: lessonRef.thumbnail,
            contentUrl: lessonRef.contentUrl,
          ));
        }
      }
    }

    // If no module lessons cached, fall back to bundled for Path 1
    if (lessons.isEmpty && pathId == AppConstants.path1Id) {
      return _loadBundledLessonsForPath(pathId);
    }

    // Sort by order
    lessons.sort((a, b) => a.order.compareTo(b.order));
    return lessons;
  }

  /// Get a specific lesson by ID
  Future<LessonModel?> getLesson(String pathId, String lessonId) async {
    final lessons = await getLessonsForPath(pathId);
    try {
      return lessons.firstWhere((l) => l.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  /// Get lesson content URL
  /// Returns null for bundled lessons (they use asset loading)
  String? getLessonContentUrl(String pathId, String lessonId) {
    final pathManifest = _cacheService.getPathManifest(pathId);
    if (pathManifest == null) return null;

    for (final moduleRef in pathManifest.modules) {
      final moduleLessons = _cacheService.getModuleLessons(moduleRef.id);
      if (moduleLessons != null) {
        for (final lessonRef in moduleLessons.lessons) {
          if (lessonRef.id == lessonId) {
            return lessonRef.contentUrl;
          }
        }
      }
    }
    return null;
  }

  // ===== MODULE DATA =====

  /// Get modules for a path
  List<ModuleReference> getModulesForPath(String pathId) {
    final pathManifest = _cacheService.getPathManifest(pathId);
    if (pathManifest == null) return [];
    
    final modules = pathManifest.modules.toList();
    modules.sort((a, b) => a.order.compareTo(b.order));
    return modules;
  }

  /// Get module lessons version
  int getModuleLessonsVersion(String moduleId) {
    return _cacheService.getModuleLessonsVersion(moduleId);
  }

  // ===== REMOTE FETCHING (for update service) =====

  /// Fetch global manifest from Supabase (for update checks)
  Future<GlobalManifestModel?> fetchRemoteGlobalManifest() async {
    return _storageService.downloadGlobalManifest();
  }

  /// Fetch path manifest from Supabase
  Future<PathManifestModel?> fetchRemotePathManifest(String pathId) async {
    return _storageService.downloadPathManifest(pathId);
  }

  /// Fetch module lessons from Supabase
  Future<ModuleLessonsModel?> fetchRemoteModuleLessons({
    required String pathId,
    required String moduleId,
  }) async {
    return _storageService.downloadModuleLessons(
      pathId: pathId,
      moduleId: moduleId,
    );
  }

  /// Cache global manifest
  Future<bool> cacheGlobalManifest(GlobalManifestModel manifest) async {
    return _cacheService.cacheGlobalManifest(manifest);
  }

  /// Cache path manifest
  Future<bool> cachePathManifest(PathManifestModel manifest) async {
    return _cacheService.cachePathManifest(manifest);
  }

  /// Cache module lessons
  Future<bool> cacheModuleLessons(String moduleId, ModuleLessonsModel lessons) async {
    return _cacheService.cacheModuleLessons(moduleId, lessons);
  }

  // ===== BUNDLED ASSET FALLBACKS =====

  /// Load paths from bundled assets
  Future<List<PathModel>> _loadBundledPaths() async {
    try {
      final jsonString = await rootBundle.loadString(AppConstants.pathsJsonPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => PathModel.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Load lessons from bundled assets for a specific path
  Future<List<LessonModel>> _loadBundledLessonsForPath(String pathId) async {
    try {
      final jsonString = await rootBundle.loadString(AppConstants.lessonsJsonPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      final lessonsList = jsonMap[pathId] as List<dynamic>?;
      if (lessonsList == null) return [];
      
      return lessonsList.map((j) => LessonModel.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convert PathManifestModel to PathModel for backward compatibility
  PathModel _pathManifestToPathModel(PathManifestModel manifest) {
    // Collect all lesson IDs from modules
    final lessonIds = <String>[];
    for (final moduleRef in manifest.modules) {
      final moduleLessons = _cacheService.getModuleLessons(moduleRef.id);
      if (moduleLessons != null) {
        lessonIds.addAll(moduleLessons.lessons.map((l) => l.id));
      }
    }

    return PathModel(
      id: manifest.pathId,
      name: manifest.title,
      description: manifest.description,
      level: manifest.level,
      order: manifest.order,
      isVIP: manifest.isVIP,
      bundled: false, // Manifest-based paths are not bundled
      thumbnail: manifest.thumbnail,
      lessonIds: lessonIds,
    );
  }
}
