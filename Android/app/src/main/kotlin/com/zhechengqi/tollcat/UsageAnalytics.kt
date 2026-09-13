package com.zhechengqi.tollcat

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import com.zhechengqi.tollcat.developer.isDebuggable
import com.zhechengqi.tollcat.settings.appVersionCaption
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

/**
 * 匿名页面计数。连续停在同一页不计第二次。失败丢掉这一批，宁可少计。
 *
 * 不带账号、广告标识、设备指纹、账单、凭据、厂商名。
 * debuggable 包不发：开发点来点去会把生产表打脏。
 */
object UsageAnalytics {
    private const val PREFS = "usage_analytics"
    private const val LAST_VISIT_DAY = "last_visit_day"
    private const val DEBOUNCE_MS = 2_000L
    private const val SCREENS_MAX = 32
    private const val COUNT_MAX = 1000

    @Volatile private var impl: Impl? = null

    fun start(context: Context) {
        if (isDebuggable(context)) return
        if (impl != null) return
        impl = Impl(context.applicationContext)
    }

    fun record(screen: String) {
        impl?.record(screen)
    }

    fun flush() {
        impl?.flushNow()
    }

    private class Impl(private val context: Context) {
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
        private val mutex = Mutex()
        private val counts = linkedMapOf<String, Int>()
        private var lastScreen: String? = null
        private var debounce: Job? = null
        private var inFlight = false
        private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        private val appVersion = appVersionCaption(context)

        fun record(screen: String) {
            if (screen !in UsageScreens.all) return
            scope.launch {
                mutex.withLock {
                    if (lastScreen == screen) return@withLock
                    lastScreen = screen
                    val next = (counts[screen] ?: 0) + 1
                    counts[screen] = minOf(next, COUNT_MAX)
                    debounce?.cancel()
                    debounce = scope.launch {
                        delay(DEBOUNCE_MS)
                        sendLockedCaller()
                    }
                }
            }
        }

        fun flushNow() {
            scope.launch { sendLockedCaller() }
        }

        private suspend fun sendLockedCaller() {
            val payload = mutex.withLock {
                if (inFlight) return
                val built = buildPayloadLocked() ?: return
                inFlight = true
                built
            }
            val ok = post(payload)
            mutex.withLock {
                inFlight = false
                if (ok && payload.optBoolean("newVisit")) {
                    prefs.edit().putString(LAST_VISIT_DAY, utcDay()).apply()
                }
                if (counts.isNotEmpty()) {
                    debounce?.cancel()
                    debounce = scope.launch {
                        delay(DEBOUNCE_MS)
                        sendLockedCaller()
                    }
                }
            }
        }

        private fun buildPayloadLocked(): JSONObject? {
            val day = utcDay()
            val newVisit = prefs.getString(LAST_VISIT_DAY, null) != day
            if (!newVisit && counts.isEmpty()) return null
            val screens = JSONArray()
            counts.entries.take(SCREENS_MAX).forEach { (id, n) ->
                screens.put(JSONObject().put("id", id).put("n", n))
            }
            counts.clear()
            return JSONObject()
                .put("platform", "android")
                .put("appVersion", appVersion.take(40))
                .put("newVisit", newVisit)
                .put("screens", screens)
        }

        private fun post(body: JSONObject): Boolean {
            return try {
                val json = JniGate.blocking { MeterCoreNative.postUsageJson(body.toString()) }
                JSONObject(json).optBoolean("ok")
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun utcDay(): String {
        return DateTimeFormatter.ISO_LOCAL_DATE.format(Instant.now().atZone(ZoneOffset.UTC))
    }
}

@Composable
fun TrackScreen(screen: String?) {
    DisposableEffect(screen) {
        if (screen != null) UsageAnalytics.record(screen)
        onDispose { }
    }
}
