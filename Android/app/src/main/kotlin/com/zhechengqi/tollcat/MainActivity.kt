package com.zhechengqi.tollcat

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import com.zhechengqi.tollcat.developer.DebugLaunch
import com.zhechengqi.tollcat.developer.isDebuggable
import com.zhechengqi.tollcat.settings.ReminderAlarmScheduler

class MainActivity : ComponentActivity() {
    private val viewModel: TollCatViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WidgetSnapshot.install(applicationContext)
        UsageAnalytics.start(this)
        enableEdgeToEdge()
        if (isDebuggable(this)) {
            DebugLaunch.apply(this, viewModel.session, intent)
        }
        applyIncomingIntent(intent)
        setContent {
            TollCatTheme {
                TollCatApp(viewModel.session)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        applyIncomingIntent(intent)
    }

    override fun onStop() {
        UsageAnalytics.flush()
        super.onStop()
    }

    /**
     * 启动器 Activity 天然导出，任何 app 都能带任意 data 显式启动它。
     * 深链只认 `tollcat://dashboard|settings`；提醒的 extra 只导到写死的设置页，
     * 不转交外来 URI；导入只认 content/file 且文件名是 .tollcat 的。
     */
    private fun applyIncomingIntent(intent: Intent?) {
        if (intent == null) return
        val extra = intent.getBooleanExtra(ReminderAlarmScheduler.EXTRA_OPEN_SETTINGS, false)
        val data = intent.data
        when {
            data != null && data.scheme == "tollcat" && data.host == "dashboard" ->
                viewModel.session.openDashboard()
            data != null && data.scheme == "tollcat" && data.host == "settings" ->
                viewModel.session.openSettingsDeepLink(data)
            extra ->
                viewModel.session.openSettingsDeepLink(Uri.parse(ReminderAlarmScheduler.SETTINGS_URI))
            data != null && data.scheme in IMPORT_SCHEMES &&
                data.lastPathSegment?.endsWith(".tollcat") == true -> {
                viewModel.session.openSettingsDeepLink(Uri.parse("tollcat://settings/import"))
            }
        }
        if (extra) {
            intent.removeExtra(ReminderAlarmScheduler.EXTRA_OPEN_SETTINGS)
        }
    }

    private companion object {
        val IMPORT_SCHEMES = setOf("content", "file")
    }
}
