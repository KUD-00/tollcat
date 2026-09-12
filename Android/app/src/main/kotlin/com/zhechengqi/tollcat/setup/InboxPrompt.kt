package com.zhechengqi.tollcat.setup

import android.content.Context
import com.zhechengqi.tollcat.R
import java.util.Calendar

/**
 * 交给 AI 的任务书。密钥不进这段话，投递 key 用 `$TOLL_INGEST_KEY` 引用。
 * HTTP 合同不进翻译；地址与 `InboxEndpoint.readingsURL` 同一条。
 */
object InboxPrompt {
    const val READINGS_URL = "https://api.tollcat.app/v1/readings"

    fun text(
        context: Context,
        displayName: String,
        providerId: String,
        nowMillis: Long,
    ): String {
        return listOf(
            context.getString(R.string.inbox_prompt_lede, displayName),
            "",
            context.getString(R.string.inbox_prompt_step1, displayName),
            context.getString(R.string.inbox_prompt_no_api),
            "",
            context.getString(R.string.inbox_prompt_step2),
            "",
            requestBlock(providerId, nowMillis),
            "",
            context.getString(R.string.inbox_prompt_rules),
            context.getString(R.string.inbox_prompt_rule_mtd),
            context.getString(R.string.inbox_prompt_rule_string),
            context.getString(R.string.inbox_prompt_rule_period),
            context.getString(R.string.inbox_prompt_rule_overwrite),
            context.getString(R.string.inbox_prompt_rule_daily),
            "",
            context.getString(R.string.inbox_prompt_env),
            context.getString(R.string.inbox_prompt_no_elsewhere),
        ).joinToString("\n")
    }

    fun requestBlock(providerId: String, nowMillis: Long): String {
        val body = "{\"provider\":\"$providerId\"," +
            "\"periodStart\":\"${monthStart(nowMillis)}\"," +
            "\"currentSpendUSD\":\"12.34\"}"
        return listOf(
            "  POST $READINGS_URL",
            "  Authorization: Bearer \$TOLL_INGEST_KEY",
            "  content-type: application/json",
            "",
            "  $body",
        ).joinToString("\n")
    }

    fun monthStart(nowMillis: Long): String {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMillis
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        return "%04d-%02d-01".format(year, month)
    }
}
