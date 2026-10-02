package com.notes.tacknotes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews

/**
 * 3x3 Responsive Home Screen Quick Actions App Widget ("Make Today's").
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
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

    private fun getCircularMascotBitmap(context: Context): Bitmap? {
        return try {
            val density = context.resources.displayMetrics.density
            val sizePx = (48 * density).toInt().coerceAtLeast(96)
            val output = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)

            val center = sizePx / 2f
            val outerRadius = sizePx / 2f

            // 1. Crisp white outer circle / ring
            val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
                style = Paint.Style.FILL
            }
            canvas.drawCircle(center, center, outerRadius, ringPaint)

            // 2. Mascot icon rendered and clipped into inner circle
            val strokePx = (2.5f * density).toInt().coerceAtLeast(4)
            val innerSize = sizePx - (strokePx * 2)
            val innerRadius = innerSize / 2f

            val drawable: Drawable? = try {
                context.packageManager.getApplicationIcon(context.packageName)
            } catch (e: Exception) {
                context.getDrawable(R.mipmap.ic_launcher)
            }

            if (drawable != null) {
                val iconBitmap = Bitmap.createBitmap(innerSize, innerSize, Bitmap.Config.ARGB_8888)
                val iconCanvas = Canvas(iconBitmap)
                drawable.setBounds(0, 0, innerSize, innerSize)
                drawable.draw(iconCanvas)

                val shader = BitmapShader(iconBitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
                val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.shader = shader
                }

                canvas.save()
                canvas.translate(strokePx.toFloat(), strokePx.toFloat())
                canvas.drawCircle(innerRadius, innerRadius, innerRadius, iconPaint)
                canvas.restore()
            }

            output
        } catch (e: Throwable) {
            null
        }
    }
}
