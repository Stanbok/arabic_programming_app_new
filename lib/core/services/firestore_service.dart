import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../models/path_model.dart';
import '../models/progress_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    _db.settings = const Settings(persistenceEnabled: true);
  }

  // User operations
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  Future<void> upgradeToPremium(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isPremium': true,
    });
  }

  // Path operations
  Future<List<PathModel>> getPaths() async {
    final snapshot = await _db
        .collection('paths')
        .orderBy('orderIndex')
        .get();
    return snapshot.docs
        .map((doc) => PathModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Lesson operations
  Future<List<LessonModel>> getLessonsForPath(String pathId) async {
    final snapshot = await _db
        .collection('lessons')
        .where('pathId', isEqualTo: pathId)
        .orderBy('orderIndex')
        .get();
    return snapshot.docs
        .map((doc) => LessonModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<LessonModel?> getLesson(String lessonId) async {
    final doc = await _db.collection('lessons').doc(lessonId).get();
    if (!doc.exists) return null;
    return LessonModel.fromMap(doc.data()!, doc.id);
  }

  // Progress operations
  Future<Map<String, ProgressModel>> getUserProgress(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();
    
    final Map<String, ProgressModel> progress = {};
    for (final doc in snapshot.docs) {
      progress[doc.id] = ProgressModel.fromMap(doc.data(), doc.id);
    }
    return progress;
  }

  Future<void> saveProgress(
    String userId,
    String lessonId,
    ProgressModel progress,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(lessonId)
        .set(progress.toMap());
  }

  Future<void> incrementCompletedLessons(String userId) async {
    await _db.collection('users').doc(userId).update({
      'completedLessons': FieldValue.increment(1),
    });
  }

  // Download tracking (for premium users)
  Future<void> recordDownload(
    String userId,
    String lessonId,
    String lessonTitle,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('downloads')
        .add({
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'downloadedAt': FieldValue.serverTimestamp(),
    });
  }
}
