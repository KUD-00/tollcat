package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.DashboardSnapshot

/**
 * 最急的那一件上横幅，其余进横滑小卡。排序：涨幅大的异常 → 快见底的余额 → 快用完的额度。
 * 没有一件够得上 [AttentionItem.isUrgent] 时没有横幅，全部是小卡。
 */
data class AttentionSummary(
    val urgent: AttentionItem?,
    val others: List<AttentionItem>,
) {
    val isEmpty: Boolean get() = urgent == null && others.isEmpty()
    val count: Int get() = others.size + if (urgent != null) 1 else 0

    companion object {
        fun from(dashboard: DashboardSnapshot, enabled: Collection<String>): AttentionSummary {
            // 取景框在共享层生效：回看过去的月份时这三组在 JNI 里就已经是空的。
            val anomalies = if (DashboardModules.ANOMALY in enabled) {
                dashboard.anomalies.sortedByDescending { it.changeRatio }.map { AttentionItem.Anomaly(it) }
            } else {
                emptyList()
            }
            val balances = if (DashboardModules.BALANCE in enabled) {
                dashboard.balanceAlerts.sortedBy { it.daysRemaining }.map { AttentionItem.Balance(it) }
            } else {
                emptyList()
            }
            val quotas = if (DashboardModules.QUOTA in enabled) {
                dashboard.freeQuota.sortedByDescending { it.usedPercent }.map { AttentionItem.Quota(it) }
            } else {
                emptyList()
            }
            val all: List<AttentionItem> = anomalies + balances + quotas
            val urgent = all.firstOrNull { it.isUrgent }
            return AttentionSummary(urgent = urgent, others = all.filter { it !== urgent })
        }
    }
}
