package com.zhechengqi.tollcat.settings

data class TipTransaction(
    val id: String,
    val productID: String,
    val displayPrice: String,
    val jws: String,
    val purchasedAtMillis: Long,
)

enum class TipPurchaseNotice {
    Cancelled,
    Pending,
    Failed,
}
