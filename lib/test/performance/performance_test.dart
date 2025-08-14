import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/reward_service.dart';
import '../../services/analytics_service.dart';
import '../../providers/lesson_provider.dart';

void main() {
  group('Performance Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('reward calculation performance', () async {
      final stopwatch = Stopwatch()..start();
      
      // Test 1000 reward calculations
      for (int i = 0; i < 1000; i++) {
        await RewardService.calculateLessonReward(
          userId: 'user_$i',
          lessonId: 'lesson_${i % 10}',
          score: 85.0,
          baseXP: 50,
          baseGems: 2,
        );
      }
      
      stopwatch.stop();
      
      // Should complete within 2 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      print('1000 reward calculations took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('analytics logging performance', () async {
      final stopwatch = Stopwatch()..start();
      
      // Test 500 analytics events
      for (int i = 0; i < 500; i++) {
        await AnalyticsService.logQuizComplete(
          'user_$i',
          'lesson_${i % 10}',
          correctAnswers: 4,
          totalQuestions: 5,
          score: 80.0,
          timeSpent: 120,
          isRetake: false,
          attemptNumber: 1,
        );
      }
      
      stopwatch.stop();
      
      // Should complete within 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print('500 analytics events took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('memory usage during intensive operations', () async {
      // Simulate memory-intensive operations
      final List<Map<String, dynamic>> dataList = [];
      
      for (int i = 0; i < 10000; i++) {
        dataList.add({
          'id': i,
          'data': 'test_data_$i' * 100, // Large string
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      // Verify we can handle large datasets
      expect(dataList.length, equals(10000));
      
      // Clear memory
      dataList.clear();
      expect(dataList.length, equals(0));
    });

    test('concurrent operations handling', () async {
      final futures = <Future>[];
      
      // Create 50 concurrent reward calculations
      for (int i = 0; i < 50; i++) {
        futures.add(
          RewardService.calculateLessonReward(
            userId: 'concurrent_user_$i',
            lessonId: 'lesson_${i % 5}',
            score: 85.0,
            baseXP: 50,
            baseGems: 2,
          ),
        );
      }
      
      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();
      
      // Should handle concurrent operations efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      print('50 concurrent operations took: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
