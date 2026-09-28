package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.FreeQuotaRow

/** 「需要注意」里的一件事。三种来源共用一张卡、一条横幅，各自决定大数字和措辞。 */
sealed interface AttentionItem {
    val providerId: String
    val accountId: String
    val displayName: String

    /** 值得顶到横幅上的程度：涨了就算；余额撑不过一周；额度用到九成。 */
    val isUrgent: Boolean

    val target: String? get() = dashboardAttentionTarget(accountId, providerId)

    data class Anomaly(val row: AnomalyRow) : AttentionItem {
        override val providerId get() = row.providerId
        override val accountId get() = row.accountId
        override val displayName get() = row.displayName
        override val isUrgent get() = true
    }

    data class Balance(val row: BalanceAlertRow) : AttentionItem {
        override val providerId get() = row.providerId
        override val accountId get() = row.accountId
        override val displayName get() = row.displayName
        override val isUrgent get() = row.daysRemaining <= 7
    }

    data class Quota(val row: FreeQuotaRow) : AttentionItem {
        override val providerId get() = row.providerId
        override val accountId get() = row.accountId
        override val displayName get() = row.displayName
        override val isUrgent get() = row.usedPercent >= 90
    }
}
