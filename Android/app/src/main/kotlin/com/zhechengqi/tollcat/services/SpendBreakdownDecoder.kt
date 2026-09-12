package com.zhechengqi.tollcat.services

import com.zhechengqi.tollcat.mapObject
import com.zhechengqi.tollcat.orEmpty
import com.zhechengqi.tollcat.warnOnSchemaDrift
import org.json.JSONObject

/**
 * 桥的「花在哪了」JSON → 一屏能画的内容。**这里只拼句子**：分组、排序、占比、
 * 折叠成「其他」、用量位数都在共享层算完了。
 */
object SpendBreakdownDecoder {
    fun decode(
        json: String,
        otherTitle: String,
        allowance: (String) -> String,
        listPrice: (String) -> String,
        discount: (String, String) -> String,
    ): SpendBreakdownContent {
        val root = runCatching { JSONObject(json) }.getOrNull() ?: return SpendBreakdownContent.empty
        warnOnSchemaDrift(root, "spendBreakdown")
        if (root.optBoolean("empty", true)) return SpendBreakdownContent.empty

        val groups = root.optJSONArray("groups").orEmpty().mapObject { item ->
            val title = if (item.optBoolean("isOther")) otherTitle else item.optString("title")
            val amount = item.optString("amountText")
            SpendBreakdownGroup(
                id = item.optString("id"),
                title = title,
                amountCaption = amount,
                fraction = item.optDouble("fraction", 0.0),
                shareCaption = item.optString("shareCaption").ifBlank { null },
                detailCaption = item.optString("detailCaption").ifBlank { null },
                // 有原价就写抵扣了多少；没有就退回厂商自己写的那句额度说明。
                allowanceCaption = item.optString("discountText").ifBlank { null }?.let(allowance)
                    ?: item.optString("allowanceNote").ifBlank { null },
                isZeroBilled = item.optBoolean("isZeroBilled"),
                items = item.optJSONArray("items").orEmpty().mapObject { row ->
                    val rowAmount = row.optString("amountText")
                    val rowTitle = row.optString("title")
                    SpendBreakdownItem(
                        id = row.optString("id"),
                        title = rowTitle,
                        amountCaption = rowAmount,
                        detailCaption = row.optString("detailCaption").ifBlank { null },
                        listCaption = row.optString("listText").ifBlank { null }?.let(listPrice),
                        spokenLabel = "$rowTitle，$rowAmount",
                    )
                },
                spokenLabel = "$title，$amount",
            )
        }
        val total = root.optString("totalText")
        val listTotal = root.optString("listTotalText").ifBlank { null }
        val saved = root.optString("savedText").ifBlank { null }
        return SpendBreakdownContent(
            groups = groups,
            supportsScopeGrouping = root.optBoolean("supportsScope"),
            totalCaption = total,
            discountCaption = if (listTotal != null && saved != null) discount(listTotal, saved) else null,
            itemCount = root.optInt("itemCount"),
            spokenSummary = total,
        )
    }
}
