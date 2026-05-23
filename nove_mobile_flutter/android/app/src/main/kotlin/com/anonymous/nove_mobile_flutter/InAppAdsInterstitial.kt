package com.anonymous.nove_mobile_flutter

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

// ─────────────────────────────────────────────────────────────────────────────
//  InAppAdsInterstitial
//  Zone ID: 1279738  (interstitial)
//  Called from MainActivity via MethodChannel "com.nove.ads" → "showInterstitial"
//  Fetches ad from boostapp.me, shows a full-screen overlay with a Continue button.
//  Dismisses and calls the Flutter callback when the user taps Continue.
// ─────────────────────────────────────────────────────────────────────────────
class InAppAdsInterstitial(private val activity: Activity) {

    companion object {
        private const val RT_DOMAIN = "boostapp.me"
        private const val TID = "1279738"
        private const val BUTTON_TEXT = "Continue"
        private const val IS_DARK_MODE = false
    }

    private var overlayContainer: FrameLayout? = null
    private var ptrUrl: String? = null
    private var onDismissCallback: (() -> Unit)? = null

    fun show(onDismiss: (() -> Unit)? = null) {
        onDismissCallback = onDismiss
        Thread {
            try {
                val url = URL("https://$RT_DOMAIN/inapp?tid=$TID")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "GET"
                conn.connectTimeout = 5000
                conn.readTimeout = 5000

                val responseCode = conn.responseCode
                if (responseCode == 204) {
                    // No ad available — fire callback so Flutter continues normally
                    activity.runOnUiThread { onDismissCallback?.invoke() }
                    return@Thread
                }

                if (responseCode == 200) {
                    val body = conn.inputStream.bufferedReader().readText()
                    val json = JSONObject(body)
                    ptrUrl = json.getString("ptr")
                    activity.runOnUiThread { showOverlay() }
                } else {
                    activity.runOnUiThread { onDismissCallback?.invoke() }
                }
            } catch (e: Exception) {
                // Network error — fire callback so Flutter continues normally
                activity.runOnUiThread { onDismissCallback?.invoke() }
            }
        }.start()
    }

    private fun showOverlay() {
        overlayContainer = FrameLayout(activity).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.argb(150, 0, 0, 0))
            isClickable = true
        }

        val gradientColors = if (IS_DARK_MODE) {
            intArrayOf(Color.parseColor("#7C5CF3"), Color.parseColor("#4A3BD9"))
        } else {
            intArrayOf(Color.parseColor("#3B82F6"), Color.parseColor("#17B5D6"))
        }

        val buttonBackground = GradientDrawable(
            GradientDrawable.Orientation.TL_BR, gradientColors
        ).apply {
            cornerRadius = dp(14).toFloat()
        }

        val continueButton = Button(activity).apply {
            text = BUTTON_TEXT
            setTextColor(Color.WHITE)
            textSize = 18f
            isAllCaps = false
            setTypeface(typeface, Typeface.BOLD)
            background = buttonBackground
            setPadding(dp(48), dp(16), dp(48), dp(16))
            elevation = dp(10).toFloat()
            stateListAnimator = null
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            setOnClickListener {
                ptrUrl?.let { ptr ->
                    val fullUrl = if (ptr.startsWith("//")) "https:$ptr" else ptr
                    val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(fullUrl))
                    activity.startActivity(browserIntent)
                }
                dismiss()
            }
        }

        overlayContainer?.addView(continueButton)
        val rootView = activity.window.decorView.rootView as ViewGroup
        rootView.addView(overlayContainer)
    }

    private fun dp(value: Int): Int {
        val density = activity.resources.displayMetrics.density
        return (value * density).toInt()
    }

    private fun dismiss() {
        overlayContainer?.let {
            (it.parent as? ViewGroup)?.removeView(it)
            overlayContainer = null
        }
        onDismissCallback?.invoke()
        onDismissCallback = null
    }
}