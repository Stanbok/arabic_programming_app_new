import '../../core/constants/app_constants.dart';

/// Service for managing ads (currently disabled)
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Initialize ads SDK (no-op when disabled)
  Future<void> initialize() async {
    // Ads disabled - no initialization needed
  }

  /// Check if ad is ready (always true when disabled)
  bool get isAdReady => true;

  /// Show rewarded ad
  /// Returns true immediately since ads are disabled
  Future<bool> showRewardedAd() async {
    // Ads disabled - grant reward immediately
    return true;
  }

  /// Dispose resources (no-op when disabled)
  void dispose() {
    // Nothing to dispose
  }
}
