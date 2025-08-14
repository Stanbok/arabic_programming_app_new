class RewardInfo {
  final int xp;
  final int gems;
  final String reason;
  final DateTime timestamp;
  final double multiplier;
  final bool isRetake;
  final int retakeCount;

  const RewardInfo({
    required this.xp,
    required this.gems,
    required this.reason,
    required this.timestamp,
    this.multiplier = 1.0,
    this.isRetake = false,
    this.retakeCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'gems': gems,
      'reason': reason,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'multiplier': multiplier,
      'isRetake': isRetake,
      'retakeCount': retakeCount,
    };
  }

  factory RewardInfo.fromJson(Map<String, dynamic> json) {
    return RewardInfo(
      xp: json['xp'] ?? 0,
      gems: json['gems'] ?? 0,
      reason: json['reason'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      multiplier: (json['multiplier'] ?? 1.0).toDouble(),
      isRetake: json['isRetake'] ?? false,
      retakeCount: json['retakeCount'] ?? 0,
    );
  }

  RewardInfo copyWith({
    int? xp,
    int? gems,
    String? reason,
    DateTime? timestamp,
    double? multiplier,
    bool? isRetake,
    int? retakeCount,
  }) {
    return RewardInfo(
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      multiplier: multiplier ?? this.multiplier,
      isRetake: isRetake ?? this.isRetake,
      retakeCount: retakeCount ?? this.retakeCount,
    );
  }

  @override
  String toString() {
    return 'RewardInfo(xp: $xp, gems: $gems, reason: $reason, multiplier: $multiplier, isRetake: $isRetake, retakeCount: $retakeCount)';
  }
}
