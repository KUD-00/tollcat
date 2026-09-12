package com.zhechengqi.tollcat.settings

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.BillingClient
import com.zhechengqi.tollcat.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class TipModel(
    context: Context,
    private val store: TipStore = TipStore(context),
    private val billing: PlayBillingTips? = PlayBillingTips(context),
    private val messenger: (TipMessagePayload) -> Boolean = { TipMessageClient.submit(it) },
    private val appVersion: String = appVersionShort(context),
    previewOfferings: List<TipOffering>? = null,
) {
    enum class CatalogState { Loading, Ready, Unavailable }

    var catalogState by mutableStateOf(if (previewOfferings == null) CatalogState.Loading else CatalogState.Ready)
        private set
    var offerings by mutableStateOf(previewOfferings.orEmpty())
        private set
    var records by mutableStateOf(store.all())
        private set
    var isPurchasing by mutableStateOf(false)
        private set
    var purchaseNotice by mutableStateOf<TipPurchaseNotice?>(null)
        private set
    var thanksVisible by mutableStateOf(records.isNotEmpty())
        private set
    var thanksTreat by mutableStateOf<TipProductID?>(null)
        private set
    var thanksIsRepeat by mutableStateOf(false)
        private set
    var composerVisible by mutableStateOf(false)
        private set
    var draftName by mutableStateOf("")
    var draftMessage by mutableStateOf("")
    var pendingTransactionID by mutableStateOf<String?>(null)
        private set
    var willRetryMessage by mutableStateOf(false)
        private set

    val thanks: TipThanks get() = TipThanks.make(thanksTreat, thanksIsRepeat)

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val preview = previewOfferings != null

    init {
        billing?.events = object : PlayBillingTips.Events {
            override fun onTransaction(transaction: TipTransaction) {
                ingest(transaction, showComposer = true)
                isPurchasing = false
                scope.launch { billing.consume(transaction.id) }
            }

            override fun onCancelled() {
                isPurchasing = false
                purchaseNotice = TipPurchaseNotice.Cancelled
            }

            override fun onPending() {
                isPurchasing = false
                purchaseNotice = TipPurchaseNotice.Pending
            }

            override fun onFailed() {
                isPurchasing = false
                purchaseNotice = TipPurchaseNotice.Failed
            }
        }
    }

    fun start() {
        if (preview) {
            scope.launch { retryUnsentMessages() }
            return
        }
        scope.launch {
            catalogState = CatalogState.Loading
            billing?.start()
            val products = billing?.loadProducts().orEmpty()
            if (products.isEmpty()) {
                offerings = emptyList()
                catalogState = CatalogState.Unavailable
            } else {
                offerings = products
                catalogState = CatalogState.Ready
            }
            reloadHistory()
            billing?.restoreUnconsumed()
            retryUnsentMessages()
        }
    }

    fun release() {
        scope.cancel()
        billing?.end()
    }

    fun buy(activity: Activity, offering: TipOffering) {
        if (isPurchasing) return
        isPurchasing = true
        purchaseNotice = null
        if (preview) {
            ingest(
                TipTransaction(
                    id = "preview-${offering.id}-${System.currentTimeMillis()}",
                    productID = offering.id,
                    displayPrice = offering.displayPrice,
                    jws = "preview",
                    purchasedAtMillis = System.currentTimeMillis(),
                ),
                showComposer = true,
            )
            isPurchasing = false
            return
        }
        val code = billing?.launchPurchase(activity, offering.id)
            ?: BillingClient.BillingResponseCode.ERROR
        when (code) {
            BillingClient.BillingResponseCode.OK -> Unit
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> {
                isPurchasing = false
                scope.launch { billing?.restoreUnconsumed() }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                isPurchasing = false
                purchaseNotice = TipPurchaseNotice.Cancelled
            }
            else -> {
                isPurchasing = false
                purchaseNotice = TipPurchaseNotice.Failed
            }
        }
    }

    fun submitComposer() {
        val transactionID = pendingTransactionID
        if (transactionID == null) {
            composerVisible = false
            return
        }
        store.updateDraft(
            transactionID,
            TipFieldLimits.clampName(draftName),
            TipFieldLimits.clampMessage(draftMessage),
        )
        composerVisible = false
        pendingTransactionID = null
        scope.launch { submit(transactionID) }
    }

    fun skipComposer() {
        val transactionID = pendingTransactionID
        if (transactionID == null) {
            composerVisible = false
            return
        }
        composerVisible = false
        pendingTransactionID = null
        scope.launch { submit(transactionID) }
    }

    /** 划掉这页等于「这次不留」。已经点过写好了就什么都不做。 */
    fun abandonComposerIfNeeded() {
        if (composerVisible && pendingTransactionID != null) skipComposer()
    }

    private suspend fun retryUnsentMessages() {
        val pending = store.unsynced()
        for (record in pending) {
            if (composerVisible && record.transactionID == pendingTransactionID) continue
            submit(record.transactionID)
        }
    }

    private fun ingest(transaction: TipTransaction, showComposer: Boolean) {
        val (_, created) = store.upsert(
            transactionID = transaction.id,
            productID = transaction.productID,
            displayPrice = transaction.displayPrice,
            purchasedAtMillis = transaction.purchasedAtMillis,
            jws = transaction.jws,
            appVersion = appVersion,
        )
        reloadHistory()
        thanksVisible = true
        thanksTreat = TipProductID.fromRaw(transaction.productID)
        thanksIsRepeat = records.size > 1
        purchaseNotice = null
        if (showComposer && created) {
            pendingTransactionID = transaction.id
            composerVisible = true
            draftName = ""
            draftMessage = ""
        }
    }

    private suspend fun submit(transactionID: String) {
        val record = store.fetch(transactionID) ?: return
        val payload = TipMessagePayload.of(
            transactionID = record.transactionID,
            jws = record.jws,
            productID = record.productID,
            displayPrice = record.displayPrice,
            name = record.name,
            message = record.message,
            appVersion = record.appVersion,
        )
        val ok = withContext(Dispatchers.IO) { messenger(payload) }
        if (ok) {
            store.markSubmitted(transactionID)
            val remaining = store.unsynced()
            willRetryMessage = remaining.any { it.transactionID != pendingTransactionID }
            reloadHistory()
        } else {
            willRetryMessage = true
            reloadHistory()
        }
    }

    private fun reloadHistory() {
        records = store.all()
    }

    companion object {
        fun preview(context: Context, seedHistory: Boolean = false, unavailable: Boolean = false): TipModel {
            val store = TipStore(context)
            if (seedHistory && store.fetch("preview-1") == null) {
                store.upsert(
                    transactionID = "preview-1",
                    productID = TipProductID.Small.raw,
                    displayPrice = "6.00",
                    purchasedAtMillis = 1_787_000_000_000L,
                    name = "陈",
                    message = "好用",
                    jws = "preview-jws",
                    appVersion = "0.1.0",
                )
            }
            val offerings = if (unavailable) {
                emptyList()
            } else {
                listOf(
                    TipOffering(TipProductID.Small.raw, context.getString(R.string.settings_tip_candy), "¥6.00"),
                    TipOffering(TipProductID.Medium.raw, context.getString(R.string.settings_tip_coffee), "¥18.00"),
                    TipOffering(TipProductID.Large.raw, context.getString(R.string.settings_tip_pizza), "¥45.00"),
                )
            }
            val model = TipModel(
                context = context,
                store = store,
                billing = null,
                messenger = { true },
                appVersion = "0.1.0",
                previewOfferings = offerings,
            )
            if (unavailable) model.catalogState = CatalogState.Unavailable
            if (seedHistory) model.thanksVisible = true
            return model
        }
    }

    internal fun previewOpenComposer() {
        composerVisible = true
        pendingTransactionID = records.firstOrNull()?.transactionID ?: "preview-1"
        thanksTreat = TipProductID.Large
        thanksVisible = true
    }
}
