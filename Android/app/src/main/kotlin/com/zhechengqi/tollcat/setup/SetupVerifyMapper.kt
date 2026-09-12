package com.zhechengqi.tollcat.setup

import android.content.Context
import com.zhechengqi.tollcat.FetchResult
import com.zhechengqi.tollcat.GuideErrorCase
import com.zhechengqi.tollcat.MeterCoreNative
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.hasBillableMetrics
import com.zhechengqi.tollcat.isNetworkErrorDump
import kotlin.math.round

/** 把 JNI 的 fetch JSON 折成人话。不在这里发明 HTTP。 */
object SetupVerifyMapper {
    fun outcome(
        context: Context,
        result: FetchResult,
        troubleshooting: List<GuideErrorCase>,
    ): SetupVerifyOutcome {
        if (result.ok) {
            val snapshot = result.snapshot
            if (snapshot != null && snapshot.hasBillableMetrics) {
                return SetupVerifyOutcome.Success(
                    title = successTitle(context, snapshot, result.spend),
                    detail = periodDetail(context, snapshot.periodStartMillis, snapshot.periodEndMillis, snapshot.dailyUsdJson),
                )
            }
            return SetupVerifyOutcome.EmptyReading
        }
        val status = result.httpStatus
        if (status != null) {
            val match = troubleshooting.firstOrNull { it.httpStatus == status }
            return SetupVerifyOutcome.Http(match ?: fallbackErrorCase(context, status))
        }
        if (isNetworkErrorDump(result.error)) return SetupVerifyOutcome.Network
        return SetupVerifyOutcome.Unknown
    }

    private fun successTitle(context: Context, snapshot: SnapshotRow, spend: String?): String {
        fun money(raw: String?): String? = raw?.takeIf { it.isNotBlank() }?.let { MoneyDisplay.formatUsd(it) }
        val spendText = money(snapshot.currentSpendUsd) ?: spend?.takeIf { it.isNotBlank() }
        return when (snapshot.kind) {
            "prepaid" -> {
                spendText?.let { context.getString(R.string.setup_verify_period_spend, it) }
                    ?: money(snapshot.balanceUsd)?.let { context.getString(R.string.services_balance, it) }
                    ?: context.getString(R.string.setup_verify_period_spend, "—")
            }
            "subscription" -> context.getString(
                R.string.services_dot_join,
                context.getString(R.string.kind_subscription_title),
                money(snapshot.committedMonthlyUsd) ?: "—",
            )
            "freeTier" -> {
                val percent = snapshot.freeQuotaUsedRatio?.let { round(it * 100.0).toInt() } ?: 0
                context.getString(
                    R.string.services_dot_join,
                    context.getString(R.string.services_free_quota),
                    context.getString(R.string.services_quota_used, percent),
                )
            }
            "planAndUsage" -> {
                val committed = money(snapshot.committedMonthlyUsd)
                val usage = spendText
                when {
                    committed != null && usage != null -> context.getString(R.string.services_dot_join, committed, usage)
                    committed != null -> context.getString(
                        R.string.services_dot_join,
                        context.getString(R.string.kind_subscription_title),
                        committed,
                    )
                    else -> context.getString(R.string.setup_verify_period_spend, usage ?: "—")
                }
            }
            else -> context.getString(R.string.setup_verify_period_spend, spendText ?: "—")
        }
    }

    private fun periodDetail(
        context: Context,
        startMillis: Long,
        endMillis: Long,
        dailyUsdJson: String?,
    ): String? {
        if (startMillis <= 0L || endMillis <= 0L) return null
        val granularity = context.getString(
            if (dailyUsdJson.isNullOrBlank()) {
                R.string.setup_verify_no_daily
            } else {
                R.string.setup_verify_daily
            },
        )
        return context.getString(
            R.string.setup_verify_period_detail,
            monthDay(startMillis),
            monthDay(endMillis),
            granularity,
        )
    }

    /** 月日的写法在共享层（`MeterDateFormat`）。手拼 "9/9" 在英日下是错的。 */
    private fun monthDay(millis: Long): String {
        return MeterCoreNative.formatMonthAndDay(millis, MoneyDisplay.localeTag())
    }

    private fun fallbackErrorCase(context: Context, status: Int): GuideErrorCase {
        return when (status) {
            401 -> GuideErrorCase(
                httpStatus = 401,
                explanation = context.getString(R.string.setup_verify_401_body),
                nextStep = context.getString(R.string.setup_verify_401_next),
            )
            403 -> GuideErrorCase(
                httpStatus = 403,
                explanation = context.getString(R.string.setup_verify_403_body),
                nextStep = context.getString(R.string.setup_verify_403_next),
            )
            else -> GuideErrorCase(
                httpStatus = status,
                explanation = context.getString(R.string.setup_verify_unknown_body),
                nextStep = context.getString(R.string.setup_verify_unknown_next),
            )
        }
    }
}
