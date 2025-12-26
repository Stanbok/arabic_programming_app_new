import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';

import '../models/lesson_content_model.dart';

/// Service for downloading lesson content from Firebase Storage
class FirebaseStorageService {
  FirebaseStorageService._();
  static final FirebaseStorageService instance = FirebaseStorageService._();

  final _storage = FirebaseStorage.instance;

  /// Download lesson content JSON from Firebase Storage
  /// Path format: lessons/{pathId}/{lessonId}.json
  Future<LessonContentModel?> downloadLessonContent({
    required String lessonId,
    required String pathId,
  }) async {
    try {
      final ref = _storage.ref('lessons/$pathId/$lessonId.json');
      final data = await ref.getData();
      
      if (data == null) return null;

      final jsonString = utf8.decode(data);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      
      return LessonContentModel.fromJson(jsonMap);
    } on FirebaseException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'object-not-found') {
        return null;
      }
      rethrow;
    } catch (e) {
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

  /// Check if lesson exists in Firebase Storage
  Future<bool> lessonExists({
    required String lessonId,
    required String pathId,
  }) async {
    try {
      final ref = _storage.ref('lessons/$pathId/$lessonId.json');
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get download URL for a lesson (for debugging)
  Future<String?> getLessonDownloadUrl({
    required String lessonId,
    required String pathId,
  }) async {
    try {
      final ref = _storage.ref('lessons/$pathId/$lessonId.json');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
