class UserModel {
  final String id;
  final String name;
  final int avatarId;
  final bool isPremium;
  final int completedLessons;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.avatarId,
    required this.isPremium,
    required this.completedLessons,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      avatarId: map['avatarId'] ?? 1,
      isPremium: map['isPremium'] ?? false,
      completedLessons: map['completedLessons'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarId': avatarId,
      'isPremium': isPremium,
      'completedLessons': completedLessons,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? name,
    int? avatarId,
    bool? isPremium,
    int? completedLessons,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      isPremium: isPremium ?? this.isPremium,
      completedLessons: completedLessons ?? this.completedLessons,
      createdAt: createdAt,
    );
  }
}
