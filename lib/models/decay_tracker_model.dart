class DecayTrackerModel {
  final String lessonId;
  final DateTime firstCompletionDate;
  final DateTime lastRetakeDate;
  final int retakeCount;

  DecayTrackerModel({
    required this.lessonId,
    required this.firstCompletionDate,
    required this.lastRetakeDate,
    required this.retakeCount,
  });

  factory DecayTrackerModel.fromMap(Map<String, dynamic> map) {
    return DecayTrackerModel(
      lessonId: map['lessonId'] ?? '',
      firstCompletionDate: DateTime.fromMillisecondsSinceEpoch(map['firstCompletionDate'] ?? 0),
      lastRetakeDate: DateTime.fromMillisecondsSinceEpoch(map['lastRetakeDate'] ?? 0),
      retakeCount: map['retakeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'firstCompletionDate': firstCompletionDate.millisecondsSinceEpoch,
      'lastRetakeDate': lastRetakeDate.millisecondsSinceEpoch,
      'retakeCount': retakeCount,
    };
  }

  /// حساب نسبة الاضمحلال الحالية
  double getDecayMultiplier() {
    final now = DateTime.now();
    final daysSinceLastRetake = now.difference(lastRetakeDate).inDays;
    
    // إعادة التأهيل بعد يوم واحد
    if (daysSinceLastRetake >= 1) {
      return 0.3; // 30%
    }
    
    // تطبيق الاضمحلال بناءً على عدد الإعادات
    switch (retakeCount) {
      case 0:
        return 1.0; // 100% - أول مرة
      case 1:
        return 0.3; // 30% من المكافآت الأساسية - إعادة أولى
      case 2:
        return 0.2; // 20% من المكافآت الأساسية - إعادة ثانية
      case 3:
        return 0.1; // 10% من المكافآت الأساسية - إعادة ثالثة
      default:
        return 0.0; // 0% - أي إعادة لاحقة في نفس اليوم
    }
  }

  /// إنشاء نسخة محدثة مع إعادة جديدة
  DecayTrackerModel withNewRetake() {
    return DecayTrackerModel(
      lessonId: lessonId,
      firstCompletionDate: firstCompletionDate,
      lastRetakeDate: DateTime.now(),
      retakeCount: retakeCount + 1,
    );
  }

  /// إنشاء نسخة محدثة مع إعادة تأهيل يومية
  DecayTrackerModel withDailyReset() {
    final now = DateTime.now();
    final daysSinceLastRetake = now.difference(lastRetakeDate).inDays;
    
    if (daysSinceLastRetake >= 1) {
      return DecayTrackerModel(
        lessonId: lessonId,
        firstCompletionDate: firstCompletionDate,
        lastRetakeDate: now,
        retakeCount: 1, // البداية من المرحلة الأولى للاضمحلال (30%)
      );
    }
    
    return this;
  }
}
