package com.zhechengqi.tollcat.services

import androidx.annotation.StringRes
import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.AccountRow
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.TollCatSession

/**
 * 「计费模式」分的是右侧数字在说什么（从量 / 余额 / 月费 / 额度），
 * 「类别」分的是这家干什么活（AI 推理 / 托管 / 数据库……，标在服务目录里）。
 * 两者都是分组，别混成一个词。和 iOS `ServiceListSort` 一一对应。
 */
enum class ServiceListSort { Kind, Category, Price }

data class ServiceRowUi(
    val providerId: String,
    val displayName: String,
    val colorKey: String,
    val kind: String,
    val category: String,
    val amountText: String,
    val amountValue: Double,
    val subtitle: String,
    val usesSecondaryValue: Boolean,
    /** 列表 key。同厂商分行时是 accountId，否则是 providerId。 */
    val id: String = providerId,
    val accountId: String = "",
    val isStale: Boolean = false,
    val lastSuccessMillis: Long? = null,
    val isEnded: Boolean = false,
)

data class ServiceSectionUi(
    val id: String,
    val kind: String?,
    val category: String?,
    val rows: List<ServiceRowUi>,
)

private val kindOrder = listOf("usage", "planAndUsage", "prepaid", "subscription", "freeTier")

/** 超过一天没刷到新数，行上标陈旧。手动填的不算——那是你刚写的。 */
internal const val STALE_AFTER_MILLIS = 86_400_000L

@StringRes
fun categoryTitleRes(category: String): Int {
    return when (category) {
        "aiInference" -> R.string.category_ai_inference
        "gpuCompute" -> R.string.category_gpu_compute
        "hosting" -> R.string.category_hosting
        "database" -> R.string.category_database
        "search" -> R.string.category_search
        "networkEdge" -> R.string.category_network_edge
        "storage" -> R.string.category_storage
        "media" -> R.string.category_media
        "devTools" -> R.string.category_dev_tools
        "ciCd" -> R.string.category_ci_cd
        "observability" -> R.string.category_observability
        "authSecurity" -> R.string.category_auth_security
        "payments" -> R.string.category_payments
        "messaging" -> R.string.category_messaging
        "collaboration" -> R.string.category_collaboration
        "cms" -> R.string.category_cms
        "analytics" -> R.string.category_analytics
        "automation" -> R.string.category_automation
        "dataPipeline" -> R.string.category_data_pipeline
        else -> R.string.category_other
    }
}

@StringRes
fun kindTitleRes(kind: String): Int {
    return when (kind) {
        "prepaid" -> R.string.kind_prepaid_title
        "subscription" -> R.string.kind_subscription_title
        "freeTier" -> R.string.kind_freetier_title
        "planAndUsage" -> R.string.kind_plan_usage_title
        else -> R.string.kind_usage_title
    }
}

/**
 * @param categoryOrder 类别组序，来自目录载荷（权威是 iOS `ProviderCategory` 的声明序）。
 *   不按金额排——刷新一次就重排组序会让人找不着刚看过的那一行。清单里没有的类别排在后面。
 */
fun arrangeSections(
    rows: List<ServiceRowUi>,
    sort: ServiceListSort,
    categoryOrder: List<String> = emptyList(),
): List<ServiceSectionUi> {
    if (rows.isEmpty()) return emptyList()
    return when (sort) {
        ServiceListSort.Price -> listOf(
            ServiceSectionUi(
                id = "flat",
                kind = null,
                category = null,
                rows = rows.sortedWith(
                    compareByDescending<ServiceRowUi> { it.amountValue }
                        .thenBy { it.displayName.lowercase() },
                ),
            ),
        )
        ServiceListSort.Kind -> {
            val grouped = rows.groupBy { it.kind.ifBlank { "usage" } }
            val kinds = kindOrder.filter { it in grouped } + grouped.keys.filter { it !in kindOrder }
            kinds.map { kind ->
                ServiceSectionUi(id = kind, kind = kind, category = null, rows = grouped[kind].orEmpty())
            }
        }
        ServiceListSort.Category -> {
            val grouped = rows.groupBy { it.category.ifBlank { "other" } }
            val categories = categoryOrder.filter { it in grouped } +
                grouped.keys.filter { it !in categoryOrder }
            categories.map { category ->
                ServiceSectionUi(
                    id = category,
                    kind = null,
                    category = category,
                    rows = grouped[category].orEmpty(),
                )
            }
        }
    }
}

