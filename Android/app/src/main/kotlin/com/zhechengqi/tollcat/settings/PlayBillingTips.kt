package com.zhechengqi.tollcat.settings

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ConsumeParams
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.consumePurchase
import com.android.billingclient.api.queryProductDetails
import com.android.billingclient.api.queryPurchasesAsync
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import org.json.JSONObject
import kotlin.coroutines.resume

/**
 * Play 结算对 iOS StoreKit 那三档消耗型打赏。
 * 买完立刻 consume，才能再买同一档。
 */
class PlayBillingTips(
    context: Context,
) {
    interface Events {
        fun onTransaction(transaction: TipTransaction)
        fun onCancelled()
        fun onPending()
        fun onFailed()
    }

    var events: Events? = null

    private val products = linkedMapOf<String, ProductDetails>()
    private val main = Handler(Looper.getMainLooper())

    private val client: BillingClient = BillingClient.newBuilder(context.applicationContext)
        .setListener { result, purchases ->
            main.post { handlePurchasesUpdated(result, purchases) }
        }
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build(),
        )
        .enableAutoServiceReconnection()
        .build()

    suspend fun start() {
        ensureConnected()
    }

    fun end() {
        if (client.isReady) client.endConnection()
    }

    suspend fun loadProducts(): List<TipOffering> {
        if (!ensureConnected()) return emptyList()
        var offerings = queryOfferings()
        if (offerings.isEmpty()) {
            // Play 刚连上时第一次查询偶尔是空的，和 StoreKit 本地店面同一类。
            delay(400)
            offerings = queryOfferings()
        }
        return offerings
    }

    suspend fun restoreUnconsumed() {
        if (!ensureConnected()) return
        val result = withContext(Dispatchers.IO) {
            client.queryPurchasesAsync(
                QueryPurchasesParams.newBuilder()
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build(),
            )
        }
        if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) return
        for (purchase in result.purchasesList) {
            handlePurchase(purchase, notify = true)
        }
    }

    fun launchPurchase(activity: Activity, productID: String): Int {
        val details = products[productID] ?: return BillingClient.BillingResponseCode.ITEM_UNAVAILABLE
        val offer = details.oneTimeOffer()
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)
            .apply {
                val token = offer?.offerToken.orEmpty()
                if (token.isNotEmpty()) setOfferToken(token)
            }
            .build()
        val flow = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productParams))
            .build()
        return client.launchBillingFlow(activity, flow).responseCode
    }

    private suspend fun queryOfferings(): List<TipOffering> {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                TipProductID.allRawValues.map { id ->
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(id)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build()
                },
            )
            .build()
        val result = withContext(Dispatchers.IO) { client.queryProductDetails(params) }
        if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            return emptyList()
        }
        val fetched = result.productDetailsList.orEmpty()
        products.clear()
        for (details in fetched) {
            products[details.productId] = details
        }
        return TipProductID.entries.mapNotNull { id ->
            val details = products[id.raw] ?: return@mapNotNull null
            val price = details.oneTimeOffer()?.formattedPrice ?: return@mapNotNull null
            TipOffering(
                id = details.productId,
                displayName = details.name.ifBlank { details.productId },
                displayPrice = price,
            )
        }
    }

    private fun handlePurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                if (purchases.isNullOrEmpty()) return
                for (purchase in purchases) {
                    handlePurchase(purchase, notify = true)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> events?.onCancelled()
            else -> events?.onFailed()
        }
    }

    private fun handlePurchase(purchase: Purchase, notify: Boolean) {
        when (purchase.purchaseState) {
            Purchase.PurchaseState.PENDING -> {
                if (notify) events?.onPending()
            }
            Purchase.PurchaseState.PURCHASED -> {
                val productID = purchase.products.firstOrNull() ?: return
                val price = products[productID]?.oneTimeOffer()?.formattedPrice.orEmpty()
                val jws = JSONObject()
                    .put("signature", purchase.signature)
                    .put("signedData", purchase.originalJson)
                    .toString()
                val transaction = TipTransaction(
                    id = purchase.purchaseToken,
                    productID = productID,
                    displayPrice = price,
                    jws = jws,
                    purchasedAtMillis = purchase.purchaseTime,
                )
                if (notify) events?.onTransaction(transaction)
            }
        }
    }

    suspend fun consume(purchaseToken: String) {
        if (purchaseToken.isEmpty()) return
        if (!ensureConnected()) return
        withContext(Dispatchers.IO) {
            client.consumePurchase(
                ConsumeParams.newBuilder().setPurchaseToken(purchaseToken).build(),
            )
        }
    }

    private suspend fun ensureConnected(): Boolean {
        if (client.isReady) return true
        return suspendCancellableCoroutine { cont ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (cont.isActive) {
                        cont.resume(result.responseCode == BillingClient.BillingResponseCode.OK)
                    }
                }

                override fun onBillingServiceDisconnected() = Unit
            })
        }
    }
}

private fun ProductDetails.oneTimeOffer(): ProductDetails.OneTimePurchaseOfferDetails? {
    oneTimePurchaseOfferDetailsList?.firstOrNull()?.let { return it }
    @Suppress("DEPRECATION")
    return oneTimePurchaseOfferDetails
}
