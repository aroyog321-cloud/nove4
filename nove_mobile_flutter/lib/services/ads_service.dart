import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdsService {
  // ── Replace this with your actual Game ID from Unity Dashboard ──────────────
  // Go to: dashboard.unity.com → your project → Monetization → Get Started
  // It is a number like: 1234567
  static const String _gameId = '6116524';

  // ── Placement IDs — must match exactly what is in Unity Dashboard ───────────
  // Go to: dashboard.unity.com → Monetization → Ad Units
  static const String interstitialPlacementId = 'Interstitial_Android';
  static const String rewardedPlacementId     = 'Rewarded_Android';
  static const String bannerPlacementId       = 'Banner_Android';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // ── Initialize Unity Ads ────────────────────────────────────────────────────
  // Call once from main() before runApp()
  static Future<void> initialize() async {
    try {
      await UnityAds.init(
        gameId: _gameId,
        testMode: true, // ← keep true until you confirm ads are showing,
        //   then change to: kDebugMode
        onComplete: () {
          _initialized = true;
          debugPrint('✅ AdsService: Unity Ads initialized successfully');
          // Pre-load ads as soon as init is done
          loadInterstitial();
          loadRewarded();
        },
        onFailed: (error, message) {
          _initialized = false;
          debugPrint('❌ AdsService: Init FAILED — error: $error | message: $message');
          debugPrint('❌ Check your Game ID is correct in ads_service.dart');
        },
      );
    } catch (e) {
      debugPrint('❌ AdsService: Exception during init — $e');
    }
  }

  // ── Load Interstitial ───────────────────────────────────────────────────────
  static void loadInterstitial() {
    if (!_initialized) {
      debugPrint('⚠️ AdsService: Cannot load interstitial — not initialized yet');
      return;
    }
    UnityAds.load(
      placementId: interstitialPlacementId,
      onComplete: (id) => debugPrint('✅ AdsService: Interstitial loaded — $id'),
      onFailed: (id, error, message) =>
          debugPrint('❌ AdsService: Interstitial load FAILED — $id | $error | $message'),
    );
  }

  // ── Show Interstitial ───────────────────────────────────────────────────────
  // Shows a full screen ad. Calls onComplete when done (whether ad showed or not)
  // so your app always continues normally even if the ad fails.
  static void showInterstitial({VoidCallback? onComplete}) {
    if (!_initialized) {
      debugPrint('⚠️ AdsService: Cannot show interstitial — not initialized');
      onComplete?.call();
      return;
    }
    UnityAds.showVideoAd(
      placementId: interstitialPlacementId,
      onComplete: (id) {
        debugPrint('✅ AdsService: Interstitial completed — $id');
        onComplete?.call();
        loadInterstitial(); // pre-load next one immediately
      },
      onFailed: (id, error, message) {
        debugPrint('❌ AdsService: Interstitial show FAILED — $id | $error | $message');
        onComplete?.call(); // always continue even if ad fails
        loadInterstitial();
      },
      onSkipped: (id) {
        debugPrint('⚠️ AdsService: Interstitial skipped — $id');
        onComplete?.call();
        loadInterstitial();
      },
      onStart: (id) => debugPrint('▶️ AdsService: Interstitial started — $id'),
      onClick: (id) => debugPrint('👆 AdsService: Interstitial clicked — $id'),
    );
  }

  // ── Load Rewarded ───────────────────────────────────────────────────────────
  static void loadRewarded() {
    if (!_initialized) {
      debugPrint('⚠️ AdsService: Cannot load rewarded — not initialized yet');
      return;
    }
    UnityAds.load(
      placementId: rewardedPlacementId,
      onComplete: (id) => debugPrint('✅ AdsService: Rewarded loaded — $id'),
      onFailed: (id, error, message) =>
          debugPrint('❌ AdsService: Rewarded load FAILED — $id | $error | $message'),
    );
  }

  // ── Show Rewarded ───────────────────────────────────────────────────────────
  // Shows a rewarded ad. Only calls onReward if user watches the full ad.
  // Calls onSkipped if user closes early — do NOT give the reward in this case.
  static void showRewarded({
    required VoidCallback onReward,
    VoidCallback? onSkipped,
    VoidCallback? onFailed,
  }) {
    if (!_initialized) {
      debugPrint('⚠️ AdsService: Cannot show rewarded — not initialized');
      onFailed?.call();
      return;
    }
    UnityAds.showVideoAd(
      placementId: rewardedPlacementId,
      onComplete: (id) {
        debugPrint('✅ AdsService: Rewarded completed — user earned reward — $id');
        onReward();
        loadRewarded();
      },
      onFailed: (id, error, message) {
        debugPrint('❌ AdsService: Rewarded show FAILED — $id | $error | $message');
        onFailed?.call();
        loadRewarded();
      },
      onSkipped: (id) {
        debugPrint('⚠️ AdsService: Rewarded skipped — no reward given — $id');
        onSkipped?.call();
        loadRewarded();
      },
      onStart: (id) => debugPrint('▶️ AdsService: Rewarded started — $id'),
      onClick: (id) => debugPrint('👆 AdsService: Rewarded clicked — $id'),
    );
  }
}