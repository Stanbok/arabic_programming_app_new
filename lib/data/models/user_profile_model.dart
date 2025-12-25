import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 1)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  final String? name;

  @HiveField(1)
  final int avatarId;

  @HiveField(2)
  final bool isLinked;

  @HiveField(3)
  final bool isPremium;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? supabaseUid;

  @HiveField(6)
  final DateTime? premiumExpiryDate;

  @HiveField(7)
  final bool hasCompletedOnboarding;

  UserProfileModel({
    this.name,
    this.avatarId = 0,
    this.isLinked = false,
    this.isPremium = false,
    this.email,
    this.supabaseUid,
    this.premiumExpiryDate,
    this.hasCompletedOnboarding = false,
  });

  UserProfileModel copyWith({
    String? name,
    int? avatarId,
    bool? isLinked,
    bool? isPremium,
    String? email,
    String? supabaseUid,
    DateTime? premiumExpiryDate,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      isLinked: isLinked ?? this.isLinked,
      isPremium: isPremium ?? this.isPremium,
      email: email ?? this.email,
      supabaseUid: supabaseUid ?? this.supabaseUid,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return false;
    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarId': avatarId,
      'isLinked': isLinked,
      'isPremium': isPremium,
      'email': email,
      'supabaseUid': supabaseUid,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name'],
      avatarId: json['avatarId'] ?? 0,
      isLinked: json['isLinked'] ?? false,
      isPremium: json['isPremium'] ?? false,
      email: json['email'],
      supabaseUid: json['supabaseUid'] ?? json['firebaseUid'],
      premiumExpiryDate: json['premiumExpiryDate'] != null
          ? DateTime.parse(json['premiumExpiryDate'])
          : null,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
    );
  }
}
