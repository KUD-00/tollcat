package com.zhechengqi.tollcat

import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/** JNI 载荷 schema 版本，和 Swift `JNISchema.version` 同步改。 */
internal const val EXPECTED_JNI_SCHEMA = 7

internal fun warnOnSchemaDrift(root: JSONObject, what: String) {
    val version = root.optInt("jniSchema", EXPECTED_JNI_SCHEMA)
    if (version != EXPECTED_JNI_SCHEMA) {
        Log.w("TollCat", "$what jniSchema=$version expected=$EXPECTED_JNI_SCHEMA：两侧解码器脱节")
    }
}

data class CatalogProvider(
    val id: String,
    val displayName: String,
    val kind: String,
    /** 这家干什么活（aiInference / hosting / database……），和 iOS `ProviderCategory` 同一组值。 */
    val category: String,
    /** 所属品类里的市占档，1…4，和 iOS `ProviderTier` 同一组值。 */
    val tier: Int,
    /** 为什么标这个档。给人读的，不进翻译表。 */
    val tierReason: String,
    val colorKey: String,
    val costsMoneyToRefresh: Boolean,
    val supportsInbox: Boolean,
    val hasLiveFetch: Boolean,
    val summary: String,
    /** 搜索别名（中英混排），来自编译期 descriptor，不参与展示。 */
    val searchKeywords: List<String>,
    /** available / pendingVerification / declined，和 iOS `ProviderAccessStatus` 同一组值。 */
    val accessStatus: String,
    /** 不接入的理由。空表示不是 declined。 */
    val declineReason: String,
    val supportsDailyGranularity: Boolean,
    val historyLookbackMonths: Int,
    /**
     * 两次成功刷新之间的最短间隔（秒）。0 表示不另限。
     * 和 iOS `ProviderDescriptor.minimumRefreshInterval` 同一口径。
     */
    val minimumRefreshInterval: Int = 0,
    /** 官网账单页。编译进 .so，不来自远程目录。 */
    val billingURL: String,
    /** 直达创建 token 的那一页。 */
    val credentialSetupURL: String,
    val fields: List<CatalogField>,
) {
    /** 和 iOS `RefreshCadence.shouldFetch` 同一口径。 */
    fun shouldFetch(lastFetchedAtMillis: Long?, nowMillis: Long): Boolean {
        if (minimumRefreshInterval <= 0) return true
        if (lastFetchedAtMillis == null || lastFetchedAtMillis <= 0L) return true
        if (lastFetchedAtMillis > nowMillis) return true
        return nowMillis - lastFetchedAtMillis >= minimumRefreshInterval.toLong() * 1000L
    }
}

data class CatalogField(
    val key: String,
    val label: String,
    val isSecret: Boolean = false,
    val hint: String = "",
    /** catalogJson 的 fields 没有这一格；setupGuideJson 的 parts.fields 才有。 */
    val validation: CatalogFieldValidation? = null,
) {
    fun errorMessage(raw: String, emptyMessage: String): String? {
        val value = raw.trim()
        if (value.isEmpty()) return emptyMessage
        return validation?.errorMessage(value)
    }
}

/** 长度 / 前缀 / 允许字符。失败文案来自 catalog，不要另写「格式不正确」。 */
data class CatalogFieldValidation(
    val exactLength: Int? = null,
    val minLength: Int? = null,
    val prefix: String? = null,
    val allowedCharacters: String? = null,
    val message: String = "",
) {
    fun errorMessage(value: String): String? {
        if (exactLength != null && value.length != exactLength) return message.ifBlank { null }
        if (minLength != null && value.length < minLength) return message.ifBlank { null }
        if (prefix != null && !value.startsWith(prefix)) return message.ifBlank { null }
        if (allowedCharacters != null && value.any { it !in allowedCharacters }) {
            return message.ifBlank { null }
        }
        return null
    }
}

