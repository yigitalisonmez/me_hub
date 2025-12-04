package com.example.me_hub

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.io.File

class MeHubWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Open App on Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // Load the rendered image
                val imagePath = widgetData.getString("me_hub_widget_image", null)
                if (imagePath != null) {
                    val imageFile = File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        setImageViewBitmap(R.id.widget_image, bitmap)
                        setViewVisibility(R.id.widget_image, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_image, View.GONE)
                    }
                } else {
                    setViewVisibility(R.id.widget_image, View.GONE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
