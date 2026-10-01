package com.zhechengqi.tollcat.developer

import android.content.Intent
import com.zhechengqi.tollcat.JniGate
import com.zhechengqi.tollcat.MainActivity
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.AppTab
import com.zhechengqi.tollcat.settings.AppearancePreference
import com.zhechengqi.tollcat.ui.AppearanceMode
import com.zhechengqi.tollcat.ui.AppearancePreferences
import com.zhechengqi.tollcat.ui.OnboardingPreferences

/**
 * 落地页 / 验收截图用的调试启动参数。只在 debuggable 包里生效。
 * 对齐 iOS 的 `-seed-demo` / `-skip-onboarding` / `-appearance=` / `-clock-preset=design`。
 */
object DebugLaunch {
    const val SEED_DEMO = "seed_demo"
    const val SKIP_ONBOARDING = "skip_onboarding"
    const val HIDE_CAT = "hide_cat"
    const val APPEARANCE = "appearance"
    const val CLOCK_PRESET = "clock_preset"
    const val START_ON_SERVICES = "start_on_services"
    /** 落地页截图不要「当前是演示数据」那行；iOS 的截图本来就没有。 */
    const val HIDE_DEMO_BANNER = "hide_demo_banner"
    /** 直接打开这家的接入向导（空库截向导那一屏用）。对齐 iOS 的 `-open-setup=`。 */
    const val OPEN_SETUP = "open_setup"

    /** MeterClock.design：2026-08-16 12:00 UTC。 */
    const val DESIGN_CLOCK_MILLIS = 1_786_881_600_000L

    fun apply(activity: MainActivity, session: TollCatSession, intent: Intent) {
        if (!isDebuggable(activity)) return

        val skipOnboarding = boolExtra(intent, SKIP_ONBOARDING) || boolExtra(intent, SEED_DEMO)
        if (skipOnboarding) {
            OnboardingPreferences(activity).complete()
        }

        if (boolExtra(intent, HIDE_CAT)) {
            session.preferences.hidesCat = true
        }

        intent.getStringExtra(APPEARANCE)?.let { raw ->
            val appearance = AppearancePreference.normalize(raw)
            session.preferences.appearance = appearance
            session.preferences.applyAppearance(activity)
            AppearancePreferences(activity).setMode(AppearanceMode.fromStorage(appearance))
        }

        when (intent.getStringExtra(CLOCK_PRESET)) {
            "design" -> session.applyClockOverride(DESIGN_CLOCK_MILLIS)
        }

        if (boolExtra(intent, SEED_DEMO)) {
            // 加载 .so、解压资源、setResourceRoot 都排在 JniGate 那条单线程队列里，
            // 这里还在主线程 onCreate。直接调会抢在库就位之前，种子静默失败（ok=false），
            // 仪表盘就是空态。排进同一队列，FIFO 保证它在 bootstrap 之后跑。
            JniGate.run { session.seedDemo() }
        }

        if (boolExtra(intent, HIDE_DEMO_BANNER)) {
            session.isDemoBannerDismissed = true
        }
        if (boolExtra(intent, START_ON_SERVICES)) {
            session.tab = AppTab.Services
        }
        intent.getStringExtra(OPEN_SETUP)?.takeIf { it.isNotBlank() }?.let { providerId ->
            session.openSetup(providerId, accountId = null)
        }
    }

    private fun boolExtra(intent: Intent, key: String): Boolean {
        if (!intent.hasExtra(key)) return false
        return intent.getBooleanExtra(key, false) || intent.getStringExtra(key) == "true"
    }
}
