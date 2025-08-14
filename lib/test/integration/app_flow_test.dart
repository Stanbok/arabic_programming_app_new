import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('complete lesson flow with security checks', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lesson
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Start quiz
      await tester.tap(find.text('ابدأ الاختبار'));
      await tester.pumpAndSettle();

      // Answer questions (simulate correct answers)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(RadioListTile).first);
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
      }

      // Verify results screen
      expect(find.text('النتيجة'), findsOneWidget);
      expect(find.textContaining('XP'), findsOneWidget);
      expect(find.textContaining('جوهرة'), findsOneWidget);

      // Verify next lesson is unlocked
      await tester.tap(find.text('العودة للدروس'));
      await tester.pumpAndSettle();

      // Check that next lesson is now available
      final nextLessonCard = find.byType(Card).at(1);
      expect(nextLessonCard, findsOneWidget);
    });

    testWidgets('retake system works correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Complete lesson first time
      await _completeLessonFlow(tester, correctAnswers: 4);

      // Retake the same lesson
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Should show retake warning
      expect(find.textContaining('إعادة المحاولة'), findsOneWidget);
      expect(find.textContaining('30%'), findsOneWidget);

      await tester.tap(find.text('ابدأ الاختبار'));
      await tester.pumpAndSettle();

      // Complete again
      await _completeLessonFlow(tester, correctAnswers: 5);

      // Verify reduced rewards
      expect(find.textContaining('15 XP'), findsOneWidget); // 50 * 0.3
    });

    testWidgets('security: prevent rapid retakes', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to complete same lesson multiple times rapidly
      for (int i = 0; i < 3; i++) {
        await _completeLessonFlow(tester, correctAnswers: 4);
        await tester.pumpAndSettle();
      }

      // Should show rate limiting message
      expect(find.textContaining('محاولات كثيرة'), findsOneWidget);
    });
  });
}

Future<void> _completeLessonFlow(WidgetTester tester, {required int correctAnswers}) async {
  await tester.tap(find.byType(Card).first);
  await tester.pumpAndSettle();

  await tester.tap(find.text('ابدأ الاختبار'));
  await tester.pumpAndSettle();

  // Answer questions
  for (int i = 0; i < 5; i++) {
    if (i < correctAnswers) {
      await tester.tap(find.byType(RadioListTile).first); // Correct answer
    } else {
      await tester.tap(find.byType(RadioListTile).at(1)); // Wrong answer
    }
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('العودة للدروس'));
  await tester.pumpAndSettle();
}
