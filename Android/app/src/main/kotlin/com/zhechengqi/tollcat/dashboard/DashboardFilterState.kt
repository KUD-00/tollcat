package com.zhechengqi.tollcat.dashboard

import org.json.JSONArray
import org.json.JSONObject

/**
 * 仪表盘取景框，和 iOS `MeterCore.DashboardFilter` 同一个模型。
 * 时间维三个标量过桥：`periodKind` / `monthsBack` / `monthCount`。
 */
data class DashboardFilterState(
    val periodKind: String = KIND_MONTHS,
    /** 窗口里最新的那个月。0 = 本月。 */
    val monthsBack: Int = 0,
    /** `.months` 时窗口长度。今年至今 / 全期间存 1，意图在 kind。 */
    val monthCount: Int = 1,
    val includesSubscriptions: Boolean = false,
    val excludedAccountIds: Set<String> = emptySet(),
) {
    val isCurrentMonth: Boolean
        get() = periodKind == KIND_MONTHS && monthsBack == 0 && monthCount == 1

    /** 和 iOS 一样：订阅口径不算「正在筛」。 */
    val isActive: Boolean
        get() = !isCurrentMonth || excludedAccountIds.isNotEmpty()

    fun toggleAccount(id: String): DashboardFilterState {
        val next = excludedAccountIds.toMutableSet()
        if (!next.add(id)) next.remove(id)
        return copy(excludedAccountIds = next)
    }

    fun includeAllAccounts(): DashboardFilterState = copy(excludedAccountIds = emptySet())

    fun currentMonth(): DashboardFilterState =
        copy(periodKind = KIND_MONTHS, monthsBack = 0, monthCount = 1)

    fun lastMonths(count: Int): DashboardFilterState =
        copy(periodKind = KIND_MONTHS, monthsBack = 0, monthCount = count.coerceIn(1, MAX_MONTHS_BACK + 1))

    fun singleMonth(back: Int): DashboardFilterState =
        copy(periodKind = KIND_MONTHS, monthsBack = back.coerceIn(0, MAX_MONTHS_BACK), monthCount = 1)

    fun yearToDate(): DashboardFilterState =
        copy(periodKind = KIND_YEAR_TO_DATE, monthsBack = 0, monthCount = 1)

    fun allTime(): DashboardFilterState =
        copy(periodKind = KIND_ALL_TIME, monthsBack = 0, monthCount = 1)

    fun toJson(): String = JSONObject().apply {
        put("periodKind", periodKind)
        put("monthsBack", monthsBack)
        put("monthCount", monthCount)
        put("includesSubscriptions", includesSubscriptions)
        put("excludedAccounts", JSONArray(excludedAccountIds.toList()))
    }.toString()

    companion object {
        const val MAX_MONTHS_BACK = 11
        const val KIND_MONTHS = "months"
        const val KIND_YEAR_TO_DATE = "yearToDate"
        const val KIND_ALL_TIME = "allTime"

        fun fromJson(raw: String?): DashboardFilterState {
            if (raw.isNullOrBlank()) return DashboardFilterState()
            return runCatching {
                val root = JSONObject(raw)
                val excluded = root.optJSONArray("excludedAccounts") ?: JSONArray()
                val ids = (0 until excluded.length()).map { excluded.optString(it) }.filter { it.isNotBlank() }
                DashboardFilterState(
                    periodKind = root.optString("periodKind", KIND_MONTHS).ifBlank { KIND_MONTHS },
                    monthsBack = root.optInt("monthsBack", 0).coerceIn(0, MAX_MONTHS_BACK),
                    monthCount = root.optInt("monthCount", 1).coerceAtLeast(1),
                    includesSubscriptions = root.optBoolean("includesSubscriptions", false),
                    excludedAccountIds = ids.toSet(),
                )
            }.getOrElse { DashboardFilterState() }
        }
    }
}
