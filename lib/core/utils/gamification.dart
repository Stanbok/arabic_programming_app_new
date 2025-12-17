class GamificationUtils {
  static bool didPass(int correctAnswers, int totalQuestions) {
    return (correctAnswers / totalQuestions) >= 0.5;
  }

  static String getResultMessage(int correctAnswers, int totalQuestions) {
    final percentage = correctAnswers / totalQuestions;
    
    if (percentage == 1.0) return 'ممتاز! إجابة مثالية';
    if (percentage >= 0.8) return 'أحسنت! أداء رائع';
    if (percentage >= 0.5) return 'جيد! استمر في التعلم';
    return 'حاول مرة أخرى';
  }
}
