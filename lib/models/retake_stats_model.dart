class RetakeStats {
  final String lessonId;
  final int retakeCount;
  final DateTime lastPassTime;
  final DateTime lastAttemptTime;
  final List<int> scores;
  final double currentMultiplier;
  final bool canRetake;
  final Duration timeSinceLastPass;

  const RetakeStats({
    required this.lessonId,
    required this.retakeCount,
    required this.lastPassTime,
    required this.lastAttemptTime,
    required this.scores,
    required this.currentMultiplier,
    required this.canRetake,
    required this.timeSinceLastPass,
  });

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'retakeCount': retakeCount,
      'lastPassTime': lastPassTime.millisecondsSinceEpoch,
      'lastAttemptTime': lastAttemptTime.millisecondsSinceEpoch,
      'scores': scores,
      'currentMultiplier': currentMultiplier,
      'canRetake': canRetake,
      'timeSinceLastPassHours': timeSinceLastPass.inHours,
    };
  }

  factory RetakeStats.fromJson(Map<String, dynamic> json) {
    return RetakeStats(
      lessonId: json['lessonId'] ?? '',
      retakeCount: json['retakeCount'] ?? 0,
      lastPassTime: DateTime.fromMillisecondsSinceEpoch(json['lastPassTime'] ?? 0),
      lastAttemptTime: DateTime.fromMillisecondsSinceEpoch(json['lastAttemptTime'] ?? 0),
      scores: List<int>.from(json['scores'] ?? []),
      currentMultiplier: (json['currentMultiplier'] ?? 0.0).toDouble(),
      canRetake: json['canRetake'] ?? true,
      timeSinceLastPass: Duration(hours: json['timeSinceLastPassHours'] ?? 0),
    );
  }

  RetakeStats copyWith({
    String? lessonId,
    int? retakeCount,
    DateTime? lastPassTime,
    DateTime? lastAttemptTime,
    List<int>? scores,
    double? currentMultiplier,
    bool? canRetake,
    Duration? timeSinceLastPass,
  }) {
    return RetakeStats(
      lessonId: lessonId ?? this.lessonId,
      retakeCount: retakeCount ?? this.retakeCount,
      lastPassTime: lastPassTime ?? this.lastPassTime,
      lastAttemptTime: lastAttemptTime ?? this.lastAttemptTime,
      scores: scores ?? this.scores,
      currentMultiplier: currentMultiplier ?? this.currentMultiplier,
      canRetake: canRetake ?? this.canRetake,
      timeSinceLastPass: timeSinceLastPass ?? this.timeSinceLastPass,
    );
  }

  bool get isEligibleForReset {
    return timeSinceLastPass.inHours >= 24;
  }

  String get nextResetTime {
    if (isEligibleForReset) return 'متاح الآن';
    
    final hoursLeft = 24 - timeSinceLastPass.inHours;
    return 'خلال $hoursLeft ساعة';
  }

  @override
  String toString() {
    return 'RetakeStats(lessonId: $lessonId, retakeCount: $retakeCount, currentMultiplier: $currentMultiplier, canRetake: $canRetake)';
  }
}
