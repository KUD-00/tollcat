package com.zhechengqi.tollcat.settings

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlin.concurrent.thread

/**
 * 到点了。**读盘不在主线程**：`onReceive` 跑在主线程上，而这里要开一次 SQLite
 * 才知道上次刷新是什么时候；广播的时限是 10 秒，卡住就是一次 ANR。
 * `goAsync()` 让系统等我们，`finish()` 之前进程不会被回收。
 */
class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val pending = goAsync()
        val app = context.applicationContext
        thread(name = "tollcat-reminder") {
            try {
                ReminderAlarmScheduler.deliverAndReschedule(app)
            } finally {
                pending.finish()
            }
        }
    }
}
