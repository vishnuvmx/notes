package com.notes.tacknotes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/**
 * 2x2 Home Screen Quick Actions App Widget ("Make Today's").
 * Surfaces 3 instant tactile capture actions:
 * 1. "Worth remembering...." -> Quick note / memory capture
 * 2. "Done with your works?" -> Task checklist / to-do note
 * 3. "Plan your day" -> Daily plan / priorities
 */
class TackQuickActionWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)

        // 1. Root / Header tap launches main Tack dashboard
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            context,
            100,
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_header, mainPendingIntent)

        // 2. "Worth remembering...." action
        val rememberingIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("tack://action/worth_remembering")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val rememberingPendingIntent = PendingIntent.getActivity(
            context,
            101,
            rememberingIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_worth_remembering, rememberingPendingIntent)

        // 3. "Done with your works?" action
        val doneWorksIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("tack://action/done_works")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val doneWorksPendingIntent = PendingIntent.getActivity(
            context,
            102,
            doneWorksIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_done_works, doneWorksPendingIntent)

        // 4. "Plan your day" action
        val planDayIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("tack://action/plan_day")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val planDayPendingIntent = PendingIntent.getActivity(
            context,
            103,
            planDayIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_plan_day, planDayPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
