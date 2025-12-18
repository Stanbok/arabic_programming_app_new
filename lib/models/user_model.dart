import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String? displayName;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final int selectedAvatarIndex;

  @HiveField(5)
  final bool isAnonymous;

  @HiveField(6)
  final bool isPremium;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final int totalXp;

  @HiveField(9)
  final int currentStreak;

  @HiveField(10)
  final int completedLessons;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.selectedAvatarIndex = 0,
    this.isAnonymous = true,
    this.isPremium = false,
    required this.createdAt,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.completedLessons = 0,
  });

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    int? selectedAvatarIndex,
    bool? isAnonymous,
    bool? isPremium,
    DateTime? createdAt,
    int? totalXp,
    int? currentStreak,
    int? completedLessons,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      selectedAvatarIndex: selectedAvatarIndex ?? this.selectedAvatarIndex,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      completedLessons: completedLessons ?? this.completedLessons,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'selectedAvatarIndex': selectedAvatarIndex,
      'isAnonymous': isAnonymous,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'completedLessons': completedLessons,
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      selectedAvatarIndex: data['selectedAvatarIndex'] as int? ?? 0,
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      isPremium: data['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
      totalXp: data['totalXp'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      completedLessons: data['completedLessons'] as int? ?? 0,
    );
  }
}
