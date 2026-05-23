import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AdsService — AdMaven Native Integration
//
//  Uses the official AdMaven boostapp.me inapp API via native Kotlin code.
//  No WebView. No third-party Flutter plugin.
//
//  Android side:
//    • InAppAdsInterstitial.kt — zone 1279738 — triggered on new note save
//    • InAppAdsBanner.kt       — zone 1279749 — shown on app launch
//    • Both wired in MainActivity.kt
//
//  Dart side (this file):
//    • AdsService.initialize()     — call once from main()
//    • AdsService.showInterstitial — calls native via MethodChannel,
//                                    awaits dismiss, then fires onComplete
//
//  The banner is shown automatically by MainActivity.onFlutterUiDisplayed()
//  so no Dart code is needed for it.
// ═══════════════════════════════════════════════════════════════════════════════

class AdsService {
  static const MethodChannel _channel = MethodChannel('com.nove.ads');

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // ── Initialize ───────────────────────────────────────────────────────────────
  // Call once from main() before runApp().
  static Future<void> initialize() async {
    try {
      _initialized = true;
      debugPrint('✅ AdsService: AdMaven native service ready');
    } catch (e) {
      debugPrint('❌ AdsService: Initialization error — $e');
    }
  }

  // ── Show Interstitial ────────────────────────────────────────────────────────
  // Calls native Kotlin InAppAdsInterstitial via MethodChannel.
  // Waits for the user to dismiss the ad (tap Continue), then fires onComplete.
  // If the ad fails or no ad is available, onComplete is still called so
  // the editor always pops back normally.
  static Future<void> showInterstitial({
    required BuildContext context,
    VoidCallback? onComplete,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️  AdsService: Not initialized');
      onComplete?.call();
      return;
    }

    try {
      debugPrint('▶️  AdsService: Requesting AdMaven interstitial from native');
      await _channel.invokeMethod('showInterstitial');
      debugPrint('✅ AdsService: Interstitial dismissed');
    } catch (e) {
      debugPrint('❌ AdsService: Interstitial error — $e');
    } finally {
      // Always fire onComplete so the editor pops back
      onComplete?.call();
    }
  }
}