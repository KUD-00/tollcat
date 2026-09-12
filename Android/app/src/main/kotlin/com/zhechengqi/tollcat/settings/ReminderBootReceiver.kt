package com.zhechengqi.tollcat.settings

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 闹钟在开机和改时区后会丢，按偏好重排。 */
class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            -> ReminderAlarmScheduler.sync(context)
        }
    }
}
