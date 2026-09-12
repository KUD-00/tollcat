package com.zhechengqi.tollcat.settings

data class TipHistoryItem(
    val transactionID: String,
    val productID: String,
    val displayPrice: String,
    val purchasedAtMillis: Long,
    val name: String?,
    val message: String?,
    val isSubmitted: Boolean,
    val jws: String,
    val appVersion: String,
) {
    val productTitleRes: Int
        get() = TipProductID.fromRaw(productID)?.titleRes ?: 0
}
