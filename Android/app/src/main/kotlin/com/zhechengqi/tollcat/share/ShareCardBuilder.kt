package com.zhechengqi.tollcat.share

import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.dashboard.compositionSlices

/** 把仪表快照折成分享卡要画的东西。不再打账单接口。 */
object ShareCardBuilder {
    fun content(
        dashboard: DashboardSnapshot,
        filterNote: String?,
        emptyTotal: String,
        projectedCaption: String?,
        subscriptionCaption: String?,
        otherLabel: String,
        tagline: String,
        footnote: String = ShareCardContent.HOST,
    ): ShareCardContent {
        val amount = dashboard.formattedVariable.ifBlank { dashboard.formattedTotal }
        val total = if (dashboard.empty || amount.isBlank()) emptyTotal else amount
        val slices = compositionSlices(dashboard.composition, otherLabel)
        return ShareCardContent(
            periodTitle = dashboard.periodCaption.ifBlank { dashboard.monthTitle },
            totalText = total,
            projectionText = projectedCaption?.takeIf {
                dashboard.allowsProjection && dashboard.formattedProjected.isNotBlank()
            },
            subscriptionText = subscriptionCaption,
            currencyNote = dashboard.currencyNote,
            filterNote = filterNote,
            segments = slices.map { row ->
                ShareCardContent.Segment(
                    name = row.displayName,
                    amountText = row.amount,
                    fraction = row.fraction,
                    isOther = row.providerId == "other",
                )
            },
            qrPayload = ShareCardContent.SHARE_URL,
            qrCaption = tagline,
            footnote = footnote,
        )
    }
}
