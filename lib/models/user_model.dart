import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int xp;
  final int gems;
  final int currentLevel;
  final List<String> completedLessons;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.xp = 0,
    this.gems = 0,
    this.currentLevel = 1,
    this.completedLessons = const [],
    this.settings = const {'theme': 'system', 'notifications': true},
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'xp': xp,
      'gems': gems,
      'currentLevel': currentLevel,
      'completedLessons': completedLessons,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      xp: map['xp'] ?? 0,
      gems: map['gems'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      completedLessons: List<String>.from(map['completedLessons'] ?? []),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: map['lastLoginAt'] != null 
          ? (map['lastLoginAt'] as Timestamp).toDate() 
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    int? xp,
    int? gems,
    int? currentLevel,
    List<String>? completedLessons,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      currentLevel: currentLevel ?? this.currentLevel,
      completedLessons: completedLessons ?? this.completedLessons,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  int get level {
    // Calculate level based on XP
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    return (xp / 500).floor() + 1;
  }

  int get xpForNextLevel {
    final currentLevelXP = _getXPForLevel(level);
    final nextLevelXP = _getXPForLevel(level + 1);
    return nextLevelXP - currentLevelXP;
  }

  int get currentLevelProgress {
    final currentLevelXP = _getXPForLevel(level);
    return xp - currentLevelXP;
  }

  int _getXPForLevel(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 300;
    if (level == 4) return 600;
    return 1000 + (level - 5) * 500;
  }
}
