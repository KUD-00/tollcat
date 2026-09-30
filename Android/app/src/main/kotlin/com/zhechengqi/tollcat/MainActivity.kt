package com.zhechengqi.tollcat

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.view.ViewTreeObserver
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.annotation.RequiresApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.platform.LocalContext
import com.zhechengqi.tollcat.developer.DebugLaunch
import com.zhechengqi.tollcat.developer.isDebuggable
import com.zhechengqi.tollcat.launch.LaunchRevealOverlay
import com.zhechengqi.tollcat.launch.LaunchSwatchRegistry
import com.zhechengqi.tollcat.launch.LocalLaunchSwatches
import com.zhechengqi.tollcat.settings.ReminderAlarmScheduler
import com.zhechengqi.tollcat.ui.OnboardingPreferences

class MainActivity : ComponentActivity() {
    private val viewModel: TollCatViewModel by viewModels()

    /** 冷启动过渡还在演。转屏重建时不再演。 */
    private var launchActive by mutableStateOf(false)
    /** 系统启动画面交给 App 了（没有系统启动画面时一开始就是）。 */
    private var launchHandedOver by mutableStateOf(false)
    /** 系统启动图标在窗口里的位置：过渡从这里放大铺满。 */
    private var launchIcon by mutableStateOf<Rect?>(null)
    private val launchRegistry = LaunchSwatchRegistry()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WidgetSnapshot.install(applicationContext)
        UsageAnalytics.start(this)
        enableEdgeToEdge()
        if (isDebuggable(this)) {
            DebugLaunch.apply(this, viewModel.session, intent)
        }
        applyIncomingIntent(intent)
        launchActive = savedInstanceState == null && !intent.getBooleanExtra(EXTRA_SKIP_LAUNCH_REVEAL, false)
        if (launchActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            handOverSplash()
        } else {
            launchHandedOver = true
        }
        setContent {
            TollCatTheme {
                CompositionLocalProvider(LocalLaunchSwatches provides launchRegistry.takeIf { launchActive }) {
                    Box(Modifier.fillMaxSize()) {
                        TollCatApp(viewModel.session)
                        if (launchActive) {
                            LaunchReveal()
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun LaunchReveal() {
        val session = viewModel.session
        val context = LocalContext.current
        val onboarding = remember { OnboardingPreferences(context) }
        DisposableEffect(onboarding) { onDispose { onboarding.dispose() } }
        LaunchRevealOverlay(
            iconBounds = launchIcon,
            handedOver = launchHandedOver,
            targets = session.dashboard.launchTargets,
            registry = launchRegistry,
            showsDashboard = {
                onboarding.completed && session.tab == AppTab.Dashboard && !session.dashboard.empty
            },
            onFinished = { launchActive = false },
        )
    }

    /**
     * 系统启动画面先别撤：第一份仪表盘算好再交接（最多等 [SPLASH_HOLD_MS]），过渡落点才有数。
     * 交接时记下系统图标的位置，等覆盖层按这个位置画出一帧再撤系统画面，中间不闪空底。
     */
    @RequiresApi(Build.VERSION_CODES.S)
    private fun handOverSplash() {
        val content = findViewById<View>(android.R.id.content)
        val started = SystemClock.uptimeMillis()
        content.viewTreeObserver.addOnPreDrawListener(object : ViewTreeObserver.OnPreDrawListener {
            override fun onPreDraw(): Boolean {
                val ready = viewModel.session.hasComputedDashboard ||
                    SystemClock.uptimeMillis() - started > SPLASH_HOLD_MS
                if (ready) {
                    content.viewTreeObserver.removeOnPreDrawListener(this)
                    // 系统等 App 太久会自己撤掉启动画面，不再调下面的交接回调；那样覆盖层就从全屏口袋直接起步，
                    // 不能一直盖在 App 上。
                    content.postDelayed({ launchHandedOver = true }, HANDOVER_FALLBACK_MS)
                }
                return ready
            }
        })
        splashScreen.setOnExitAnimationListener { splash ->
            splash.iconView?.let { icon ->
                val at = IntArray(2)
                icon.getLocationInWindow(at)
                launchIcon = Rect(
                    at[0].toFloat(),
                    at[1].toFloat(),
                    (at[0] + icon.width).toFloat(),
                    (at[1] + icon.height).toFloat(),
                )
            }
            launchHandedOver = true
            content.postOnAnimation { content.postOnAnimation { splash.remove() } }
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
        const val SPLASH_HOLD_MS = 1200L
        const val HANDOVER_FALLBACK_MS = 1500L
        /** 冷启动过渡不演，直接进 App。截图和 UI 冒烟用（iOS 是 `-skip-launch-reveal`）。 */
        const val EXTRA_SKIP_LAUNCH_REVEAL = "skip_launch_reveal"
    }
}
