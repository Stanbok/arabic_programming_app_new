import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHelper {
  static Future<void> setupTestEnvironment() async {
    SharedPreferences.setMockInitialValues({});
  }
  
  static Future<void> cleanupTestEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  static void expectSecureString(String value) {
    // Check that sensitive data is not in plain text
    expect(value.contains('password'), isFalse);
    expect(value.contains('token'), isFalse);
    expect(value.contains('secret'), isFalse);
  }
  
  static void expectValidReward(dynamic reward) {
    expect(reward, isNotNull);
    expect(reward.xpGained, greaterThanOrEqualTo(0));
    expect(reward.gemsGained, greaterThanOrEqualTo(0));
  }
  
  static Future<void> simulateNetworkDelay([int milliseconds = 100]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }
}