data class Catalog(
    val providers: List<CatalogProvider>,
    val currencies: List<String>,
    /** 服务页「按类别」的组序，权威在 iOS `ProviderCategory` 的声明序，这里不另抄一份。 */
    val categoryOrder: List<String> = emptyList(),
) {
    fun provider(id: String): CatalogProvider? = providers.firstOrNull { it.id == id }

    companion object {
        fun parse(json: String): Catalog {
            val root = JSONObject(json)
            warnOnSchemaDrift(root, "catalog")
            val providers = root.optJSONArray("providers").orEmpty().mapObject { item ->
                CatalogProvider(
                    id = item.getString("id"),
                    displayName = item.getString("displayName"),
                    kind = item.optString("kind"),
                    category = item.optString("category", "other"),
                    tier = item.optInt("tier", 3),
                    tierReason = item.optString("tierReason"),
                    colorKey = item.optString("colorKey", item.getString("id")),
                    costsMoneyToRefresh = item.optBoolean("costsMoneyToRefresh"),
                    supportsInbox = item.optBoolean("supportsInbox"),
                    hasLiveFetch = item.optBoolean("hasLiveFetch"),
                    summary = item.optString("summary"),
                    searchKeywords = item.optJSONArray("searchKeywords").orEmpty().mapString(),
                    accessStatus = item.optString("accessStatus", "available"),
                    declineReason = item.optString("declineReason"),
                    supportsDailyGranularity = item.optBoolean("supportsDailyGranularity"),
                    historyLookbackMonths = item.optInt("historyLookbackMonths"),
                    minimumRefreshInterval = item.optInt("minimumRefreshInterval"),
                    billingURL = item.optString("billingURL"),
                    credentialSetupURL = item.optString("credentialSetupURL"),
                    fields = item.optJSONArray("fields").orEmpty().mapObject { field ->
                        CatalogField(
                            key = field.getString("key"),
                            label = field.optString("label", field.getString("key")),
                            isSecret = field.optBoolean("isSecret"),
                            hint = field.optString("hint"),
                        )
                    },
                )
            }
            val currencies = root.optJSONArray("currencies").orEmpty().mapString()
                .ifEmpty { listOf("USD") }
            val categoryOrder = root.optJSONArray("categoryOrder").orEmpty().mapString()
            return Catalog(providers, currencies, categoryOrder)
        }
    }
}

data class CompositionRow(
    val providerId: String,
    val displayName: String,
    val colorKey: String,
    val amount: String,
    val percent: Int,
    val fraction: Float,
    /** 出键粒度是账号：同一家两份账号是两段。合成「其他」和画廊夹具留空。 */
    val accountId: String = "",
)

data class UpcomingRow(
    val name: String,
    val providerId: String,
    val colorKey: String,
    val amount: String,
    val dateCaption: String,
    val accountId: String = "",
)

data class FreeQuotaRow(
    val providerId: String,
    val displayName: String,
    val colorKey: String,
    val usedPercent: Int,
    val caption: String,
    val accountId: String = "",
)

data class AnomalyRow(
    val providerId: String,
    val displayName: String,
    val signedPercent: String,
    val caption: String,
    val changeRatio: Double,
    val accountId: String = "",
)

data class BalanceAlertRow(
    val providerId: String,
    val displayName: String,
    val balance: String,
    val daysRemaining: Int,
    val caption: String,
    val accountId: String = "",
)

data class TrendRow(
    val month: String,
    val amount: String,
    val fraction: Float,
)

data class HeatmapMonthRow(
    val monthStartMillis: Long,
    val title: String,
    val monthTitle: String,
    val values: List<Double?>,
    val leadingEmptyDays: Int,
    val totalText: String,
    val peakCaption: String,
    val dayLabels: List<String>,
)

data class CategorySliceRow(
    val category: String,
    val amountText: String,
    val percent: Int,
    val fraction: Float,
    val colorKey: String,
    val memberNames: List<String>,
)

data class BudgetRow(
    val spentText: String,
    val budgetText: String,
    val remainingText: String,
    val overText: String,
    val fraction: Float,
    /** 「用了 N%」里的 N。共享层算好——两端各自取整会差一个百分点。 */
    val usedPercent: Int,
    val isOver: Boolean,
    val isClose: Boolean,
)

