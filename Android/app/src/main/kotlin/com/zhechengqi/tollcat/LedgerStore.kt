package com.zhechengqi.tollcat

data class SnapshotRow(
    val providerId: String,
    val accountId: String,
    val kind: String,
    val source: String = "api",
    val currentSpendUsd: String? = null,
    val balanceUsd: String? = null,
    val committedMonthlyUsd: String? = null,
    val chargeDayOfMonth: Int? = null,
    val freeQuotaUsedRatio: Double? = null,
    /** {"毫秒": "usd 十进制串"} 的 JSON。有日粒度的家才有，原样过 JNI。 */
    val dailyUsdJson: String? = null,
    /** 换算注记 {"currency","amount","usdPerUnit","usd"}。丢了它换算账单会被当成精确值。 */
    val convertedJson: String? = null,
    /** 多钱包换算注记数组。原样过 JNI。 */
    val walletsJson: String? = null,
    /** 账单明细 JSON 数组。只展示，不进折算。 */
    val spendLinesJson: String? = null,
    val periodStartMillis: Long = 0,
    val periodEndMillis: Long = 0,
    val fetchedAtMillis: Long,
)

data class MembershipRow(
    val providerId: String,
    val sortIndex: Int,
)

data class AccountRow(
    val accountId: String,
    val providerId: String,
    val credentialReference: String,
    val sortIndex: Int,
    /**
     * 迁移包里这一端还不认识的接入字段（昵称、结束日、身份指纹、信箱投递 key…），
     * **原样存着，导出时原样吐回**。
     *
     * Android 还没有「昵称」和「结束接入」这两件事，但那不等于可以在换机的路上
     * 把别人的数据抹掉：iOS → Android → iOS 走一圈回来，结束过的接入不能复活成
     * 「在用」，指纹也不能不见。不认识 ≠ 可以丢。
     */
    val transferExtrasJson: String? = null,
)

data class SubscriptionRow(
    /**
     * 行的身份。**不能用名字**——同一个产品可以有两段：1–3 月订过 Pro，
     * 5 月又订回来，那是两笔独立的记录（中间 4 月不该有钱）。
     * 名字做主键就存不下第二段。
     */
    val id: String,
    val name: String,
    val amountUsd: String,
    val period: String,
    val anchorYear: Int,
    val anchorMonth: Int,
    val anchorDay: Int,
    /**
     * 退订那个月。三个都是 null = 还在付。
     *
     * 没有终点的话，退掉的订阅只能删，而历史月份是拿当前订阅表现算的——
     * 删一行等于把过去每个月里那笔钱一起抹掉。结束月当月仍全额计入。
     */
    val endYear: Int? = null,
    val endMonth: Int? = null,
    val endDay: Int? = null,
    val providerId: String? = null,
    val accountId: String? = null,
    val quantity: Int = 1,
) {
    /** 填过结束月。注意：填在未来的那种**还在付**，看 [hasEndedBy]。 */
    val hasEnd: Boolean get() = endYear != null && endMonth != null

    /** 到 [year]/[month] 那个月为止已经结束了。结束月当月仍然算数。 */
    fun hasEndedBy(year: Int, month: Int): Boolean {
        val endYear = endYear ?: return false
        val endMonth = endMonth ?: return false
        return endYear * 12 + endMonth < year * 12 + month
    }
}

/**
 * Android 不能用 SwiftData。Kotlin UI 只认这份协议；折算仍在 Swift。
 */
interface LedgerStore {
    fun insertSnapshot(row: SnapshotRow)
    fun replaceAccountSnapshots(accountId: String, row: SnapshotRow)
    fun snapshots(): List<SnapshotRow>

    /**
     * 最近一次刷新的时刻。**不要用 `snapshots().maxOf {}` 代替**——
     * 那会把整条快照日志读进内存，只为求一个数。
     */
    fun lastSnapshotFetchedAtMillis(): Long?
    fun upsertMembership(row: MembershipRow)
    fun memberships(): List<MembershipRow>
    fun deleteMembership(providerId: String)
    fun upsertAccount(row: AccountRow)
    fun accounts(): List<AccountRow>
    fun accounts(providerId: String): List<AccountRow>
    fun deleteAccount(accountId: String)
    fun upsertSubscription(row: SubscriptionRow)
    fun subscriptions(): List<SubscriptionRow>
    fun deleteSubscription(id: String)
    fun clearAll()
}
