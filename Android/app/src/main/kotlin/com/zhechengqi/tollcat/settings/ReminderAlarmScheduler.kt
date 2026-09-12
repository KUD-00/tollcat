package com.zhechengqi.tollcat.settings

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.zhechengqi.tollcat.LedgerStore
import com.zhechengqi.tollcat.MainActivity
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SqliteLedgerStore

/**
 * 本地定时提醒。只用 AlarmManager，不接 FCM、不做后台取数。
 *
 * 不申请 SCHEDULE_EXACT_ALARM：`setAndAllowWhileIdle` 在 API 31+ 也不要精确闹钟权限。
 * 响一次再排下一次，开机 / 时区变化由 [ReminderBootReceiver] 重排。
 */
object ReminderAlarmScheduler {
    const val CHANNEL_ID = "com.zhechengqi.tollcat.reminders"
    const val EXTRA_OPEN_SETTINGS = "com.zhechengqi.tollcat.extra.OPEN_SETTINGS"
    const val SETTINGS_URI = "tollcat://settings"

    private const val ALARM_REQUEST = 4101
    private const val NOTIFICATION_ID = 4101
    private const val CONTENT_REQUEST = 4102

    fun sync(context: Context, nowMillis: Long = System.currentTimeMillis()) {
        val app = context.applicationContext
        val preferences = PreferencesStore(app)
        if (!preferences.reminderEnabled || !ReminderAuthorization.canPostNotifications(app)) {
            cancel(app)
            return
        }
        schedule(app, preferences, nowMillis)
    }

    fun cancel(context: Context) {
        val app = context.applicationContext
        val alarm = app.getSystemService(AlarmManager::class.java) ?: return
        alarm.cancel(alarmPending(app))
        app.getSystemService(NotificationManager::class.java)
            ?.cancel(NOTIFICATION_ID)
    }

    fun deliverAndReschedule(context: Context) {
        val app = context.applicationContext
        val preferences = PreferencesStore(app)
        if (!preferences.reminderEnabled || !ReminderAuthorization.canPostNotifications(app)) {
            cancel(app)
            return
        }
        showNotification(app, SqliteLedgerStore(app))
        // 当前这一格已经响过；+1s 避免 nextDate 把同一分钟再捡回来。
        schedule(app, preferences, System.currentTimeMillis() + 1_000L)
    }

    private fun schedule(
        context: Context,
        preferences: PreferencesStore,
        nowMillis: Long,
    ) {
        ensureChannel(context)
        val triggerAt = ReminderNextFire.nextMillis(
            frequency = preferences.reminderFrequency,
            hour = preferences.reminderHour,
            minute = preferences.reminderMinute,
            weekday = preferences.reminderWeekday,
            dayOfMonth = preferences.reminderDayOfMonth,
            nowMillis = nowMillis,
        ) ?: run {
            cancel(context)
            return
        }
        val alarm = context.getSystemService(AlarmManager::class.java) ?: return
        alarm.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAt,
            alarmPending(context),
        )
    }

    private fun showNotification(context: Context, ledger: LedgerStore) {
        ensureChannel(context)
        val now = System.currentTimeMillis()
        // 只问「最近一次刷新是什么时候」。以前是把整条快照日志读进内存再求 max。
        val lastRefresh = runCatching { ledger.lastSnapshotFetchedAtMillis() }.getOrNull()
        val title = ReminderNotificationCopy.title(context)
        val body = ReminderNotificationCopy.body(
            context = context,
            lastRefreshAtMillis = lastRefresh,
            nowMillis = now,
        )
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setColor(context.getColor(R.color.ic_launcher_background))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(contentPending(context))
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .build()
        context.getSystemService(NotificationManager::class.java)
            ?.notify(NOTIFICATION_ID, notification)
    }

    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.settings_reminder),
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        channel.description = context.getString(R.string.settings_reminder_note)
        manager.createNotificationChannel(channel)
    }

    private fun alarmPending(context: Context): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun contentPending(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            data = Uri.parse(SETTINGS_URI)
            putExtra(EXTRA_OPEN_SETTINGS, true)
        }
        return PendingIntent.getActivity(
            context,
            CONTENT_REQUEST,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