data class SuperlativeRow(
    val kind: String,
    val displayName: String,
    val value: String,
    val colorKey: String,
    val accountId: String,
    val providerId: String,
)

data class PinnedServiceRow(
    val accountId: String,
    val providerId: String,
    val displayName: String,
    val colorKey: String,
    val amountText: String,
    val spark: List<Float>,
    /** 较上月同期。这家还不能比时为 null。 */
    val changeText: String? = null,
    val changeIsUp: Boolean = false,
)

data class SubscriptionModuleItem(
    val id: String,
    val name: String,
    val amountText: String,
    val periodCaption: String,
    val accountId: String,
    val providerId: String,
    val colorKey: String,
    val quantity: Int,
)

/**
 * 「固定订阅」整块。回答的是「我现在每月固定要出多少钱」，所以合计和下一笔
 * 跟条目一起来——桥算，这里只画。**不截断**：列不下是版式的事。
 */
data class SubscriptionsModuleRow(
    val monthlyTotalText: String,
    val countCaption: String,
    val nextChargeCaption: String?,
    val items: List<SubscriptionModuleItem>,
)

data class ComparisonItemRow(
    val accountId: String,
    val providerId: String,
    val displayName: String,
    val colorKey: String,
    val currentText: String,
    val previousText: String?,
    val signedPercent: String?,
    val changeRatio: Double?,
    val isComparable: Boolean,
)