fun buildServiceRows(
    session: TollCatSession,
    scoped: DashboardSnapshot,
    nowMillis: Long,
    freeQuota: String,
    quotaUsed: (Int) -> String,
    typed: String,
    paidRefresh: String,
    noAmount: String,
    balance: (String) -> String,
    usageCount: (Int) -> String,
    kindTitle: (String) -> String,
    relative: (Long) -> String,
): List<ServiceRowUi> {
    val byAccount = scoped.composition.associateBy { it.accountId }
    val quotaByAccount = scoped.freeQuota.associateBy { it.accountId }
    return session.liveMemberships().flatMap { membership ->
        val provider = session.catalog.provider(membership.providerId) ?: return@flatMap emptyList()
        val accounts = session.liveAccounts(membership.providerId)
        val snapshots = session.snapshotsFor(membership.providerId)
        val split = accounts.size > 1 && accounts.any { !AccountExtras.nickname(it).isNullOrBlank() }
        if (split) {
            accounts.map { account ->
                val snapshot = latestFor(snapshots, account.accountId)
                accountRow(
                    provider = provider,
                    account = account,
                    snapshot = snapshot,
                    composed = byAccount[account.accountId],
                    quota = quotaByAccount[account.accountId],
                    nowMillis = nowMillis,
                    freeQuota = freeQuota,
                    quotaUsed = quotaUsed,
                    typed = typed,
                    paidRefresh = paidRefresh,
                    noAmount = noAmount,
                    balance = balance,
                    kindTitle = kindTitle,
                    relative = relative,
                    accountCount = 1,
                    usageCount = usageCount,
                )
            }
        } else {
            val ids = accounts.map { it.accountId }.toSet()
            val snapshot = accounts
                .mapNotNull { latestFor(snapshots, it.accountId) }
                .maxByOrNull { it.fetchedAtMillis }
                ?: session.latestSnapshot(membership.providerId)
            listOf(
                vendorRow(
                    provider = provider,
                    snapshot = snapshot,
                    accounts = accounts,
                    composed = compositionForAccounts(scoped.composition, ids),
                    quota = quotaForAccounts(scoped.freeQuota, ids),
                    nowMillis = nowMillis,
                    freeQuota = freeQuota,
                    quotaUsed = quotaUsed,
                    typed = typed,
                    paidRefresh = paidRefresh,
                    noAmount = noAmount,
                    balance = balance,
                    usageCount = usageCount,
                    kindTitle = kindTitle,
                    relative = relative,
                ),
            )
        }
    }
}

fun endedProviderRow(
    provider: CatalogProvider,
    endedAtMillis: Long?,
    ended: String,
    endedMonth: (String) -> String,
    yearMonth: (Long) -> String,
): ServiceRowUi {
    val caption = endedAtMillis?.let { endedMonth(yearMonth(it)) } ?: ended
    return ServiceRowUi(
        providerId = provider.id,
        displayName = provider.displayName,
        colorKey = provider.colorKey.ifBlank { provider.id },
        kind = provider.kind.ifBlank { "usage" },
        category = provider.category,
        amountText = "—",
        amountValue = 0.0,
        subtitle = caption,
        usesSecondaryValue = true,
        isEnded = true,
    )
}

private fun vendorRow(
    provider: CatalogProvider,
    snapshot: SnapshotRow?,
    accounts: List<AccountRow>,
    composed: List<CompositionRow>,
    quota: FreeQuotaRow?,
    nowMillis: Long,
    freeQuota: String,
    quotaUsed: (Int) -> String,
    typed: String,
    paidRefresh: String,
    noAmount: String,
    balance: (String) -> String,
    usageCount: (Int) -> String,
    kindTitle: (String) -> String,
    relative: (Long) -> String,
): ServiceRowUi {
    val lastSuccess = snapshot?.fetchedAtMillis?.takeIf { it > 0L }
    val isStale = isStale(snapshot, lastSuccess, nowMillis)
    return row(
        id = provider.id,
        providerId = provider.id,
        accountId = accounts.singleOrNull()?.accountId.orEmpty(),
        displayName = provider.displayName,
        provider = provider,
        snapshot = snapshot,
        accountCount = accounts.size,
        composedAmount = composedAmountText(composed),
        quotaPercent = quota?.usedPercent,
        lastSuccess = lastSuccess,
        isStale = isStale,
        freeQuota = freeQuota,
        quotaUsed = quotaUsed,
        typed = typed,
        paidRefresh = paidRefresh,
        noAmount = noAmount,
        balance = balance,
        usageCount = usageCount,
        kindTitle = kindTitle,
        relative = relative,
    )
}

