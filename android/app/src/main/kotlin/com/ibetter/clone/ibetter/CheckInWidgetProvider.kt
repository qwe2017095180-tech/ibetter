package com.ibetter.clone.ibetter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class CheckInWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateSingleWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "qingsong_widget"
        private const val KEY_TITLE = "title"
        private const val KEY_LINES = "lines"
        private const val KEY_DONE = "doneCount"
        private const val KEY_TOTAL = "totalCount"

        fun saveAndUpdate(
            context: Context,
            title: String,
            lines: List<String>,
            doneCount: Int,
            totalCount: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_TITLE, title)
                .putString(KEY_LINES, lines.joinToString("\n"))
                .putInt(KEY_DONE, doneCount)
                .putInt(KEY_TOTAL, totalCount)
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, CheckInWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                for (id in ids) {
                    updateSingleWidget(context, manager, id)
                }
            }
        }

        internal fun updateSingleWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString(KEY_TITLE, "轻松打卡") ?: "轻松打卡"
            val rawLines = prefs.getString(KEY_LINES, "") ?: ""
            val doneCount = prefs.getInt(KEY_DONE, 0)
            val totalCount = prefs.getInt(KEY_TOTAL, 0)

            val views = RemoteViews(context.packageName, R.layout.widget_checkin)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_badge, "$doneCount/$totalCount")
            views.setTextViewText(
                R.id.widget_lines,
                if (rawLines.isBlank()) "打开轻松打卡开始今日习惯记录" else rawLines,
            )

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