data class DashboardSnapshot(
    val empty: Boolean,
    /** 取景框月份的标题（zh「八月」/ en "August"），由共享层按 locale 给出。 */
    val monthTitle: String,
    /** 多月区间时的起讫（「三月–五月」）。单月与 [monthTitle] 相同。 */
    val periodCaption: String = "",
    /** 只有当月才有「预计月底」；回看过去月份时隐藏。 */
    val allowsProjection: Boolean,
    val formattedTotal: String,
    val formattedVariable: String,
    val formattedProjected: String,
    val confidence: String,
    /** 估的那几**份账号**（UUID）——不压成 ProviderID：一家的其中一份是估的 ≠ 这家全是估的。 */
    val estimatedAccountIds: List<String>,
    val subscriptionFormatted: String?,
    val subscriptionCaption: String? = null,
    val staleCaption: String? = null,
    val currencyNote: String?,
    val composition: List<CompositionRow>,
    val upcoming: List<UpcomingRow>,
    val freeQuota: List<FreeQuotaRow>,
    val formattedComparison: String?,
    val changePercent: Int?,
    /** 共享层选好的猫气泡句（已本地化）。 */
    val catSpeech: String,
    /** 对比视图状态（已本地化的 +N% / 语气 / 带月名的 caption）。 */
    val comparisonPercentText: String?,
    val comparisonCaption: String?,
    val comparisonTone: String?,
    val anomalies: List<AnomalyRow>,
    val balanceAlerts: List<BalanceAlertRow>,
    val trend: List<TrendRow>,
    val catMood: String,
    val heatmap: List<HeatmapMonthRow> = emptyList(),
    val categories: List<CategorySliceRow> = emptyList(),
    val budget: BudgetRow? = null,
    val superlatives: List<SuperlativeRow> = emptyList(),
    val pinnedServices: List<PinnedServiceRow> = emptyList(),
    val subscriptions: SubscriptionsModuleRow? = null,
    val comparisonItems: List<ComparisonItemRow> = emptyList(),
) {
    companion object {
        val vacant = DashboardSnapshot(
            empty = true,
            monthTitle = "",
            allowsProjection = true,
            formattedTotal = "—",
            formattedVariable = "—",
            formattedProjected = "—",
            confidence = "exact",
            estimatedAccountIds = emptyList(),
            subscriptionFormatted = null,
            currencyNote = null,
            composition = emptyList(),
            upcoming = emptyList(),
            freeQuota = emptyList(),
            formattedComparison = null,
            changePercent = null,
            catSpeech = "",
            comparisonPercentText = null,
            comparisonCaption = null,
            comparisonTone = null,
            anomalies = emptyList(),
            balanceAlerts = emptyList(),
            trend = emptyList(),
            catMood = "sleeping",
        )

        fun parse(json: String): DashboardSnapshot {
            val root = JSONObject(json)
            warnOnSchemaDrift(root, "dashboard")
            if (root.optBoolean("empty", false)) {
                return vacant.copy(
                    monthTitle = root.optString("monthTitle"),
                    catSpeech = root.optString("catSpeech"),
                    catMood = root.optString("catMood").ifBlank { "sleeping" },
                )
            }
            return DashboardSnapshot(
                empty = false,
                monthTitle = root.optString("monthTitle"),
                periodCaption = root.optString("periodCaption").ifBlank { root.optString("monthTitle") },
                allowsProjection = root.optBoolean("allowsProjection", true),
                formattedTotal = root.optString("formattedTotal", "—"),
                formattedVariable = root.optString("formattedVariable", "—"),
                formattedProjected = root.optString("formattedProjected", "—"),
                confidence = root.optString("confidence", "exact"),
                estimatedAccountIds = root.optJSONArray("estimatedAccountIDs").orEmpty().mapString(),
                subscriptionFormatted = root.optString("subscriptionFormatted").ifBlank { null },
                subscriptionCaption = root.optString("subscriptionCaption").ifBlank { null },
                staleCaption = root.optString("staleCaption").ifBlank { null },
                currencyNote = root.optString("currencyNote").ifBlank { null },
                composition = root.optJSONArray("composition").orEmpty().mapObject { item ->
                    CompositionRow(
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        displayName = item.optString("displayName"),
                        colorKey = item.optString("colorKey"),
                        amount = item.optString("amount"),
                        percent = item.optInt("percent"),
                        fraction = item.optDouble("fraction").toFloat(),
                    )
                },
                formattedComparison = root.optString("formattedComparison").ifBlank { null },
                changePercent = if (root.has("changePercent")) root.optInt("changePercent") else null,
                catSpeech = root.optString("catSpeech"),
                comparisonPercentText = root.optString("comparisonPercentText").ifBlank { null },
                comparisonCaption = root.optString("comparisonCaption").ifBlank { null },
                comparisonTone = root.optString("comparisonTone").ifBlank { null },
                upcoming = root.optJSONArray("upcoming").orEmpty().mapObject { item ->
                    UpcomingRow(
                        name = item.optString("name"),
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        colorKey = item.optString("colorKey"),
                        amount = item.optString("amount"),
                        dateCaption = item.optString("dateCaption"),
                    )
                },
                freeQuota = root.optJSONArray("freeQuota").orEmpty().mapObject { item ->
                    FreeQuotaRow(
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        displayName = item.optString("displayName"),
                        colorKey = item.optString("colorKey"),
                        usedPercent = item.optInt("usedPercent"),
                        caption = item.optString("caption"),
                    )
                },
                anomalies = root.optJSONArray("anomalies").orEmpty().mapObject { item ->
                    AnomalyRow(
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        displayName = item.optString("displayName"),
                        signedPercent = item.optString("signedPercent"),
                        caption = item.optString("caption"),
                        changeRatio = item.optDouble("changeRatio"),
                    )
                },
                balanceAlerts = root.optJSONArray("balanceAlerts").orEmpty().mapObject { item ->
                    BalanceAlertRow(
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        displayName = item.optString("displayName"),
                        balance = item.optString("balance"),
                        daysRemaining = item.optInt("daysRemaining"),
                        caption = item.optString("caption"),
                    )
                },
                trend = root.optJSONArray("trend").orEmpty().mapObject { item ->
                    TrendRow(
                        month = item.optString("month"),
                        amount = item.optString("amount"),
                        fraction = item.optDouble("fraction").toFloat(),
                    )
                },
                catMood = root.optString("catMood").ifBlank { "normal" },
                heatmap = root.optJSONArray("heatmap").orEmpty().mapObject { item ->
                    val values = item.optJSONArray("values") ?: JSONArray()
                    val labels = item.optJSONArray("dayLabels") ?: JSONArray()
                    HeatmapMonthRow(
                        monthStartMillis = item.optLong("monthStartMillis"),
                        title = item.optString("title"),
                        monthTitle = item.optString("monthTitle"),
                        values = (0 until values.length()).map {
                            if (values.isNull(it)) null else values.optDouble(it)
                        },
                        leadingEmptyDays = item.optInt("leadingEmptyDays"),
                        totalText = item.optString("totalText"),
                        peakCaption = item.optString("peakCaption"),
                        dayLabels = (0 until labels.length()).map { labels.optString(it) },
                    )
                },
                categories = root.optJSONArray("categories").orEmpty().mapObject { item ->
                    val names = item.optJSONArray("memberNames") ?: JSONArray()
                    CategorySliceRow(
                        category = item.optString("category"),
                        amountText = item.optString("amountText"),
                        percent = item.optInt("percent"),
                        fraction = item.optDouble("fraction").toFloat(),
                        colorKey = item.optString("colorKey"),
                        memberNames = (0 until names.length()).map { names.optString(it) },
                    )
                },
                budget = root.optJSONObject("budget")?.let { item ->
                    BudgetRow(
                        spentText = item.optString("spentText"),
                        budgetText = item.optString("budgetText"),
                        remainingText = item.optString("remainingText"),
                        overText = item.optString("overText"),
                        fraction = item.optDouble("fraction").toFloat(),
                        usedPercent = item.optInt("usedPercent"),
                        isOver = item.optBoolean("isOver"),
                        isClose = item.optBoolean("isClose"),
                    )
                },
                superlatives = root.optJSONArray("superlatives").orEmpty().mapObject { item ->
                    SuperlativeRow(
                        kind = item.optString("kind"),
                        displayName = item.optString("displayName"),
                        value = item.optString("value"),
                        colorKey = item.optString("colorKey"),
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                    )
                },
                pinnedServices = root.optJSONArray("pinnedServices").orEmpty().mapObject { item ->
                    val spark = item.optJSONArray("spark") ?: JSONArray()
                    PinnedServiceRow(
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        displayName = item.optString("displayName"),
                        colorKey = item.optString("colorKey"),
                        amountText = item.optString("amountText"),
                        spark = (0 until spark.length()).map { spark.optDouble(it).toFloat() },
                        changeText = item.optString("changeText").ifBlank { null },
                        changeIsUp = item.optBoolean("changeIsUp"),
                    )
                },
                subscriptions = root.optJSONObject("subscriptionsModule")?.let { module ->
                    SubscriptionsModuleRow(
                        monthlyTotalText = module.optString("monthlyTotalText"),
                        countCaption = module.optString("countCaption"),
                        nextChargeCaption = module.optString("nextChargeCaption").ifBlank { null },
                        items = module.optJSONArray("items").orEmpty().mapObject { item ->
                            SubscriptionModuleItem(
                                id = item.optString("id"),
                                name = item.optString("name"),
                                amountText = item.optString("amountText"),
                                periodCaption = item.optString("periodCaption"),
                                accountId = item.optString("accountID"),
                                providerId = item.optString("providerID"),
                                colorKey = item.optString("colorKey"),
                                quantity = item.optInt("quantity", 1),
                            )
                        },
                    )
                },
                comparisonItems = root.optJSONArray("comparisonItems").orEmpty().mapObject { item ->
                    ComparisonItemRow(
                        accountId = item.optString("accountID"),
                        providerId = item.optString("providerID"),
                        displayName = item.optString("displayName"),
                        colorKey = item.optString("colorKey"),
                        currentText = item.optString("currentText"),
                        previousText = item.optString("previousText").ifBlank { null },
                        signedPercent = item.optString("signedPercent").ifBlank { null },
                        changeRatio = if (item.has("changeRatio")) item.optDouble("changeRatio") else null,
                        isComparable = item.optBoolean("isComparable"),
                    )
                },
            )
        }
    }
}

