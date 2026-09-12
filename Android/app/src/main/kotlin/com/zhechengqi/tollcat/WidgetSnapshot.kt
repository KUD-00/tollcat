package com.zhechengqi.tollcat

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.updateAll
import com.zhechengqi.tollcat.widget.TollCatWidget
import com.zhechengqi.tollcat.widget.WidgetComposition
import java.io.File
import java.util.Calendar
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

/**
 * 主 App 每次重算仪表之后落下的只读快照。小组件只读这份文件，
 * 不加载 JNI、不打账单接口——和 iOS Widget 不链 Providers 同一条线。
 */
object WidgetSnapshot {
    private const val FILE = "widget-snapshot.json"
    private const val TAG = "TollCatWidget"

    @Volatile
    private var appContext: Context? = null

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    data class Payload(
        val empty: Boolean,
        val monthTitle: String,
        val periodCaption: String,
        val formattedTotal: String,
        val formattedProjected: String,
        val allowsProjection: Boolean,
        val lastRefreshAtMillis: Long?,
        val asOfMonth: String,
        val catMood: String,
        val composition: List<WidgetComposition.Slice>,
    ) {
        fun speaksCurrentMonth(nowMillis: Long = System.currentTimeMillis()): Boolean {
            if (asOfMonth.isBlank()) return true
            return asOfMonth == monthKey(nowMillis)
        }
    }

    val vacant = Payload(
        empty = true,
        monthTitle = "",
        periodCaption = "",
        formattedTotal = "",
        formattedProjected = "",
        allowsProjection = true,
        lastRefreshAtMillis = null,
        asOfMonth = "",
        catMood = "sleeping",
        composition = emptyList(),
    )

    /** 设计稿数字，给小组件预览 / 图库用。不是运行时取数。 */
    val designSpec = Payload(
        empty = false,
        monthTitle = "八月",
        periodCaption = "八月",
        formattedTotal = "$47.20",
        formattedProjected = "$87.70",
        allowsProjection = true,
        lastRefreshAtMillis = null,
        asOfMonth = "",
        catMood = "shocked",
        composition = listOf(
            WidgetComposition.Slice("aws", "AWS", "$21.40", 45, 0.4534f),
            WidgetComposition.Slice("cloudflare", "Cloudflare", "$11.05", 23, 0.2341f),
            WidgetComposition.Slice("openai", "OpenAI", "$7.62", 16, 0.1614f),
            WidgetComposition.Slice("github", "GitHub", "$4.00", 9, 0.0847f),
            WidgetComposition.Slice("neon", "Neon", "$3.13", 7, 0.0663f),
        ),
    )

    fun install(context: Context) {
        appContext = context.applicationContext
    }

    fun write(
        dashboard: DashboardSnapshot,
        lastRefreshAtMillis: Long?,
        nowMillis: Long = System.currentTimeMillis(),
        otherLabel: String = "其他",
    ) {
        val ctx = appContext ?: return
        // 折算是在主线程回来的，但**编码和落盘不能在主线程**：每次 recompute
        // 一次同步写盘，正是刚修完的亮屏卡顿那条路。
        val payload = from(dashboard, lastRefreshAtMillis, nowMillis, otherLabel)
        scope.launch {
            runCatching {
                file(ctx).writeText(encode(payload), Charsets.UTF_8)
            }.onFailure { error ->
                Log.w(TAG, "write", error)
            }
            runCatching { TollCatWidget().updateAll(ctx) }
                .onFailure { error -> Log.w(TAG, "updateAll", error) }
        }
    }

    fun read(context: Context): Payload {
        val target = file(context.applicationContext)
        if (!target.exists()) return vacant
        return runCatching { decode(target.readText(Charsets.UTF_8)) }
            .getOrElse { vacant }
    }

    fun from(
        dashboard: DashboardSnapshot,
        lastRefreshAtMillis: Long?,
        nowMillis: Long,
        otherLabel: String,
    ): Payload {
        if (dashboard.empty) {
            return vacant.copy(
                monthTitle = dashboard.monthTitle,
                periodCaption = dashboard.periodCaption.ifBlank { dashboard.monthTitle },
                asOfMonth = monthKey(nowMillis),
                catMood = dashboard.catMood.ifBlank { "sleeping" },
            )
        }
        return Payload(
            empty = false,
            monthTitle = dashboard.monthTitle,
            periodCaption = dashboard.periodCaption.ifBlank { dashboard.monthTitle },
            formattedTotal = dashboard.formattedTotal,
            formattedProjected = dashboard.formattedProjected,
            allowsProjection = dashboard.allowsProjection,
            lastRefreshAtMillis = lastRefreshAtMillis,
            asOfMonth = monthKey(nowMillis),
            catMood = dashboard.catMood.ifBlank { "normal" },
            composition = WidgetComposition.vendorSlices(dashboard.composition, otherLabel),
        )
    }

    fun monthKey(millis: Long): String {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = millis
        return "%04d-%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
        )
    }

    private fun file(context: Context): File = File(context.filesDir, FILE)

    private fun encode(payload: Payload): String = JSONObject().apply {
        put("empty", payload.empty)
        put("monthTitle", payload.monthTitle)
        put("periodCaption", payload.periodCaption)
        put("formattedTotal", payload.formattedTotal)
        put("formattedProjected", payload.formattedProjected)
        put("allowsProjection", payload.allowsProjection)
        payload.lastRefreshAtMillis?.let { put("lastRefreshAtMillis", it) }
        put("asOfMonth", payload.asOfMonth)
        put("catMood", payload.catMood)
        put(
            "composition",
            JSONArray().apply {
                for (slice in payload.composition) {
                    put(
                        JSONObject().apply {
                            put("providerId", slice.providerId)
                            put("displayName", slice.displayName)
                            put("amount", slice.amount)
                            put("percent", slice.percent)
                            put("fraction", slice.fraction.toDouble())
                            put("isOther", slice.isOther)
                        },
                    )
                }
            },
        )
    }.toString()

    private fun decode(raw: String): Payload {
        val root = JSONObject(raw)
        if (root.optBoolean("empty", true)) {
            return vacant.copy(
                monthTitle = root.optString("monthTitle"),
                periodCaption = root.optString("periodCaption"),
                asOfMonth = root.optString("asOfMonth"),
                catMood = root.optString("catMood").ifBlank { "sleeping" },
            )
        }
        val composition = root.optJSONArray("composition") ?: JSONArray()
        val slices = buildList {
            for (i in 0 until composition.length()) {
                val item = composition.optJSONObject(i) ?: continue
                add(
                    WidgetComposition.Slice(
                        providerId = item.optString("providerId"),
                        displayName = item.optString("displayName"),
                        amount = item.optString("amount"),
                        percent = item.optInt("percent"),
                        fraction = item.optDouble("fraction").toFloat(),
                        isOther = item.optBoolean("isOther"),
                    ),
                )
            }
        }
        val last = if (root.has("lastRefreshAtMillis")) root.optLong("lastRefreshAtMillis") else null
        return Payload(
            empty = false,
            monthTitle = root.optString("monthTitle"),
            periodCaption = root.optString("periodCaption"),
            formattedTotal = root.optString("formattedTotal"),
            formattedProjected = root.optString("formattedProjected"),
            allowsProjection = root.optBoolean("allowsProjection", true),
            lastRefreshAtMillis = last?.takeIf { it > 0L },
            asOfMonth = root.optString("asOfMonth"),
            catMood = root.optString("catMood").ifBlank { "normal" },
            composition = slices,
        )
    }
}
