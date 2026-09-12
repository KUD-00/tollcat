package com.zhechengqi.tollcat.share

/**
 * 分享卡上要画的东西。全是已经格式化好的字符串和 0–1 的比例。
 * 卡会离开 App，月份、合计、构成都要写在图上。
 */
data class ShareCardContent(
    val periodTitle: String,
    val totalText: String,
    val projectionText: String?,
    val subscriptionText: String?,
    val currencyNote: String?,
    val filterNote: String?,
    val segments: List<Segment>,
    val qrCaption: String,
    val footnote: String,
    val qrPayload: String = SHARE_URL,
) {
    data class Segment(
        val name: String,
        val amountText: String,
        val fraction: Float,
        val isOther: Boolean = false,
    )

    companion object {
        const val HOST = "tollcat.app"
        const val SHARE_URL = "https://tollcat.app"

        /** Preview / 验收。数字取 SPEC 第 04 节那组。 */
        fun preview(
            periodTitle: String,
            tagline: String,
        ): ShareCardContent = ShareCardContent(
            periodTitle = periodTitle,
            totalText = "$47.20",
            projectionText = "预计月底 $87.70",
            subscriptionText = "本月订阅 +$4.00",
            currencyNote = null,
            filterNote = null,
            segments = listOf(
                Segment("AWS", "$21.40", 0.45f),
                Segment("Cloudflare", "$11.05", 0.23f),
                Segment("OpenAI", "$7.62", 0.16f),
                Segment("GitHub", "$4.00", 0.09f),
                Segment("Neon", "$3.13", 0.07f),
            ),
            qrPayload = SHARE_URL,
            qrCaption = tagline,
            footnote = HOST,
        )
    }
}
