package com.zhechengqi.tollcat

import android.content.Context
import android.util.Log
import org.json.JSONObject

object Proof {
    fun log(context: Context) {
        val state = runCatching { run(context) }.getOrElse { error ->
            ProofState(
                formatted = "—",
                matches = false,
                confidence = "—",
                estimated = "—",
                source = "—",
                stubFetch = false,
                stubSpend = "—",
                keystore = false,
                persistence = false,
                error = error.message ?: error.javaClass.simpleName,
            )
        }
        Log.i(
            TAG,
            "formatted=${state.formatted} matches=${state.matches} confidence=${state.confidence} estimated=${state.estimated} source=${state.source}",
        )
        Log.i(TAG, "stubFetch=${if (state.stubFetch) "ok" else "fail"} spend=${state.stubSpend}")
        Log.i(TAG, "keystore=${if (state.keystore) "ok" else "fail"}")
        Log.i(TAG, "persistence=${if (state.persistence) "ok" else "fail"}")
        if (state.error != null) {
            Log.e(TAG, "error=${state.error}")
        }
    }

    private fun run(context: Context): ProofState {
        val proof = JSONObject(MeterCoreNative.fixtureProofJson())
        val stub = JSONObject(MeterCoreNative.stubFetchCloudflareJson())
        val credentials: CredentialStore = AndroidKeystoreCredentialStore(context)
        val ledger: LedgerStore = SqliteLedgerStore(context, "tollcat-prove.db")
        return ProofState(
            formatted = proof.optString("formatted", "—"),
            matches = proof.optBoolean("matches"),
            confidence = proof.optString("confidence", "—"),
            estimated = proof.optString("estimated", "—"),
            source = proof.optString("source", "—"),
            stubFetch = stub.optBoolean("ok"),
            stubSpend = stub.optString("spend", "—"),
            keystore = proveKeystore(credentials),
            persistence = provePersistence(ledger, stub),
            error = listOfNotNull(
                proof.optString("error").ifBlank { null },
                stub.optString("error").ifBlank { null },
            ).joinToString("; ").ifBlank { null },
        )
    }

    private fun proveKeystore(store: CredentialStore): Boolean {
        val reference = "cloudflare.apiToken"
        store.delete(reference)
        store.save("cf-token-MUST-NOT-LEAK", reference)
        val roundTrip = store.read(reference) == "cf-token-MUST-NOT-LEAK"
        store.delete(reference)
        return roundTrip
    }

    private fun provePersistence(store: LedgerStore, stub: JSONObject): Boolean {
        val spend = stub.optString("spend").ifBlank { null }
        store.clearAll()
        store.insertSnapshot(
            SnapshotRow(
                providerId = "cloudflare",
                accountId = "fixture-cloudflare",
                kind = "usage",
                currentSpendUsd = spend,
                fetchedAtMillis = 1_787_184_000_000L,
            ),
        )
        store.upsertMembership(MembershipRow(providerId = "cloudflare", sortIndex = 0))
        store.upsertSubscription(
            SubscriptionRow(
                id = "proof-chatgpt-plus",
                name = "ChatGPT Plus",
                amountUsd = "20",
                period = "monthly",
                anchorYear = 2026,
                anchorMonth = 8,
                anchorDay = 20,
            ),
        )
        val snapshotOk = store.snapshots().any {
            it.providerId == "cloudflare" && it.currentSpendUsd == spend
        }
        val membershipOk = store.memberships().any { it.providerId == "cloudflare" }
        val subscriptionOk = store.subscriptions().any {
            it.name == "ChatGPT Plus" && it.amountUsd == "20"
        }
        return snapshotOk && membershipOk && subscriptionOk
    }

    const val TAG = "TollCat"
}

data class ProofState(
    val formatted: String,
    val matches: Boolean,
    val confidence: String,
    val estimated: String,
    val source: String,
    val stubFetch: Boolean,
    val stubSpend: String,
    val keystore: Boolean,
    val persistence: Boolean,
    val error: String?,
)
