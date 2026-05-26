package com.anonymous.nove_mobile_flutter

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.animation.TranslateAnimation
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class InAppAdsBanner(private val activity: Activity) {

    companion object {
        private const val RT_DOMAIN      = "boostapp.me"
        private const val TID            = "1279749"
        private const val AUTO_OPEN_SEC  = 5   // auto-open after 5 seconds
        private const val INTERVAL_MS    = 5 * 60 * 1000L  // every 5 minutes
        
        private var handler: Handler? = null
        private var runnable: Runnable? = null
        private var isScheduled = false
    }

    private var bannerContainer: FrameLayout? = null
    private var ptrUrl: String? = null
    private var countDownTimer: CountDownTimer? = null

    // ── Start the 5-minute repeating timer ───────────────────────────────────
    fun startRepeating() {
        if (isScheduled) return
        isScheduled = true

        handler = Handler(Looper.getMainLooper())
        runnable = object : Runnable {
            override fun run() {
                show()
                handler?.postDelayed(this, INTERVAL_MS)
            }
        }
        // First banner after 5 minutes
        handler?.postDelayed(runnable!!, INTERVAL_MS)
    }

    // ── Stop the repeating timer (call from onDestroy) ────────────────────────
    fun stopRepeating() {
        runnable?.let { handler?.removeCallbacks(it) }
        handler = null
        runnable = null
        isScheduled = false
    }

    // ── Fetch ad and show banner ──────────────────────────────────────────────
    private fun show() {
        Thread {
            try {
                val url  = URL("https://$RT_DOMAIN/inapp?tid=$TID")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod  = "GET"
                conn.connectTimeout = 5000
                conn.readTimeout    = 5000

                when (conn.responseCode) {
                    200 -> {
                        val body = conn.inputStream.bufferedReader().readText()
                        ptrUrl   = JSONObject(body).getString("ptr")
                        activity.runOnUiThread { buildAndShow() }
                    }
                    else -> { /* no ad available, skip silently */ }
                }
            } catch (e: Exception) {
                // network error, skip silently
            }
        }.start()
    }

    // ── Build the banner UI ───────────────────────────────────────────────────
    private fun buildAndShow() {
        // Remove any existing banner first
        dismissSilently()

        val isDark = isAppInDarkMode()

        val bgStart     = Color.parseColor("#6C63FF")
        val bgEnd       = Color.parseColor("#3B82F6")
        val textColor   = Color.WHITE
        val timerColor  = Color.parseColor(if (isDark) "#CCCCCC" else "#EEEEEE")

        // ── Outer container pinned to bottom ──────────────────────────────────
        bannerContainer = FrameLayout(activity).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { gravity = Gravity.BOTTOM }
            elevation = dp(16).toFloat()
        }

        // ── Banner card ───────────────────────────────────────────────────────
        val bannerCard = LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            background  = GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                intArrayOf(bgStart, bgEnd)
            )
            setPadding(dp(16), dp(14), dp(16), dp(14))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        // AD badge
        val adBadge = TextView(activity).apply {
            setText("AD")
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 9f)
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(bgStart)
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(4).toFloat()
            }
            setPadding(dp(6), dp(3), dp(6), dp(3))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { rightMargin = dp(10) }
        }

        // Ad text
        val adText = TextView(activity).apply {
            setText("Exclusive offer loading — opening now...")
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(textColor)
            layoutParams = LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f
            )
        }

        // Countdown timer text
        val timerText = TextView(activity).apply {
            setText("${AUTO_OPEN_SEC}s")
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(timerColor)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { leftMargin = dp(8) }
        }

        bannerCard.addView(adBadge)
        bannerCard.addView(adText)
        bannerCard.addView(timerText)

        bannerContainer!!.addView(bannerCard)

        // Add to root view
        val rootView = activity.window.decorView.rootView as ViewGroup
        rootView.addView(bannerContainer)

        // Slide up animation
        val slideUp = TranslateAnimation(0f, 0f, dp(80).toFloat(), 0f).apply {
            duration  = 300
            fillAfter = true
        }
        bannerContainer!!.startAnimation(slideUp)

        // ── Countdown: 5 seconds then auto-open ──────────────────────────────
        countDownTimer = object : CountDownTimer(
            (AUTO_OPEN_SEC * 1000).toLong(), 1000
        ) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsLeft = (millisUntilFinished / 1000).toInt() + 1
                activity.runOnUiThread {
                    timerText.setText("${secondsLeft}s")
                }
            }

            override fun onFinish() {
                activity.runOnUiThread {
                    // Auto-open the ad URL
                    openAdUrl()
                    // Dismiss banner after opening
                    Handler(Looper.getMainLooper()).postDelayed({
                        dismissSilently()
                    }, 500)
                }
            }
        }.start()
    }

    // ── Open ad URL in browser ────────────────────────────────────────────────
    private fun openAdUrl() {
        ptrUrl?.let { ptr ->
            val fullUrl = if (ptr.startsWith("//")) "https:$ptr" else ptr
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(fullUrl))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                activity.startActivity(intent)
            } catch (e: Exception) {
                // silently ignore
            }
        }
    }

    // ── Remove banner from screen ─────────────────────────────────────────────
    private fun dismissSilently() {
        countDownTimer?.cancel()
        bannerContainer?.let {
            (it.parent as? ViewGroup)?.removeView(it)
            bannerContainer = null
        }
    }

    private fun isAppInDarkMode(): Boolean {
        val nightModeFlags = activity.resources.configuration.uiMode and
                android.content.res.Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == android.content.res.Configuration.UI_MODE_NIGHT_YES
    }

    private fun dp(value: Int): Int {
        return (value * activity.resources.displayMetrics.density).toInt()
    }
}
