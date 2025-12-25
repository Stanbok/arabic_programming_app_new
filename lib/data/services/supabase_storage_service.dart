import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';
import '../models/lesson_content_model.dart';
import 'supabase_service.dart';

/// Service for downloading lesson content from Supabase
class SupabaseStorageService {
  SupabaseStorageService._();
  static final SupabaseStorageService instance = SupabaseStorageService._();

  SupabaseClient get _supabase => SupabaseService.clientInstance;

  /// Download lesson content from Supabase database
  Future<LessonContentModel?> downloadLessonContent({
    required String lessonId,
    required String pathId,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.lessonContentTable)
          .select('content')
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (response == null || response['content'] == null) return null;

      final content = response['content'] as Map<String, dynamic>;
      return LessonContentModel.fromJson(content);
    } catch (e) {
      debugPrint('Download lesson content failed: $e');
      return null;
    }
  }

  /// Download lesson content from Supabase Storage bucket
  Future<LessonContentModel?> downloadLessonContentFromStorage({
    required String lessonId,
    required String pathId,
  }) async {
    try {
      final bytes = await _supabase.storage
          .from(SupabaseConstants.lessonsBucket)
          .download('$pathId/$lessonId.json');

      final jsonString = utf8.decode(bytes);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      return LessonContentModel.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Download from storage failed: $e');
      return null;
    }
  }

  /// Download all lessons for a path
  /// Returns map of lessonId -> content
  Future<Map<String, LessonContentModel>> downloadAllLessonsForPath({
    required String pathId,
    required List<String> lessonIds,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    final results = <String, LessonContentModel>{};

    for (int i = 0; i < lessonIds.length; i++) {
      final lessonId = lessonIds[i];
      final content = await downloadLessonContent(
        lessonId: lessonId,
        pathId: pathId,
      );

      if (content != null) {
        results[lessonId] = content;
      }

      onProgress?.call(i + 1, lessonIds.length);
    }

    return results;
  }

  /// Check if lesson exists in Supabase
  Future<bool> lessonExists({
    required String lessonId,
    required String pathId,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.lessonContentTable)
          .select('id')
          .eq('lesson_id', lessonId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get content version for a path
  Future<int> getContentVersion() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.appMetadataTable)
          .select('value')
          .eq('key', 'content_version')
          .maybeSingle();

      if (response == null) return 1;
      final value = response['value'] as Map<String, dynamic>;
      return value['version'] as int? ?? 1;
    } catch (e) {
      return 1;
    }
  }
}
