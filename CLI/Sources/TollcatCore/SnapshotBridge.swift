import Foundation
import MeterBridge

enum SnapshotBridge {
    static func ledgerRow(from fetchObject: [String: Any], accountID: String) -> LedgerSnapshot? {
        guard let providerID = fetchObject["providerID"] as? String else { return nil }
        let resolvedAccount = (fetchObject["accountID"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? accountID
        return LedgerSnapshot(
            providerId: providerID,
            accountId: resolvedAccount,
            kind: fetchObject["kind"] as? String ?? "usage",
            source: fetchObject["source"] as? String ?? "api",
            currentSpendUsd: string(fetchObject["currentSpendUSD"]),
            balanceUsd: string(fetchObject["balanceUSD"]),
            committedMonthlyUsd: string(fetchObject["committedMonthlyUSD"]),
            chargeDayOfMonth: int(fetchObject["chargeDayOfMonth"]),
            freeQuotaUsedRatio: double(fetchObject["freeQuotaUsedRatio"]),
            dailyUsdJson: rawJSON(fetchObject["dailyUSD"]),
            convertedJson: rawJSON(fetchObject["converted"]),
            walletsJson: rawJSON(fetchObject["wallets"]),
            periodStartMillis: millis(fetchObject["periodStart"]),
            periodEndMillis: millis(fetchObject["periodEnd"]),
            fetchedAtMillis: millis(fetchObject["fetchedAt"])
        )
    }

    static func bridgeObject(from row: LedgerSnapshot) -> [String: Any] {
        var object: [String: Any] = [
            "providerID": row.providerId,
            "accountID": row.accountId,
            "kind": row.kind,
            "source": row.source,
            "fetchedAt": row.fetchedAtMillis,
            "periodStart": row.periodStartMillis,
            "periodEnd": row.periodEndMillis,
        ]
        if let value = row.currentSpendUsd { object["currentSpendUSD"] = value }
        if let value = row.balanceUsd { object["balanceUSD"] = value }
        if let value = row.committedMonthlyUsd { object["committedMonthlyUSD"] = value }
        if let value = row.chargeDayOfMonth { object["chargeDayOfMonth"] = value }
        if let value = row.freeQuotaUsedRatio { object["freeQuotaUsedRatio"] = value }
        if let value = row.dailyUsdJson, let parsed = JNIJSON.parse(value) {
            object["dailyUSD"] = parsed
        }
        if let value = row.convertedJson, let parsed = JNIJSON.parse(value) {
            object["converted"] = parsed
        }
        if let value = row.walletsJson, let parsed = JNIJSON.parse(value) {
            object["wallets"] = parsed
        }
        return object
    }

    static func subscriptionObject(from row: LedgerSubscription) -> [String: Any] {
        var object: [String: Any] = [
            "name": row.name,
            "amountUSD": row.amountUsd,
            "period": row.period,
            "anchorYear": row.anchorYear,
            "anchorMonth": row.anchorMonth,
            "anchorDay": row.anchorDay,
        ]
        if let value = row.providerId { object["providerID"] = value }
        if let value = row.accountId { object["accountID"] = value }
        return object
    }

    private static func string(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private static func int(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    private static func double(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) }
        return nil
    }

    private static func millis(_ value: Any?) -> Int64 {
        if let number = value as? NSNumber { return number.int64Value }
        if let string = value as? String, let parsed = Int64(string) { return parsed }
        return 0
    }

    private static func rawJSON(_ value: Any?) -> String? {
        guard let value, JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value),
              let string = String(data: data, encoding: .utf8)
        else {
            if let string = value as? String { return string }
            return nil
        }
        return string
    }
}
