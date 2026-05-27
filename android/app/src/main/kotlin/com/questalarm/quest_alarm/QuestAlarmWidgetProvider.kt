package com.questalarm.quest_alarm

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuestAlarmWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val status = widgetData.getString("qa_widget_status", "neutral")
                val route = if (status == "sad") {
                    Uri.parse("questalarm://battle-summary")
                } else {
                    Uri.parse("questalarm://home")
                }
                val openAppIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, route)
                setOnClickPendingIntent(R.id.widget_image, openAppIntent)

                val imagePath = widgetData.getString("qa_widget_image", null)
                if (!imagePath.isNullOrEmpty()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_image, bitmap)
                        setViewVisibility(R.id.widget_image, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_image, View.INVISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.widget_image, View.INVISIBLE)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
