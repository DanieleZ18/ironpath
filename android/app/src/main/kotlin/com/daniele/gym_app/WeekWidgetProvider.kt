package com.daniele.gym_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * Home-screen widget: this week's workouts. The Flutter side (WidgetBridge)
 * writes the week's state after every save; this provider only draws it.
 * Labels arrive already localised.
 */
class WeekWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val all = widgetData.all
    fun int(key: String) = (all[key] as? Number)?.toInt() ?: 0
    fun long(key: String) = (all[key] as? Number)?.toLong() ?: 0L
    fun str(key: String, fallback: String) = (all[key] as? String) ?: fallback

    // a week that ended since the app last ran shows as a fresh week
    val stale = long("updated_at") < startOfWeek()
    val done = if (stale) 0 else int("week_done")
    val total = int("week_total")
    val days = if (stale) "0000000" else str("week_days", "0000000").padEnd(7, '0')
    val labels = str("day_labels", "Mon|Tue|Wed|Thu|Fri|Sat|Sun").split("|")
    val next = if (stale) "" else str("next_title", "")
    val today = todayIndex()

    // the sessions left this week are pencilled onto the days still to come
    val planned = BooleanArray(7)
    var remaining = (total - done).coerceIn(0, 7)
    for (i in today until 7) {
      if (remaining == 0) break
      if (days[i] == '1') continue
      planned[i] = true
      remaining--
    }

    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.week_widget)
      views.setTextViewText(R.id.week_label, str("label_week", "This week"))
      views.setTextViewText(R.id.week_progress, if (total > 0) "$done / $total" else "$done")
      for (i in 0 until 7) {
        val drawable = when {
          days[i] == '1' -> R.drawable.dot_done
          i == today -> R.drawable.dot_today
          planned[i] -> R.drawable.dot_planned
          else -> R.drawable.dot_off
        }
        views.setImageViewResource(DOTS[i], drawable)
        views.setTextViewText(LABELS[i], labels.getOrElse(i) { "" })
      }
      if (next.isEmpty()) {
        views.setViewVisibility(R.id.next_title, View.GONE)
      } else {
        views.setViewVisibility(R.id.next_title, View.VISIBLE)
        views.setTextViewText(R.id.next_title, "${str("label_next", "Up next")} · $next")
      }
      views.setOnClickPendingIntent(
          R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  /** Monday 00:00 of the current week, local time, in epoch millis. */
  private fun startOfWeek(): Long {
    val c = Calendar.getInstance()
    c.add(Calendar.DAY_OF_YEAR, -todayIndex())
    c.set(Calendar.HOUR_OF_DAY, 0)
    c.set(Calendar.MINUTE, 0)
    c.set(Calendar.SECOND, 0)
    c.set(Calendar.MILLISECOND, 0)
    return c.timeInMillis
  }

  /** 0 = Monday … 6 = Sunday. */
  private fun todayIndex(): Int =
      (Calendar.getInstance().get(Calendar.DAY_OF_WEEK) + 5) % 7

  companion object {
    private val DOTS =
        intArrayOf(R.id.dot1, R.id.dot2, R.id.dot3, R.id.dot4, R.id.dot5, R.id.dot6, R.id.dot7)
    private val LABELS =
        intArrayOf(R.id.lab1, R.id.lab2, R.id.lab3, R.id.lab4, R.id.lab5, R.id.lab6, R.id.lab7)
  }
}