data class FetchResult(
    val ok: Boolean,
    val snapshot: SnapshotRow?,
    val spend: String?,
    val error: String?,
    /** JSON 里的 status / httpStatus，或从 error dump 里抠出的数字。没有就 null，不要在 Kotlin 里猜。 */
    val httpStatus: Int? = null,
) {
    companion object {
        fun parse(json: String, accountId: String): FetchResult {
            val root = JSONObject(json)
            val ok = root.optBoolean("ok")
            val snapshot = if (ok) {
                SnapshotRow(
                    providerId = root.optString("providerID"),
                    accountId = root.optString("accountID").ifBlank { accountId },
                    kind = root.optString("kind", "usage"),
                    source = root.optString("source", "api"),
                    currentSpendUsd = root.optString("currentSpendUSD").ifBlank { null },
                    balanceUsd = root.optString("balanceUSD").ifBlank { null },
                    committedMonthlyUsd = root.optString("committedMonthlyUSD").ifBlank { null },
                    chargeDayOfMonth = if (root.has("chargeDayOfMonth")) root.optInt("chargeDayOfMonth") else null,
                    freeQuotaUsedRatio = if (root.has("freeQuotaUsedRatio")) root.optDouble("freeQuotaUsedRatio") else null,
                    dailyUsdJson = root.optJSONObject("dailyUSD")?.toString(),
                    convertedJson = root.optJSONObject("converted")?.toString(),
                    walletsJson = root.optJSONArray("wallets")?.toString(),
                    spendLinesJson = root.optJSONArray("lines")?.toString(),
                    periodStartMillis = root.optLong("periodStart"),
                    periodEndMillis = root.optLong("periodEnd"),
                    fetchedAtMillis = root.optLong("fetchedAt"),
                )
            } else {
                null
            }
            val error = root.optString("error").ifBlank { null }
            return FetchResult(
                ok = ok,
                snapshot = snapshot?.copy(accountId = accountId),
                spend = root.optString("spend").ifBlank { null },
                error = error,
                httpStatus = root.optionalInt("httpStatus")
                    ?: root.optionalInt("status")
                    ?: httpStatusFromErrorDump(error),
            )
        }
    }
}

