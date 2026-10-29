package com.orbit.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import android.net.Uri

// ORBIT 1.4 — Swipeable 4×2 widget, StackView, well presented flat 1px, tabular, honest zero
// Swipe left/right via StackView, tap card → open ORBIT, refresh 15m Workmanager + 60s foreground
class OrbitWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.orbit_widget_layout)

            // Read widget data saved via HomeWidget.saveWidgetData
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val count = prefs.getInt("widget_count", 0)
            val updatedAt = prefs.getString("orbit_widget_data", null)?.let {
                try { org.json.JSONObject(it).optString("updatedAt", "") } catch(_: Exception) { "" }
            } ?: ""

            // StackView is swipeable — set remote adapter
            val serviceIntent = Intent(context, OrbitWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_stack, serviceIntent)
            views.setEmptyView(R.id.widget_stack, R.id.widget_empty)

            // Tap card → launch app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val pending = PendingIntent.getActivity(context, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setPendingIntentTemplate(R.id.widget_stack, pending)

            // Refresh button → request update via HomeWidgetPlugin
            val refreshIntent = Intent(context, OrbitWidgetProvider::class.java).apply { action = "ORBIT_REFRESH" }
            val refreshPending = PendingIntent.getBroadcast(context, 1, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshPending)

            // Footer: count + updated
            views.setTextViewText(R.id.widget_footer, "${count} cards • Swipe • $updatedAt")

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_stack)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "ORBIT_REFRESH") {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(android.content.ComponentName(context, OrbitWidgetProvider::class.java))
            onUpdate(context, mgr, ids)
        }
    }
}
