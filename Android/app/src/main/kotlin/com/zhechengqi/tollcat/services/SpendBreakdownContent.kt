package com.zhechengqi.tollcat.services

/**
 * 明细分组的两个维度。`scope` 那一维不是每家都有，能不能选由内容决定。
 */
enum class SpendBreakdownGrouping(val raw: String) {
    /** 按类别（Cloudflare 的产品线、GitHub 的 product）。 */
    Category("category"),
    /** 按归属（仓库 / project / 数据库）。 */
    Scope("scope"),
}

data class SpendBreakdownContent(
    val groups: List<SpendBreakdownGroup>,
    val supportsScopeGrouping: Boolean,
    /** 明细自身的合计。不等于快照的花费字段，只给这一页的环和占比用。 */
    val totalCaption: String,
    val discountCaption: String?,
    val itemCount: Int,
    val spokenSummary: String,
) {
    val isEmpty: Boolean get() = groups.isEmpty()

    /**
     * 详情页「本月」底下最多列几组。真花钱的才进预览——$0 那几行留给全屏页。
     */
    val previewGroups: List<SpendBreakdownGroup>
        get() = groups.filter { !it.isZeroBilled }.take(previewGroupLimit)

    companion object {
        const val previewGroupLimit = 3

        val empty = SpendBreakdownContent(
            groups = emptyList(),
            supportsScopeGrouping = false,
            totalCaption = "—",
            discountCaption = null,
            itemCount = 0,
            spokenSummary = "",
        )
    }
}

data class SpendBreakdownGroup(
    val id: String,
    val title: String,
    val amountCaption: String,
    val fraction: Double,
    val shareCaption: String?,
    val detailCaption: String?,
    val allowanceCaption: String?,
    val isZeroBilled: Boolean,
    val items: List<SpendBreakdownItem>,
    val spokenLabel: String,
)

data class SpendBreakdownItem(
    val id: String,
    val title: String,
    val amountCaption: String,
    val detailCaption: String?,
    val listCaption: String?,
    val spokenLabel: String,
)