/** 和 iOS `Snapshot.hasBillableMetrics` 同一张 kind → 字段表。空读数不能当成 $0。 */
val SnapshotRow.hasBillableMetrics: Boolean
    get() = when (kind) {
        "prepaid" -> !balanceUsd.isNullOrBlank()
        "subscription" -> !committedMonthlyUsd.isNullOrBlank()
        "freeTier" -> freeQuotaUsedRatio != null
        "planAndUsage" ->
            !committedMonthlyUsd.isNullOrBlank() ||
                !dailyUsdJson.isNullOrBlank() ||
                !currentSpendUsd.isNullOrBlank()
        else -> !dailyUsdJson.isNullOrBlank() || !currentSpendUsd.isNullOrBlank()
    }

/** JNI 失败目前把 `String(describing: ProviderError)` 塞进 error。有数字才认，不在这里发明状态码。 */
internal fun httpStatusFromErrorDump(error: String?): Int? {
    if (error.isNullOrBlank()) return null
    optionalHttpStatus.dump.find(error)?.groupValues?.getOrNull(1)?.toIntOrNull()?.let { return it }
    optionalHttpStatus.bare.find(error)?.groupValues?.getOrNull(1)?.toIntOrNull()?.let { return it }
    return null
}

internal fun isNetworkErrorDump(error: String?): Boolean {
    if (error.isNullOrBlank()) return false
    return error.contains("networkFailure") || error.contains("networkUnavailable")
}

private object optionalHttpStatus {
    val dump = Regex("""httpStatus:\s*Optional\((\d+)\)""")
    val bare = Regex("""httpStatus:\s*(\d+)""")
}

