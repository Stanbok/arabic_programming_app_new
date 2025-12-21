import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../models/path_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_content_model.dart';

/// Service for loading content from bundled assets
class AssetLoaderService {
  AssetLoaderService._();
  static final AssetLoaderService instance = AssetLoaderService._();

  List<PathModel>? _cachedPaths;
  Map<String, List<LessonModel>>? _cachedLessons;

  /// Load all paths from assets
  Future<List<PathModel>> loadPaths() async {
    if (_cachedPaths != null) return _cachedPaths!;

    final jsonString = await rootBundle.loadString(AppConstants.pathsJsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);
    _cachedPaths = jsonList.map((j) => PathModel.fromJson(j)).toList();
    return _cachedPaths!;
  }

  /// Load all lessons from assets
  Future<Map<String, List<LessonModel>>> loadAllLessons() async {
    if (_cachedLessons != null) return _cachedLessons!;

    final jsonString = await rootBundle.loadString(AppConstants.lessonsJsonPath);
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    
    _cachedLessons = {};
    jsonMap.forEach((pathId, lessonsList) {
      _cachedLessons![pathId] = (lessonsList as List)
          .map((j) => LessonModel.fromJson(j))
          .toList();
    });
    
    return _cachedLessons!;
  }

  /// Load lessons for a specific path
  Future<List<LessonModel>> loadLessonsForPath(String pathId) async {
    final allLessons = await loadAllLessons();
    return allLessons[pathId] ?? [];
  }

  /// Load bundled lesson content (Path 1 only)
  Future<LessonContentModel?> loadBundledLessonContent(String lessonId) async {
    try {
      final path = '${AppConstants.path1ContentPath}/$lessonId.json';
      final jsonString = await rootBundle.loadString(path);
      final jsonMap = json.decode(jsonString);
      return LessonContentModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Clear cached data (for testing/refresh)
  void clearCache() {
    _cachedPaths = null;
    _cachedLessons = null;
  }
}
