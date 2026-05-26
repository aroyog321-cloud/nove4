import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdsService {
  static const MethodChannel _channel = MethodChannel('com.nove.ads');

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    _initialized = true;
    debugPrint('✅ AdsService: AdMaven ready');
  }

  // ── Call this after note is saved ────────────────────────────────────────────
  // The ad URL opens automatically in browser after 1 second.
  // The app navigates back immediately — user doesn't wait.
  static Future<void> showInterstitial({
    required BuildContext context,
    VoidCallback? onComplete,
  }) async {
    try {
      // Fire and forget — don't await, so app navigates back instantly
      _channel.invokeMethod('showInterstitial');
      debugPrint('▶️  AdsService: Ad URL will open in 1 second');
    } catch (e) {
      debugPrint('❌ AdsService: Error — $e');
    } finally {
      // Navigate back immediately, ad opens in background after 1 sec
      onComplete?.call();
    }
  }
}