private fun parseGuideField(field: JSONObject): CatalogField {
    val validationJson = field.optJSONObject("validation")
    val validation = validationJson?.let { json ->
        CatalogFieldValidation(
            exactLength = json.optionalInt("exactLength"),
            minLength = json.optionalInt("minLength"),
            prefix = json.optString("prefix").ifBlank { null },
            allowedCharacters = json.optString("allowedCharacters").ifBlank { null },
            message = json.optString("message"),
        )
    }
    return CatalogField(
        key = field.getString("key"),
        label = field.optString("label", field.getString("key")),
        isSecret = field.optBoolean("isSecret"),
        hint = field.optString("hint"),
        validation = validation,
    )
}

private fun JSONObject.optionalInt(key: String): Int? {
    if (!has(key) || isNull(key)) return null
    return optInt(key)
}

internal fun JSONArray?.orEmpty(): JSONArray = this ?: JSONArray()

private fun JSONArray.mapString(): List<String> {
    return (0 until length()).map { optString(it) }.filter { it.isNotBlank() }
}

internal fun <T> JSONArray.mapObject(transform: (JSONObject) -> T): List<T> {
    return (0 until length()).map { transform(getJSONObject(it)) }
}

/** 向导整篇教程（catalog 的 SetupGuide 原样过桥）+ 行内深链解析表。 */
data class SetupGuideDoc(
    val summary: String,
    val parts: List<GuidePart>,
    val verifyHint: String,
    val troubleshooting: List<GuideErrorCase>,
    /** 空键是默认落点（创建 token 那页），其余键对应步骤的 linkTarget。 */
    val links: Map<String, String>,
    val billingURL: String,
) {
    val steps: List<GuideStep> get() = parts.flatMap { it.steps }
    /** 教程分段上的字段带 validation；catalogJson 那份没有。 */
    val fields: List<CatalogField> get() = parts.flatMap { it.fields }

    fun linkURL(target: String): String? = links[target] ?: links[""]

    companion object {
        fun parse(json: String): SetupGuideDoc? {
            val root = JSONObject(json)
            if (root.optBoolean("missing", false)) return null
            val links = mutableMapOf<String, String>()
            root.optJSONObject("links")?.let { obj ->
                obj.keys().forEach { key -> links[key] = obj.optString(key) }
            }
            return SetupGuideDoc(
                summary = root.optString("summary"),
                parts = root.optJSONArray("parts").orEmpty().mapObject { part ->
                    GuidePart(
                        fields = part.optJSONArray("fields").orEmpty().mapObject { field ->
                            parseGuideField(field)
                        },
                        steps = part.optJSONArray("steps").orEmpty().mapObject { step ->
                            GuideStep(
                                text = step.optString("text"),
                                emphasized = step.optJSONArray("emphasized").orEmpty().mapString(),
                                linkPhrases = step.optJSONArray("linkPhrases").orEmpty().mapString(),
                                linkTarget = step.optString("linkTarget"),
                                copyableLabel = step.optJSONObject("copyable")?.optString("label"),
                                copyableValue = step.optJSONObject("copyable")?.optString("value"),
                            )
                        },
                    )
                },
                verifyHint = root.optString("verifyHint"),
                troubleshooting = root.optJSONArray("troubleshooting").orEmpty().mapObject { item ->
                    GuideErrorCase(
                        httpStatus = item.optInt("httpStatus"),
                        explanation = item.optString("explanation"),
                        nextStep = item.optString("nextStep"),
                    )
                },
                links = links,
                billingURL = root.optString("billingURL"),
            )
        }
    }
}

data class GuidePart(
    val fields: List<CatalogField>,
    val steps: List<GuideStep>,
) {
    /** 分段标题，和 iOS `SetupPart.title` 同一口径。 */
    val title: String get() = fields.joinToString(" · ") { it.label }
}

data class GuideStep(
    val text: String,
    val emphasized: List<String>,
    val linkPhrases: List<String>,
    val linkTarget: String,
    val copyableLabel: String?,
    val copyableValue: String?,
)

data class GuideErrorCase(
    val httpStatus: Int,
    val explanation: String,
    val nextStep: String,
)
