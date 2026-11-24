package dev.jaewook.prototype.focus_friend_app

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/** Both layouts use a real MediaView; small video creatives get 120x120dp. */
class ExitNativeAdFactory(private val context: Context) : NativeAdFactory {
    private val ink = Color.rgb(53, 39, 36)
    private val muted = Color.rgb(119, 102, 92)
    private val brown = Color.rgb(118, 82, 57)
    private fun dp(value: Int) = (value * context.resources.displayMetrics.density).toInt()
    private fun surface(fill: Int, stroke: Int? = null, radius: Int = 12) = GradientDrawable().apply {
        setColor(fill)
        cornerRadius = dp(radius).toFloat()
        if (stroke != null) setStroke(dp(1), stroke)
    }
    private fun text(value: CharSequence?, size: Float, bold: Boolean = false) = TextView(context).apply {
        text = value
        textSize = size
        setTextColor(if (bold) ink else muted)
        if (bold) setTypeface(typeface, Typeface.BOLD)
        includeFontPadding = false
        ellipsize = TextUtils.TruncateAt.END
    }
    private fun LinearLayout.gap(height: Int) = addView(View(context), LinearLayout.LayoutParams(1, dp(height)))

    override fun createNativeAd(ad: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val compact = customOptions?.get("compact") == true
        val native = NativeAdView(context)
        native.background = surface(Color.rgb(255, 244, 225), Color.rgb(232, 221, 201))
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
        }
        native.addView(root, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        val heading = LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 0, dp(24), 0) // Space for the SDK AdChoices overlay.
        }
        val badge = text(customOptions?.get("adLabel") as? String ?: "Ad", 11f, true).apply {
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(dp(5), dp(2), dp(5), dp(2))
            background = surface(brown, radius = 4)
            minHeight = dp(18)
            minWidth = dp(18)
        }
        heading.addView(badge)
        ad.icon?.drawable?.let { drawable ->
            val icon = ImageView(context).apply {
                setImageDrawable(drawable)
                scaleType = ImageView.ScaleType.FIT_CENTER
            }
            heading.addView(icon, LinearLayout.LayoutParams(dp(32), dp(32)).apply { leftMargin = dp(6) })
            native.iconView = icon
        }
        val advertiser = text(ad.advertiser ?: ad.store.orEmpty(), 12f).apply {
            maxLines = 1
            gravity = Gravity.CENTER_VERTICAL
        }
        heading.addView(advertiser, LinearLayout.LayoutParams(0, dp(32), 1f).apply { leftMargin = dp(6) })
        if (ad.advertiser != null) native.advertiserView = advertiser
        else if (ad.store != null) native.storeView = advertiser
        root.addView(heading, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(32)))
        root.gap(8)

        val media = MediaView(context).apply { setImageScaleType(ImageView.ScaleType.FIT_CENTER) }
        native.mediaView = media
        ad.mediaContent?.let { media.mediaContent = it }
        val title = text(ad.headline, if (compact) 15f else 17f, true).apply { maxLines = 2 }
        val body = text(ad.body, 12f).apply { maxLines = 2 }
        val cta = Button(context).apply {
            text = ad.callToAction
            isAllCaps = false
            textSize = 14f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(brown)
            background = surface(Color.TRANSPARENT, brown, 9)
            minHeight = 0
            minimumHeight = 0
            minWidth = 0
            setPadding(dp(5), 0, dp(5), 0)
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
            visibility = if (ad.callToAction.isNullOrBlank()) View.GONE else View.VISIBLE
        }
        native.headlineView = title
        if (!ad.body.isNullOrBlank()) native.bodyView = body else body.visibility = View.GONE
        native.callToActionView = cta
        if (compact) {
            val row = LinearLayout(context)
            row.addView(media, LinearLayout.LayoutParams(dp(120), dp(120)))
            val copy = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
            copy.addView(title, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
            copy.gap(4)
            copy.addView(body, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
            copy.gap(4)
            copy.addView(cta, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(40)))
            row.addView(copy, LinearLayout.LayoutParams(0, dp(120), 1f).apply { leftMargin = dp(10) })
            root.addView(row)
        } else {
            root.addView(media, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(150)))
            root.gap(8)
            root.addView(title, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
            root.gap(4)
            root.addView(body, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
            root.gap(8)
            root.addView(cta, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44)))
        }
        // Click handling, impressions and AdChoices belong to the native SDK.
        native.setNativeAd(ad)
        return native
    }
}
