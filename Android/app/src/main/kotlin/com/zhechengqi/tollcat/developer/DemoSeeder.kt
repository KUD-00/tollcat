package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.AccountRow
import com.zhechengqi.tollcat.CredentialStore
import com.zhechengqi.tollcat.LedgerStore
import com.zhechengqi.tollcat.MembershipRow
import com.zhechengqi.tollcat.MeterCoreNative
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.SubscriptionRow
import org.json.JSONArray
import org.json.JSONObject

object DemoSeeder {
    const val REFERENCE_PREFIX = "demo.credential."

    sealed interface Result {
        data object Seeded : Result
        data object NotEmpty : Result
        data class Failed(val message: String) : Result
    }

    fun containsDemoData(ledger: LedgerStore): Boolean {
        return ledger.accounts().any { it.credentialReference.startsWith(REFERENCE_PREFIX) }
    }

    fun seed(
        ledger: LedgerStore,
        credentials: CredentialStore,
        nowMillis: Long,
    ): Result {
        if (ledger.snapshots().isNotEmpty()) return Result.NotEmpty
        val payload = runCatching { JSONObject(MeterCoreNative.designSeedJson(nowMillis)) }
            .getOrElse { return Result.Failed(it.message ?: "seed json") }
        if (!payload.optBoolean("ok", false)) {
            return Result.Failed(payload.optString("error").ifBlank { "seed json" })
        }
        val connections = payload.optJSONArray("connections") ?: JSONArray()
        val snapshots = payload.optJSONArray("snapshots") ?: JSONArray()
        val subscriptions = payload.optJSONArray("subscriptions") ?: JSONArray()
        val secret = JSONObject()
            .put("apiToken", "demo-token")
            .put("accountID", "demo-account")
            .toString()
        return try {
            for (index in 0 until connections.length()) {
                val item = connections.getJSONObject(index)
                val providerId = item.getString("providerID")
                val accountId = item.getString("accountID")
                ledger.upsertMembership(MembershipRow(providerId, index))
                val reference = REFERENCE_PREFIX + accountId
                ledger.upsertAccount(
                    AccountRow(
                        accountId = accountId,
                        providerId = providerId,
                        credentialReference = reference,
                        sortIndex = 0,
                    ),
                )
                credentials.save(secret, reference)
            }
            for (index in 0 until snapshots.length()) {
                ledger.insertSnapshot(readSnapshot(snapshots.getJSONObject(index)))
            }
            for (index in 0 until subscriptions.length()) {
                ledger.upsertSubscription(readSubscription(subscriptions.getJSONObject(index)))
            }
            Result.Seeded
        } catch (error: Throwable) {
            Result.Failed(error.message ?: "seed write")
        }
    }

    private fun readSnapshot(json: JSONObject): SnapshotRow {
        return SnapshotRow(
            providerId = json.getString("providerID"),
            accountId = json.optString("accountID"),
            kind = json.getString("kind"),
            source = json.optString("source").ifBlank { "api" },
            currentSpendUsd = json.optStringOrNull("currentSpendUSD"),
            balanceUsd = json.optStringOrNull("balanceUSD"),
            committedMonthlyUsd = json.optStringOrNull("committedMonthlyUSD"),
            chargeDayOfMonth = if (json.has("chargeDayOfMonth")) json.getInt("chargeDayOfMonth") else null,
            freeQuotaUsedRatio = if (json.has("freeQuotaUsedRatio")) json.getDouble("freeQuotaUsedRatio") else null,
            dailyUsdJson = json.optJSONObject("dailyUSD")?.toString(),
            convertedJson = json.optJSONObject("converted")?.toString(),
            walletsJson = json.optJSONArray("wallets")?.toString(),
            spendLinesJson = json.optJSONArray("lines")?.toString(),
            periodStartMillis = json.optLong("periodStart"),
            periodEndMillis = json.optLong("periodEnd"),
            fetchedAtMillis = json.optLong("fetchedAt"),
        )
    }

    private fun readSubscription(json: JSONObject): SubscriptionRow {
        return SubscriptionRow(
            // 演示种子每次重来都是新一批行，随机 id 就够；名字不再是身份。
            id = java.util.UUID.randomUUID().toString(),
            name = json.getString("name"),
            amountUsd = json.getString("amountUSD"),
            period = json.getString("period"),
            anchorYear = json.getInt("anchorYear"),
            anchorMonth = json.getInt("anchorMonth"),
            anchorDay = json.getInt("anchorDay"),
            endYear = json.optIntOrNull("endYear"),
            endMonth = json.optIntOrNull("endMonth"),
            endDay = json.optIntOrNull("endDay"),
            providerId = json.optStringOrNull("providerID"),
            accountId = json.optStringOrNull("accountID"),
            quantity = json.optInt("quantity", 1).coerceAtLeast(1),
        )
    }

    private fun JSONObject.optIntOrNull(key: String): Int? {
        if (!has(key) || isNull(key)) return null
        return optInt(key)
    }

    private fun JSONObject.optStringOrNull(key: String): String? {
        if (!has(key) || isNull(key)) return null
        val value = optString(key)
        return value.takeIf { it.isNotBlank() }
    }
}
