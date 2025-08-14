import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final int xp;
  final int gems;
  final int currentLevel;
  final List<String> completedLessons;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.xp,
    required this.gems,
    required this.currentLevel,
    required this.completedLessons,
    this.profileImageUrl,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Getter for level based on XP
  int get level => currentLevel;

  // Check if user has completed a specific lesson
  bool hasCompletedLesson(String lessonId) {
    return completedLessons.contains(lessonId);
  }

  // Get completion percentage (assuming 50 total lessons)
  double get completionPercentage {
    return completedLessons.length / 50.0;
  }

  // Create a copy with updated fields - إضافة دالة copyWith للتحديث المحلي
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? xp,
    int? gems,
    int? currentLevel,
    List<String>? completedLessons,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      currentLevel: currentLevel ?? this.currentLevel,
      completedLessons: completedLessons ?? this.completedLessons,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'xp': xp,
      'gems': gems,
      'currentLevel': currentLevel,
      'completedLessons': completedLessons,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  // Create from Map (Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      xp: map['xp'] ?? 0,
      gems: map['gems'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      completedLessons: List<String>.from(map['completedLessons'] ?? []),
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, xp: $xp, gems: $gems, level: $currentLevel, completedLessons: ${completedLessons.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.xp == xp &&
        other.gems == gems &&
        other.currentLevel == currentLevel;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        xp.hashCode ^
        gems.hashCode ^
        currentLevel.hashCode;
  }
}
