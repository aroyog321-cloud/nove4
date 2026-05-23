package com.anonymous.nove_mobile_flutter

import android.content.Context
import android.content.Intent
import android.content.pm.ResolveInfo
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val METHOD_CHANNEL     = "com.nove.app_link"
    private val EVENT_CHANNEL      = "com.nove.app_launch_events"
    private val ADS_METHOD_CHANNEL = "com.nove.ads"

    private var bannerShownThisSession = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── App launch event stream ────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(AppLaunchStreamHandler)

        // ── App-link / accessibility method channel ────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        result.success(checkAccessibilityEnabled(this@MainActivity))
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        this@MainActivity.startActivity(intent)
                        result.success(null)
                    }
                    "getInstalledApps" -> {
                        val pm = this@MainActivity.packageManager
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
                    }
                    "syncLinks" -> {
                        @Suppress("UNCHECKED_CAST")
                        val links = call.arguments as? Map<String, String>
                        if (links != null) {
                            val prefs = this@MainActivity
                                .getSharedPreferences("nove_links", Context.MODE_PRIVATE)
                            val editor = prefs.edit()
                            editor.clear()
                            for ((pkg, id) in links) editor.putString(pkg, id)
                            editor.apply()
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── AdMaven ads method channel ─────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADS_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
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

    // ── Show banner ad once on first resume after launch ──────────────────────
    // onResume is called after the activity is fully visible and the Flutter
    // engine is ready — safe to add views to the window here.
    override fun onResume() {
        super.onResume()
        if (!bannerShownThisSession) {
            bannerShownThisSession = true
            // Small delay to let Flutter finish its first frame render
            window.decorView.postDelayed({
                InAppAdsBanner(this@MainActivity).show()
            }, 1500)
        }
    }

    private fun checkAccessibilityEnabled(context: Context): Boolean {
        var accessibilityEnabled = 0
        val service =
            packageName + "/" + NoveAccessibilityService::class.java.canonicalName
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                context.applicationContext.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            return false
        }
        val mStringColonSplitter = TextUtils.SimpleStringSplitter(':')
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                context.applicationContext.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                mStringColonSplitter.setString(settingValue)
                while (mStringColonSplitter.hasNext()) {
                    if (mStringColonSplitter.next().equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}