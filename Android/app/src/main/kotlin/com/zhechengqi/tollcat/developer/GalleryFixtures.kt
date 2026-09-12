package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.TrendRow
import com.zhechengqi.tollcat.UpcomingRow

object GalleryFixtures {
    fun composition(items: List<Triple<String, String, Pair<String, Int>>>): List<CompositionRow> {
        val totalPercent = items.sumOf { it.third.second }.coerceAtLeast(1)
        return items.map { (id, name, amountAndPercent) ->
            val (amount, percent) = amountAndPercent
            CompositionRow(
                providerId = id,
                displayName = name,
                colorKey = id,
                amount = amount,
                percent = percent,
                fraction = percent / totalPercent.toFloat(),
            )
        }
    }

    val specComposition = composition(
        listOf(
            Triple("aws", "AWS", "$21.40" to 45),
            Triple("cloudflare", "Cloudflare", "$11.05" to 23),
            Triple("openai", "OpenAI", "$7.62" to 16),
            Triple("github", "GitHub", "$4.00" to 8),
            Triple("neon", "Neon", "$3.13" to 7),
        ),
    )

    val eightProviderComposition = composition(
        listOf(
            Triple("aws", "AWS", "$32.00" to 32),
            Triple("cloudflare", "Cloudflare", "$18.00" to 18),
            Triple("openai", "OpenAI", "$14.00" to 14),
            Triple("github", "GitHub", "$10.00" to 10),
            Triple("neon", "Neon", "$9.00" to 9),
            Triple("vercel", "Vercel", "$7.00" to 7),
            Triple("anthropic", "Anthropic", "$6.00" to 6),
            Triple("fly", "Fly.io", "$4.00" to 4),
        ),
    )

    fun anomaly(names: List<Pair<String, String>>): List<AnomalyRow> {
        return names.map { (id, name) ->
            AnomalyRow(id, name, "+62%", "对比 7 月同期 $13.20", 0.62)
        }
    }

    val upcoming = listOf(
        UpcomingRow("ChatGPT Plus", "openai", "openai", "$20.00", "8 月 20 日"),
    )

    val quota = listOf(
        FreeQuotaRow("vercel", "Vercel", "vercel", 84, "用了 84%"),
    )

    val alerts = listOf(
        BalanceAlertRow("openai", "OpenAI", "$42.00", 18, "余额 $42.00"),
    )

    val trend = listOf(
        TrendRow("3月", "$12.00", 0.55f),
        TrendRow("4月", "$18.00", 0.82f),
        TrendRow("5月", "$9.00", 0.41f),
        TrendRow("6月", "$22.00", 1f),
        TrendRow("7月", "$15.00", 0.68f),
        TrendRow("8月", "$21.00", 0.95f),
    )
}
