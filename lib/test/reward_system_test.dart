import 'package:flutter_test/flutter_test.dart';
import '../services/reward_service.dart';
import '../services/statistics_service.dart';
import '../models/lesson_model.dart';

void main() {
  group('Reward System Tests', () {
    test('Lesson completion rewards calculation', () async {
      // Create a mock lesson
      final lesson = LessonModel(
        id: 'test_lesson_001',
        title: 'Test Lesson',
        description: 'Test Description',
        content: [],
        quiz: [],
        unit: 1,
        order: 1,
        xpReward: 100,
        gemsReward: 50,
        isPublished: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test first pass - should get full rewards
      final firstPassReward = await RewardService.getLessonRewards(
        lesson, 
        85, // 85% score
        'test_user', 
        true // first pass
      );

      expect(firstPassReward.xp, equals(125)); // 100 * 1.25 (good performance)
      expect(firstPassReward.gems, equals(62)); // 50 * 1.25 (good performance)
      expect(firstPassReward.isFirstPass, equals(true));
      expect(firstPassReward.retakeMultiplier, equals(1.0));
    });

    test('Retake multiplier calculation', () async {
      // This would require mocking the statistics service
      // For now, we test the basic logic
      final multiplier = await StatisticsService.calculateRetakeMultiplier('test_lesson', 'test_user');
      expect(multiplier, isA<double>());
      expect(multiplier, greaterThanOrEqualTo(0.0));
      expect(multiplier, lessThanOrEqualTo(1.0));
    });

    test('Score validation', () {
      expect(RewardService.isValidScore(85, 10), equals(true));
      expect(RewardService.isValidScore(-5, 10), equals(false));
      expect(RewardService.isValidScore(105, 10), equals(false));
      expect(RewardService.isValidScore(85, 0), equals(false));
    });

    test('Score calculation', () {
      expect(RewardService.calculateScore(8, 10), equals(80));
      expect(RewardService.calculateScore(10, 10), equals(100));
      expect(RewardService.calculateScore(0, 10), equals(0));
      expect(RewardService.calculateScore(5, 0), equals(0));
    });
  });

  group('Statistics Service Tests', () {
    test('User statistics structure', () async {
      final stats = await StatisticsService.getUserStatistics('test_user');
      
      expect(stats, containsPair('totalAttempts', isA<int>()));
      expect(stats, containsPair('totalLessonsCompleted', isA<int>()));
      expect(stats, containsPair('averageScore', isA<double>()));
      expect(stats, containsPair('totalXPEarned', isA<int>()));
      expect(stats, containsPair('totalGemsEarned', isA<int>()));
      expect(stats, containsPair('averageScoringTime', isA<double>()));
      expect(stats, containsPair('completionRate', isA<double>()));
    });
  });
}
