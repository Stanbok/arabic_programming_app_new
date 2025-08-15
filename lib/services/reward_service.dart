import '../models/lesson_model.dart';

class RewardService {
  // حساب مكافآت XP بناءً على الأداء
  static int calculateXPReward(LessonModel lesson, double scorePercentage) {
    int baseXP = lesson.xpReward;
    
    if (scorePercentage >= 95) {
      return (baseXP * 1.5).round(); // مكافأة ممتازة
    } else if (scorePercentage >= 85) {
      return (baseXP * 1.25).round(); // مكافأة جيدة جداً
    } else if (scorePercentage >= 70) {
      return baseXP; // مكافأة أساسية للنجاح
    } else {
      return 0; // لا مكافآت للرسوب
    }
  }

  // حساب مكافآت الجواهر بناءً على الأداء
  static int calculateGemsReward(LessonModel lesson, double scorePercentage) {
    int baseGems = lesson.gemsReward;
    
    if (scorePercentage >= 95) {
      return (baseGems * 1.5).round(); // مكافأة ممتازة
    } else if (scorePercentage >= 85) {
      return (baseGems * 1.25).round(); // مكافأة جيدة جداً
    } else if (scorePercentage >= 70) {
      return baseGems; // مكافأة أساسية للنجاح
    } else {
      return 0; // لا مكافآت للرسوب
    }
  }

  // حساب المكافآت الإجمالية
  static Map<String, int> calculateTotalRewards(LessonModel lesson, double scorePercentage) {
    return {
      'xp': calculateXPReward(lesson, scorePercentage),
      'gems': calculateGemsReward(lesson, scorePercentage),
    };
  }

  // تحديد مستوى الأداء
  static String getPerformanceLevel(double scorePercentage) {
    if (scorePercentage >= 95) {
      return 'ممتاز';
    } else if (scorePercentage >= 85) {
      return 'جيد جداً';
    } else if (scorePercentage >= 70) {
      return 'جيد';
    } else {
      return 'يحتاج تحسين';
    }
  }

  // تحديد عدد النجوم بناءً على الأداء
  static int getStarsCount(double scorePercentage) {
    if (scorePercentage >= 95) {
      return 3;
    } else if (scorePercentage >= 85) {
      return 2;
    } else if (scorePercentage >= 70) {
      return 1;
    } else {
      return 0;
    }
  }
}