private fun accountRow(
    provider: CatalogProvider,
    account: AccountRow,
    snapshot: SnapshotRow?,
    composed: CompositionRow?,
    quota: FreeQuotaRow?,
    nowMillis: Long,
    freeQuota: String,
    quotaUsed: (Int) -> String,
    typed: String,
    paidRefresh: String,
    noAmount: String,
    balance: (String) -> String,
    kindTitle: (String) -> String,
    relative: (Long) -> String,
    accountCount: Int,
    usageCount: (Int) -> String,
): ServiceRowUi {
    val lastSuccess = snapshot?.fetchedAtMillis?.takeIf { it > 0L }
    val isStale = isStale(snapshot, lastSuccess, nowMillis)
    return row(
        id = account.accountId,
        providerId = provider.id,
        accountId = account.accountId,
        displayName = AccountExtras.displayName(account, provider.displayName),
        provider = provider,
        snapshot = snapshot,
        accountCount = accountCount,
        composedAmount = composed?.amount?.takeIf { it.isNotBlank() && it != "—" },
        quotaPercent = quota?.usedPercent,
        lastSuccess = lastSuccess,
        isStale = isStale,
        freeQuota = freeQuota,
        quotaUsed = quotaUsed,
        typed = typed,
        paidRefresh = paidRefresh,
        noAmount = noAmount,
        balance = balance,
        usageCount = usageCount,
        kindTitle = kindTitle,
        relative = relative,
    )
}

private fun row(
    id: String,
    providerId: String,
    accountId: String,
    displayName: String,
    provider: CatalogProvider,
    snapshot: SnapshotRow?,
    accountCount: Int,
    composedAmount: String?,
    quotaPercent: Int?,
    lastSuccess: Long?,
    isStale: Boolean,
    freeQuota: String,
    quotaUsed: (Int) -> String,
    typed: String,
    paidRefresh: String,
    noAmount: String,
    balance: (String) -> String,
    usageCount: (Int) -> String,
    kindTitle: (String) -> String,
    relative: (Long) -> String,
): ServiceRowUi {
    val kind = snapshot?.kind?.ifBlank { null } ?: provider.kind.ifBlank { "usage" }
    val ratio = snapshot?.freeQuotaUsedRatio
    if (kind == "freeTier") {
        val percent = quotaPercent
            ?: ratio?.let { (it * 100).toInt() }
        if (percent != null) {
            return ServiceRowUi(
                providerId = providerId,
                displayName = displayName,
                colorKey = provider.colorKey.ifBlank { provider.id },
                kind = kind,
                category = provider.category,
                amountText = freeQuota,
                amountValue = percent / 100.0,
                subtitle = quotaUsed(percent),
                usesSecondaryValue = true,
                id = id,
                accountId = accountId,
                isStale = isStale,
                lastSuccessMillis = lastSuccess,
            )
        }
    }

    val amount = composedAmount?.takeIf { it.isNotBlank() && it != "—" }
    val amountValue = parseAmount(amount) ?: 0.0
    val subtitle = when {
        accountCount > 1 -> usageCount(accountCount)
        snapshot?.source == "manual" -> typed
        isStale && lastSuccess != null -> relative(lastSuccess)
        provider.costsMoneyToRefresh -> paidRefresh
        kind == "prepaid" && snapshot?.balanceUsd != null ->
            balance(formatMoney(snapshot.balanceUsd))
        amount == null -> noAmount
        else -> kindTitle(kind)
    }
    return ServiceRowUi(
        providerId = providerId,
        displayName = displayName,
        colorKey = provider.colorKey.ifBlank { provider.id },
        kind = kind,
        category = provider.category,
        amountText = amount ?: "—",
        amountValue = amountValue,
        subtitle = subtitle,
        usesSecondaryValue = amount == null,
        id = id,
        accountId = accountId,
        isStale = isStale,
        lastSuccessMillis = lastSuccess,
    )
}

private fun latestFor(snapshots: List<SnapshotRow>, accountId: String): SnapshotRow? =
    snapshots.filter { it.accountId == accountId }.maxByOrNull { it.fetchedAtMillis }

private fun isStale(snapshot: SnapshotRow?, lastSuccess: Long?, nowMillis: Long): Boolean {
    if (snapshot?.source == "manual") return false
    val at = lastSuccess ?: return false
    return nowMillis - at > STALE_AFTER_MILLIS
}

private fun quotaForAccounts(rows: List<FreeQuotaRow>, accountIds: Set<String>): FreeQuotaRow? {
    val matches = rows.filter { it.accountId in accountIds }
    return matches.maxByOrNull { it.usedPercent }
}

/** 金额格式化在共享层（币种符号、位数、千分位、显示币种折算都在 Swift 侧）。 */
internal fun formatMoney(raw: String): String = com.zhechengqi.tollcat.MoneyDisplay.formatUsd(raw)

internal fun parseAmount(raw: String?): Double? {
    raw ?: return null
    val numeric = raw.replace(Regex("[^0-9.\\-]"), "")
    return numeric.toDoubleOrNull()
}
