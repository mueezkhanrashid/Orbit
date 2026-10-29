package com.orbit.app

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService

// RemoteViewsService for swipeable StackView — modern flat icons, no emojis
class OrbitWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = OrbitRemoteViewsFactory(applicationContext)
}

class OrbitRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var cards: List<Map<String, String>> = emptyList()

    private fun drawableForKey(key: String): Int = when (key) {
        "namaz" -> R.drawable.ic_namaz
        "qibla" -> R.drawable.ic_qibla
        "space" -> R.drawable.ic_space
        "news" -> R.drawable.ic_news
        "jobs" -> R.drawable.ic_jobs
        "weather" -> R.drawable.ic_weather
        "markets" -> R.drawable.ic_markets
        "quran" -> R.drawable.ic_quran
        "scholarships" -> R.drawable.ic_scholarships
        "internships" -> R.drawable.ic_internships
        "zikar" -> R.drawable.ic_zikar
        else -> R.drawable.ic_namaz
    }

    override fun onCreate() {}
    override fun onDestroy() {}
    override fun getCount(): Int = cards.size
    override fun getViewTypeCount(): Int = 2
    override fun getLoadingView(): RemoteViews? = null
    override fun hasStableIds(): Boolean = true
    override fun getItemId(p: Int): Long = p.toLong()
    override fun getViewAt(pos: Int): RemoteViews {
        val c = cards.getOrNull(pos) ?: return RemoteViews(context.packageName, R.layout.orbit_widget_card)
        val views = RemoteViews(context.packageName, R.layout.orbit_widget_card)
        val assetKey = c["glyph"] ?: c["type"] ?: "namaz"
        val iconRes = drawableForKey(assetKey)
        views.setImageViewResource(R.id.card_glyph, iconRes)
        views.setTextViewText(R.id.card_label, c["label"] ?: "")
        views.setTextViewText(R.id.card_title, c["title"] ?: "")
        views.setTextViewText(R.id.card_subtitle, c["subtitle"] ?: "")
        views.setTextViewText(R.id.card_meta, c["meta"] ?: "")
        views.setTextViewText(R.id.card_value, c["value"] ?: "")
        // Qibla bearing
        val bearing = c["bearing"] ?: ""
        val bearingLabel = c["bearingLabel"] ?: ""
        val isQibla = (c["type"] ?: "") == "qibla" || bearing.isNotEmpty()
        if (isQibla && bearingLabel.isNotEmpty()) {
            views.setTextViewText(R.id.card_bearing, bearingLabel)
            views.setImageViewResource(R.id.card_arrow, R.drawable.ic_qibla)
            views.setViewVisibility(R.id.card_qibla_badge, View.VISIBLE)
            views.setViewVisibility(R.id.card_qibla_hint, View.VISIBLE)
            views.setTextViewText(R.id.card_qibla_hint, bearingLabel)
            if (bearingLabel.isNotEmpty()) views.setTextViewText(R.id.card_time, bearingLabel)
        } else {
            val metaTime = c["meta"]?.let { extractTime(it) } ?: "now"
            views.setTextViewText(R.id.card_time, metaTime)
            if (bearingLabel.isNotEmpty()) {
                views.setTextViewText(R.id.card_bearing, bearingLabel)
                views.setImageViewResource(R.id.card_arrow, R.drawable.ic_qibla)
                views.setViewVisibility(R.id.card_qibla_badge, View.VISIBLE)
                views.setViewVisibility(R.id.card_qibla_hint, View.GONE)
            } else {
                views.setViewVisibility(R.id.card_qibla_badge, View.GONE)
                views.setViewVisibility(R.id.card_qibla_hint, View.GONE)
            }
        }
        val fill = Intent().apply {
            putExtra("card_type", c["type"] ?: "")
            putExtra("bearing", bearing)
        }
        views.setOnClickFillInIntent(R.id.card_root, fill)
        return views
    }

    private fun extractTime(meta: String): String {
        val parts = meta.split("•")
        for (p in parts.reversed()) {
            val t = p.trim()
            if (Regex("""\d{1,2}:\d{2}""").containsMatchIn(t)) return t.take(5)
        }
        return "now"
    }

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val count = prefs.getInt("widget_count", 0)
        val list = mutableListOf<Map<String, String>>()
        for (i in 0 until count) {
            list.add(mapOf(
                "type" to (prefs.getString("widget_type_$i", "") ?: ""),
                "glyph" to (prefs.getString("widget_glyph_$i", "") ?: prefs.getString("widget_type_$i", "") ?: ""),
                "label" to (prefs.getString("widget_type_$i", "")?.let { it.replaceFirstChar { c -> c.uppercase() } } ?: ""),
                "title" to (prefs.getString("widget_title_$i", "") ?: ""),
                "subtitle" to (prefs.getString("widget_subtitle_$i", "") ?: ""),
                "meta" to (prefs.getString("widget_meta_$i", "") ?: ""),
                "value" to (prefs.getString("widget_value_$i", "") ?: ""),
                "bearing" to (prefs.getString("widget_bearing_$i", "") ?: ""),
                "bearingLabel" to (prefs.getString("widget_bearingLabel_$i", "") ?: ""),
                "arrow" to (prefs.getString("widget_arrow_$i", "") ?: "")
            ))
        }
        cards = list
    }
}
