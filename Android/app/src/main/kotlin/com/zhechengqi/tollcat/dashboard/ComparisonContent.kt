package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.DashboardSnapshot

/**
 * 对比瓷砖的视图状态。百分比文本、语气和带月名的 caption 由共享层给出
 * （和 iOS `ComparisonBuilder` 同一份口径），两根柱的数也是；这里只把它们缩成相对高度。
 */
data class ComparisonContent(
    val percentText: String,
    val caption: String,
    val spokenLabel: String,
    val currentWeight: Float,
    val previousWeight: Float,
    val currentLabel: String,
    val previousLabel: String,
    val tone: Tone,
) {
    enum class Tone { Up, Down, Flat, Unknown }

    companion object {
        fun from(
            dashboard: DashboardSnapshot,
            currentLabel: String,
            previousLabel: String,
            unavailableCaption: String,
        ): ComparisonContent? {
            if (dashboard.formattedComparison == null && dashboard.changePercent == null) return null
            val percentText = dashboard.comparisonPercentText ?: "—"
            val caption = dashboard.comparisonCaption ?: unavailableCaption
            val tone = when (dashboard.comparisonTone) {
                "up" -> Tone.Up
                "down" -> Tone.Down
                "flat" -> Tone.Flat
                else -> if (dashboard.formattedComparison == null) Tone.Unknown else Tone.Flat
            }
            // 两根柱按共享层给的两个数画（和 iOS `CompactComparisonBars` 同一对）。
            // 以前从取整后的百分比倒推：上月是 0 时百分比为空，两根柱就画成一样高。
            val current = (dashboard.comparisonCurrentValue ?: 0.0).toFloat().coerceAtLeast(0f)
            val previous = (dashboard.comparisonPreviousValue ?: 0.0).toFloat().coerceAtLeast(0f)
            val max = maxOf(current, previous, 0.01f)
            return ComparisonContent(
                percentText = percentText,
                caption = caption,
                spokenLabel = "$percentText. $caption",
                currentWeight = current / max,
                previousWeight = previous / max,
                currentLabel = currentLabel,
                previousLabel = previousLabel,
                tone = tone,
            )
        }
    }
}
