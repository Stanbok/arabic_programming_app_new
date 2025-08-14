import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/reward_service.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

void main() {
  group('Security Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Data Integrity Tests', () {
      test('should prevent score tampering', () async {
        // Test various tampering attempts
        final invalidScores = [-1.0, 101.0, double.infinity, double.nan];
        
        for (final score in invalidScores) {
          expect(
            () => RewardService.calculateLessonReward(
              userId: 'test_user',
              lessonId: 'lesson_1',
              score: score,
              baseXP: 50,
              baseGems: 2,
            ),
            throwsA(isA<ArgumentError>()),
            reason: 'Should reject invalid score: $score',
          );
        }
      });

      test('should validate user input sanitization', () async {
        final maliciousInputs = [
          '<script>alert("xss")</script>',
          'DROP TABLE users;',
          '../../etc/passwd',
          'null',
          '',
        ];
        
        for (final input in maliciousInputs) {
          expect(
            () => RewardService.calculateLessonReward(
              userId: input,
              lessonId: 'lesson_1',
              score: 85.0,
              baseXP: 50,
              baseGems: 2,
            ),
            throwsA(isA<ArgumentError>()),
            reason: 'Should reject malicious input: $input',
          );
        }
      });

      test('should prevent negative rewards', () async {
        final reward = await RewardService.calculateLessonReward(
          userId: 'test_user',
          lessonId: 'lesson_1',
          score: 0.0, // Minimum valid score
          baseXP: 50,
          baseGems: 2,
        );
        
        expect(reward, isNull); // No reward for failing score
      });
    });

    group('Rate Limiting Tests', () {
      test('should prevent rapid reward claims', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_rapid';
        
        // First claim should succeed
        final firstClaim = await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        expect(firstClaim, isNotNull);
        
        // Rapid subsequent claims should be limited
        for (int i = 0; i < 10; i++) {
          final rapidClaim = await RewardService.calculateLessonReward(
            userId: userId,
            lessonId: lessonId,
            score: 85.0,
            baseXP: 50,
            baseGems: 2,
          );
          expect(rapidClaim!.xpGained, lessThanOrEqualTo(15)); // Reduced rewards
        }
      });
    });

    group('Data Encryption Tests', () {
      test('should encrypt sensitive local data', () async {
        const userId = 'test_user';
        const lessonId = 'lesson_encrypt';
        
        await RewardService.calculateLessonReward(
          userId: userId,
          lessonId: lessonId,
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
        
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        
        // Check that sensitive data is not stored in plain text
        for (final key in keys) {
          final value = prefs.getString(key) ?? '';
          expect(value.contains('test_user'), isFalse,
              reason: 'User ID should not be stored in plain text');
          expect(value.contains('85.0'), isFalse,
              reason: 'Scores should not be stored in plain text');
        }
      });
    });
  });
}
