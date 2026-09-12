package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.BudgetRow
import com.zhechengqi.tollcat.CategorySliceRow
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.HeatmapMonthRow
import com.zhechengqi.tollcat.PinnedServiceRow
import com.zhechengqi.tollcat.SubscriptionModuleItem
import com.zhechengqi.tollcat.SubscriptionsModuleRow
import com.zhechengqi.tollcat.SuperlativeRow
import com.zhechengqi.tollcat.TrendRow
import com.zhechengqi.tollcat.UpcomingRow

/**
 * 设计稿那组数字（SPEC 第 04 节），实验室在当前账本缺某一块时拿来填。
 * 只构造值对象，不碰 store。
 */
object DashboardLabFixtures {
    val contents: DashboardSnapshot = make()

    init {
        DashboardLabModules.defaultOrder.forEach { id ->
            check(DashboardLabModules.has(contents, id)) { "lab fixture missing $id" }
        }
    }

    private fun make(): DashboardSnapshot = DashboardSnapshot(
        empty = false,
        monthTitle = "八月",
        periodCaption = "八月",
        allowsProjection = true,
        formattedTotal = "$47.20",
        formattedVariable = "$47.20",
        formattedProjected = "$87.70",
        confidence = "estimated",
        estimatedAccountIds = emptyList(),
        subscriptionFormatted = "$4.00",
        currencyNote = null,
        composition = composition,
        upcoming = listOf(
            UpcomingRow("ChatGPT Plus", "openai", "openai", "$20.00", "8 月 20 日"),
        ),
        freeQuota = listOf(
            FreeQuotaRow("vercel", "Vercel", "vercel", 34, "用了 34%"),
            FreeQuotaRow("github", "GitHub", "github", 84, "用了 84%"),
        ),
        formattedComparison = "$29.10",
        changePercent = 62,
        catSpeech = "合计较上月同期涨了 62%。",
        comparisonPercentText = "+62%",
        comparisonCaption = "对比 7月同期 $13.20",
        comparisonTone = "up",
        anomalies = listOf(
            AnomalyRow("aws", "AWS", "+62%", "对比 7 月同期 $13.20", 0.62),
            AnomalyRow("openai", "OpenAI", "+41%", "对比 7 月同期 $13.20", 0.41),
            AnomalyRow("cloudflare", "Cloudflare", "+33%", "对比 7 月同期 $13.20", 0.33),
        ),
        balanceAlerts = listOf(
            BalanceAlertRow("openai", "OpenAI", "$42.00", 18, "余额 $42.00"),
        ),
        trend = listOf(
            TrendRow("3月", "$12.00", 0.55f),
            TrendRow("4月", "$18.00", 0.82f),
            TrendRow("5月", "$9.00", 0.41f),
            TrendRow("6月", "$22.00", 1f),
            TrendRow("7月", "$15.00", 0.68f),
            TrendRow("8月", "$21.00", 0.95f),
        ),
        catMood = "shocked",
        heatmap = heatmap,
        categories = categories,
        budget = BudgetRow(
            spentText = "$47.20",
            budgetText = "$80.00",
            remainingText = "$32.80",
            overText = "$0.00",
            fraction = 0.59f,
            usedPercent = 59,
            isOver = false,
            isClose = false,
        ),
        superlatives = listOf(
            SuperlativeRow("biggestRise", "AWS", "+62%", "aws", "", "aws"),
            SuperlativeRow("biggestShare", "Cloudflare", "45%", "cloudflare", "", "cloudflare"),
            SuperlativeRow("stalest", "Neon", "3", "neon", "", "neon"),
        ),
        pinnedServices = services,
        subscriptions = subscriptions,
    )

    /** 五家才看得出宽卡分两列。金额是 SPEC 第 04 节那组。 */
    private val services = listOf(
        service("aws", "AWS", "$21.40", "+62%", true, listOf(12f, 14f, 13f, 16f, 19f, 21f)),
        service("cloudflare", "Cloudflare", "$11.05", "+12%", true, listOf(6f, 8f, 7f, 9f, 10f, 11f)),
        service("openai", "OpenAI", "$7.62", null, false, listOf(4f, 5f, 5f, 6f, 7f, 7.6f)),
        service("github", "GitHub", "$4.00", null, false, listOf(4f, 4f, 4f, 4f, 4f, 4f)),
        service("neon", "Neon", "$3.13", null, false, listOf(0f, 0f, 2f, 3f, 3f, 3.1f)),
    )

    private val composition = listOf(
        CompositionRow("aws", "AWS", "aws", "$21.40", 45, 0.4534f),
        CompositionRow("cloudflare", "Cloudflare", "cloudflare", "$11.05", 23, 0.2341f),
        CompositionRow("openai", "OpenAI", "openai", "$7.62", 16, 0.1614f),
        CompositionRow("github", "GitHub", "github", "$4.00", 9, 0.0847f),
        CompositionRow("neon", "Neon", "neon", "$3.13", 7, 0.0663f),
    )

    private val subscriptions = SubscriptionsModuleRow(
        monthlyTotalText = "$24.00",
        countCaption = "2 笔，折算每月。年付按 12 摊。",
        nextChargeCaption = "下一笔：GitHub Team，9月12日",
        items = listOf(
            SubscriptionModuleItem("a", "GitHub Team", "$4.00", "每月", "", "github", "github", 1),
            SubscriptionModuleItem("b", "ChatGPT Plus", "$20.00", "每月", "", "openai", "openai", 1),
        ),
    )

    private val categories = listOf(
        CategorySliceRow("hosting", "$21.40", 55, 0.55f, "aws", listOf("AWS", "Vercel")),
        CategorySliceRow("aiInference", "$7.62", 20, 0.20f, "openai", listOf("OpenAI")),
        CategorySliceRow("networkEdge", "$11.05", 25, 0.25f, "cloudflare", listOf("Cloudflare")),
    )

    private val heatmap = listOf(
        HeatmapMonthRow(
            monthStartMillis = 1_785_542_400_000L,
            title = "2026年8月",
            monthTitle = "8月",
            values = (1..31).map { ((it * 7) % 11).toDouble() },
            leadingEmptyDays = 6,
            totalText = "$44.05",
            peakCaption = "花得最多：8月19日，$3.20",
            dayLabels = emptyList(),
        ),
        HeatmapMonthRow(
            monthStartMillis = 1_788_220_800_000L,
            title = "2026年9月",
            monthTitle = "9月",
            values = (1..30).map { if (it > 3) null else it * 0.6 },
            leadingEmptyDays = 2,
            totalText = "$1.81",
            peakCaption = "花得最多：9月1日，$1.28",
            dayLabels = emptyList(),
        ),
    )

    private fun service(
        id: String,
        name: String,
        amount: String,
        change: String?,
        up: Boolean,
        spark: List<Float>,
    ) = PinnedServiceRow(
        accountId = "",
        providerId = id,
        displayName = name,
        colorKey = id,
        amountText = amount,
        spark = spark,
        changeText = change,
        changeIsUp = up,
    )
}
