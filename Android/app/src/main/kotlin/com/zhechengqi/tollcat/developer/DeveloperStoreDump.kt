package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.LedgerStore
import org.json.JSONArray
import org.json.JSONObject

object DeveloperStoreDump {
    fun json(ledger: LedgerStore): String {
        val snapshots = JSONArray()
        for (row in ledger.snapshots()) {
            snapshots.put(
                JSONObject().apply {
                    put("providerID", row.providerId)
                    put("accountID", row.accountId)
                    put("kind", row.kind)
                    put("fetchedAt", row.fetchedAtMillis)
                    put("periodStart", row.periodStartMillis)
                    put("periodEnd", row.periodEndMillis)
                    row.currentSpendUsd?.let { put("currentSpendUSD", it) }
                    row.balanceUsd?.let { put("balanceUSD", it) }
                    row.committedMonthlyUsd?.let { put("committedMonthlyUSD", it) }
                    row.chargeDayOfMonth?.let { put("chargeDayOfMonth", it) }
                    row.freeQuotaUsedRatio?.let { put("freeQuotaUsedRatio", it) }
                },
            )
        }
        val subscriptions = JSONArray()
        for (row in ledger.subscriptions()) {
            subscriptions.put(
                JSONObject().apply {
                    put("name", row.name)
                    put("amountUSD", row.amountUsd)
                    put("period", row.period)
                    row.providerId?.let { put("providerID", it) }
                    row.accountId?.let { put("accountID", it) }
                },
            )
        }
        val connections = JSONArray()
        for (row in ledger.accounts()) {
            connections.put(
                JSONObject().apply {
                    put("providerID", row.providerId)
                    put("accountID", row.accountId)
                    put("credentialReference", row.credentialReference)
                },
            )
        }
        return JSONObject()
            .put("snapshots", snapshots)
            .put("subscriptions", subscriptions)
            .put("connections", connections)
            .toString(2)
    }
}
