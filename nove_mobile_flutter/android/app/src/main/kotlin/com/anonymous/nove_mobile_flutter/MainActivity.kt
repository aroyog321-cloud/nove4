package com.anonymous.nove_mobile_flutter

import android.content.Context
import android.content.Intent
import android.content.pm.ResolveInfo
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val METHOD_CHANNEL     = "com.nove.app_link"
        private const val EVENT_CHANNEL      = "com.nove.app_launch_events"
        private const val ADS_METHOD_CHANNEL = "com.nove.ads"
    }

    private val bannerAd by lazy { InAppAdsBanner(this) }

    override fun onResume() {
        super.onResume()
        // Start 5-minute repeating banner when app is in foreground
        bannerAd.startRepeating()
    }

    override fun onPause() {
        super.onPause()
        // Stop banner timer when app goes to background
        bannerAd.stopRepeating()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(AppLaunchStreamHandler)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(checkAccessibilityEnabled(this))
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ACCESSIBILITY_ERROR", e.message, null)
                    }
                }
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val intent = Intent(Intent.ACTION_MAIN, null)
                        intent.addCategory(Intent.CATEGORY_LAUNCHER)
                        val apps: List<ResolveInfo> = pm.queryIntentActivities(intent, 0)
                        val appList = ArrayList<Map<String, String>>()
                        for (resolveInfo in apps) {
                            val map = HashMap<String, String>()
                            map["name"] = resolveInfo.loadLabel(pm).toString()
                            map["packageName"] = resolveInfo.activityInfo.packageName
                            appList.add(map)
                        }
                        result.success(appList)
                    } catch (e: Exception) {
                        result.error("APP_LIST_ERROR", e.message, null)
                    }
                }
                "syncLinks" -> {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        val links = call.arguments as? Map<String, String>
                        if (links != null) {
                            val prefs = getSharedPreferences(
                                "nove_links", Context.MODE_PRIVATE
                            )
                            val editor = prefs.edit()
                            editor.clear()
                            for ((pkg, id) in links) editor.putString(pkg, id)
                            editor.apply()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SYNC_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── AdMaven interstitial — auto-opens 1 sec after note save ───────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ADS_METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showInterstitial" -> {
                    InAppAdsInterstitial(this@MainActivity).show(
                        onDismiss = { result.success(null) }
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAccessibilityEnabled(context: Context): Boolean {
        val service = packageName + "/" + NoveAccessibilityService::class.java.canonicalName
        return try {
            val accessibilityEnabled = Settings.Secure.getInt(
                context.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
            if (accessibilityEnabled == 1) {
                val settingValue = Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                )
                if (settingValue != null) {
                    val splitter = TextUtils.SimpleStringSplitter(':')
                    splitter.setString(settingValue)
                    while (splitter.hasNext()) {
                        if (splitter.next().equals(service, ignoreCase = true)) return true
                    }
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }
}