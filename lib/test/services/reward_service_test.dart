import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/reward_service.dart';
import '../../models/lesson_model.dart';

void main() {
  group('RewardService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Security Tests', () {
      test('should prevent duplicate rewards for same lesson', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_1';
        
        // First completion
        final firstReward = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        
        expect(firstReward, isNotNull);
        expect(firstReward!.xpGained, equals(50));
        
        // Attempt duplicate completion
        final duplicateReward = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        
        // Should return reduced reward for retake
        expect(duplicateReward, isNotNull);
        expect(duplicateReward!.xpGained, lessThan(50));
      });

      test('should validate score ranges', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_1';
        
        // Test invalid scores
        expect(
          () => RewardService.calculateLessonReward(
            userId: userId,
            lessonId: lessonId,
            score: -10.0, // Invalid negative score
            baseXP: 50,
            baseGems: 2,
          ),
          throwsArgumentError,
        );
        
        expect(
          () => RewardService.calculateLessonReward(
            userId: userId,
            lessonId: lessonId,
            score: 150.0, // Invalid score > 100
            baseXP: 50,
            baseGems: 2,
          ),
          throwsArgumentError,
        );
      });

      test('should prevent XP manipulation', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_1';
        
        final reward = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 95.0,
          baseXP: 50,
          baseGems: 2,
        );
        
        // Verify XP calculation is server-side controlled
        expect(reward!.xpGained, equals(75)); // 50 * 1.5 for 95% score
        expect(reward.gemsGained, equals(3)); // 2 * 1.5 for 95% score
      });
    });

    group('Retake System Tests', () {
      test('should apply correct retake penalties', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_retake';
        
        // First successful completion
        await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        
        // First retake (30%)
        final firstRetake = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 90.0,
          baseXP: 50,
          baseGems: 2,
        );
        expect(firstRetake!.xpGained, equals(15)); // 50 * 0.3
        
        // Second retake (20%)
        final secondRetake = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 95.0,
          baseXP: 50,
          baseGems: 2,
        );
        expect(secondRetake!.xpGained, equals(10)); // 50 * 0.2
      });

      test('should reset retake penalties after 24 hours', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_time_reset';
        
        // Complete lesson
        await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        
        // Simulate 24+ hours passing
        final prefs = await SharedPreferences.getInstance();
        final oldTime = DateTime.now().subtract(const Duration(hours: 25));
        await prefs.setString(
          'last_success_${userId}_$lessonId',
          oldTime.toIso8601String(),
        );
        
        // Should get 30% again (reset)
        final resetRetake = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        expect(resetRetake!.xpGained, equals(15)); // 50 * 0.3
      });
    });

    group('Performance Tests', () {
      test('should calculate rewards quickly', () async {
        const userId = 'test_user';
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          await RewardService.calculateLessonReward(
            userId: userId,
            lessonId: 'lesson_$i',
            score: 85.0,
            baseXP: 50,
            baseGems: 2,
          );
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // < 1 second
      });
    });
  });
}
