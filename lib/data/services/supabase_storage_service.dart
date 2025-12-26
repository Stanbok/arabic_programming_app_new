import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/lesson_content_model.dart';
import '../models/manifest/manifest_models.dart';

/// Service for downloading content from Supabase Storage
/// 
/// Handles:
/// - Global manifest downloads
/// - Path manifest downloads
/// - Module lessons downloads
/// - Lesson content downloads (on-demand)
/// 
/// All downloads are validated before returning.
class SupabaseStorageService {
  SupabaseStorageService._();
  static final SupabaseStorageService instance = SupabaseStorageService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Download and parse global manifest
  Future<GlobalManifestModel?> downloadGlobalManifest() async {
    try {
      final url = _client.storage
          .from(SupabaseConstants.contentBucket)
          .getPublicUrl(SupabaseConstants.globalManifestPath);
      
      final jsonString = await _fetchJson(url);
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return GlobalManifestModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Download and parse path manifest by path ID
  Future<PathManifestModel?> downloadPathManifest(String pathId) async {
    try {
      final url = _client.storage
          .from(SupabaseConstants.contentBucket)
          .getPublicUrl(SupabaseConstants.pathManifestPath(pathId));
      
      final jsonString = await _fetchJson(url);
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return PathManifestModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Download and parse module lessons by module ID
  Future<ModuleLessonsModel?> downloadModuleLessons({
    required String pathId,
    required String moduleId,
  }) async {
    try {
      final url = _client.storage
          .from(SupabaseConstants.contentBucket)
          .getPublicUrl(SupabaseConstants.moduleLessonsPath(pathId, moduleId));
      
      final jsonString = await _fetchJson(url);
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return ModuleLessonsModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Download lesson content by direct URL
  /// Used for on-demand lesson loading
  Future<LessonContentModel?> downloadLessonContentByUrl(String contentUrl) async {
    try {
      final jsonString = await _fetchJson(
        contentUrl,
        timeout: AppConstants.lessonDownloadTimeout,
      );
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return LessonContentModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Download lesson content by path structure
  Future<LessonContentModel?> downloadLessonContent({
    required String pathId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final url = _client.storage
          .from(SupabaseConstants.contentBucket)
          .getPublicUrl(
            SupabaseConstants.lessonContentPath(pathId, moduleId, lessonId),
          );
      
      return downloadLessonContentByUrl(url);
    } catch (e) {
      return null;
    }
  }

  /// Download manifest from direct URL (used for path/module manifest_url fields)
  Future<String?> downloadFromUrl(String url) async {
    return _fetchJson(url);
  }

  /// Internal: Fetch JSON string from URL with timeout
  Future<String?> _fetchJson(
    String url, {
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(timeout ?? AppConstants.manifestDownloadTimeout);

      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate JSON string is parseable
  bool isValidJson(String jsonString) {
    try {
      json.decode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
