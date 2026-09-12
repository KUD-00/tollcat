package com.zhechengqi.tollcat.settings

/** 展示用的一档。价格只认 Play 给的 formattedPrice。 */
data class TipOffering(
    val id: String,
    val displayName: String,
    val displayPrice: String,
) {
    val productID: TipProductID? get() = TipProductID.fromRaw(id)
}
