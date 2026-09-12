package com.zhechengqi.tollcat.services

import com.zhechengqi.tollcat.SnapshotRow

/**
 * 账单明细在这一端只是**一段 JSON**：分组、占比、折扣、用量位数全在共享层
 * （`MeterCore/SpendGrouping` + `MeterFormat/QuantityFormat`），由桥算好送回来。
 *
 * 这里曾经有一份手译的 builder（连数量格式的位数阈值都抄了，rounding 还不一样），
 * 而桥上本来就在送 `lines`。
 */
object SpendLines {
    /**
     * 最新一条带明细的快照。**不合并历次**——把八十次刷新加起来会把 $10 加成 $800。
     */
    fun latestJson(snapshots: List<SnapshotRow>): String? {
        return snapshots
            .filter {
                val raw = it.spendLinesJson
                !raw.isNullOrBlank() && raw != "[]" && raw != "null"
            }
            .maxByOrNull { it.fetchedAtMillis }
            ?.spendLinesJson
    }
}
