package com.zhechengqi.tollcat.settings

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.zhechengqi.tollcat.PreferencesStore

enum class ReminderAuthorization {
    NotDetermined,
    Denied,
    Authorized,
    ;

    val isAuthorized: Boolean get() = this == Authorized

    companion object {
        fun status(context: Context, preferences: PreferencesStore): ReminderAuthorization {
            if (canPostNotifications(context)) return Authorized
            return if (preferences.reminderOptInCompleted) Denied else NotDetermined
        }

        fun canPostNotifications(context: Context): Boolean {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return false
            if (!manager.areNotificationsEnabled()) return false
            if (Build.VERSION.SDK_INT >= 33) {
                val granted = context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                    PackageManager.PERMISSION_GRANTED
                if (!granted) return false
            }
            val channel = manager.getNotificationChannel(ReminderAlarmScheduler.CHANNEL_ID)
            return channel == null || channel.importance != NotificationManager.IMPORTANCE_NONE
        }
    }
}
