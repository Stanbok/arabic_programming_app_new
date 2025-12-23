import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/app_constants.dart';

/// Service for managing AdMob rewarded video ads
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Initialize ads SDK (no-op when disabled)
  Future<void> initialize() async {
    // Ads disabled - no initialization needed
  }

  /// Load a rewarded ad (no-op when disabled)
  void _loadRewardedAd() {
    // Nothing to load when ads are disabled
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
