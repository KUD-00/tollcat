package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.TrendRow
import com.zhechengqi.tollcat.UpcomingRow

object DashboardPreviewData {
    val snapshot = DashboardSnapshot(
        empty = false,
        monthTitle = "八月",
        allowsProjection = true,
        formattedTotal = "$47.20",
        formattedVariable = "$47.20",
        formattedProjected = "$87.70",
        confidence = "estimated",
        estimatedAccountIds = emptyList(),
        subscriptionFormatted = "$4.00",
        currencyNote = null,
        composition = listOf(
            CompositionRow("aws", "AWS", "aws", "$21.40", 45, 0.4534f),
            CompositionRow("cloudflare", "Cloudflare", "cloudflare", "$11.05", 23, 0.2341f),
            CompositionRow("openai", "OpenAI", "openai", "$7.62", 16, 0.1614f),
            CompositionRow("github", "GitHub", "github", "$4.00", 9, 0.0847f),
            CompositionRow("neon", "Neon", "neon", "$3.13", 7, 0.0663f),
        ),
        upcoming = listOf(
            UpcomingRow("ChatGPT Plus", "openai", "openai", "$20.00", "8 月 20 日"),
        ),
        freeQuota = listOf(
            FreeQuotaRow("vercel", "Vercel", "vercel", 84, "用了 84%"),
        ),
        formattedComparison = "$29.10",
        changePercent = 62,
        anomalies = listOf(
            AnomalyRow("aws", "AWS", "+62%", "对比 7 月同期 $13.20", 0.62),
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
        catSpeech = "合计较上月同期涨了 62%。",
        comparisonPercentText = "+62%",
        comparisonCaption = "对比 7月同期 $13.20",
        comparisonTone = "up",
    )
}
