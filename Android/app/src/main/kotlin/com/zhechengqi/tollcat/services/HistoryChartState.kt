package com.zhechengqi.tollcat.services

import org.json.JSONObject

/** 图上的一个读数：横轴是 bucket（当天/当月零点），纵轴是美元。 */
data class ChartPoint(val bucketMillis: Long, val amount: Double)

/**
 * 历史图视图状态，由 JNI `historyChartJson` 算好（分桶、做差、推断段、轴刻度
 * 单源在 MeterCore `HistoryChartMath`，和 iOS 同一份）。Kotlin 只渲染。
 */
sealed interface HistoryChartState {
    data class Spend(
        val points: List<ChartPoint>,
        val startMillis: Long,
        val endMillis: Long,
        val monthly: Boolean,
        val isIntervalSpend: Boolean,
        /** 横轴完整桶序列：缺读数的桶留空位，不补 0。 */
        val buckets: List<Long>,
        /** 纵轴刻度值（美元）。文字由渲染层过 formatUsd。 */
        val axisMarks: List<Double>,
    ) : HistoryChartState

    data class Balance(
        val points: List<ChartPoint>,
        val startMillis: Long,
        val endMillis: Long,
        val monthly: Boolean,
        /** 到下一个点的连线是推断段的那些起点 bucket。 */
        val inferredStarts: Set<Long>,
        val buckets: List<Long>,
        val axisMarks: List<Double>,
    ) : HistoryChartState

    data object None : HistoryChartState

    fun hasPlot(): Boolean = when (this) {
        is Spend -> points.isNotEmpty()
        is Balance -> points.isNotEmpty()
        None -> false
    }

    companion object {
        fun parse(json: String): HistoryChartState {
            val root = JSONObject(json)
            return when (root.optString("kind")) {
                "spend" -> Spend(
                    points = points(root),
                    startMillis = root.optLong("startMillis"),
                    endMillis = root.optLong("endMillis"),
                    monthly = root.optBoolean("monthly"),
                    isIntervalSpend = root.optBoolean("isIntervalSpend"),
                    buckets = longs(root, "buckets"),
                    axisMarks = doubles(root, "axisMarks"),
                )
                "balance" -> Balance(
                    points = points(root),
                    startMillis = root.optLong("startMillis"),
                    endMillis = root.optLong("endMillis"),
                    monthly = root.optBoolean("monthly"),
                    inferredStarts = longs(root, "inferredStarts").toSet(),
                    buckets = longs(root, "buckets"),
                    axisMarks = doubles(root, "axisMarks"),
                )
                else -> None
            }
        }

        private fun points(root: JSONObject): List<ChartPoint> {
            val array = root.optJSONArray("points") ?: return emptyList()
            return (0 until array.length()).map { index ->
                val item = array.getJSONObject(index)
                ChartPoint(item.optLong("bucket"), item.optDouble("amount"))
            }
        }

        private fun longs(root: JSONObject, key: String): List<Long> {
            val array = root.optJSONArray(key) ?: return emptyList()
            return (0 until array.length()).map { array.optLong(it) }
        }

        private fun doubles(root: JSONObject, key: String): List<Double> {
            val array = root.optJSONArray(key) ?: return emptyList()
            return (0 until array.length()).map { array.optDouble(it) }
        }
    }
}
