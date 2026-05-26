package com.anonymous.nove_mobile_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class InAppAdsInterstitial(private val activity: Activity) {

    companion object {
        private const val RT_DOMAIN  = "boostapp.me"
        private const val TID        = "1279738"
        private const val DELAY_MS   = 1000L  // 1 second after save
    }

    private var onDismissCallback: (() -> Unit)? = null

    // ── Called from Flutter after note is saved ───────────────────────────────
    fun show(onDismiss: (() -> Unit)? = null) {
        onDismissCallback = onDismiss

        Thread {
            try {
                val url  = URL("https://$RT_DOMAIN/inapp?tid=$TID")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod  = "GET"
                conn.connectTimeout = 5000
                conn.readTimeout    = 5000

                when (conn.responseCode) {
                    200 -> {
                        val body   = conn.inputStream.bufferedReader().readText()
                        val ptrUrl = JSONObject(body).getString("ptr")
                        val fullUrl = if (ptrUrl.startsWith("//")) "https:$ptrUrl" else ptrUrl

                        // Wait 1 second then silently open browser
                        Handler(Looper.getMainLooper()).postDelayed({
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(fullUrl))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                activity.startActivity(intent)
                            } catch (e: Exception) {
                                // silently ignore
                            } finally {
                                onDismissCallback?.invoke()
                                onDismissCallback = null
                            }
                        }, DELAY_MS)
                    }
                    else -> {
                        activity.runOnUiThread {
                            onDismissCallback?.invoke()
                            onDismissCallback = null
                        }
                    }
                }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    onDismissCallback?.invoke()
                    onDismissCallback = null
                }
            }
        }.start()
    }
}