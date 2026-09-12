import Foundation
import MeterCore
import MeterProviders

package enum ProductSnapshotCodec {
    package static func snapshot(from json: [String: Any]) -> Snapshot? {
        guard
            let providerRaw = json["providerID"] as? String,
            let kindRaw = json["kind"] as? String,
            let kind = ProviderKind(rawValue: kindRaw)
        else {
            return nil
        }
        let accountID = (json["accountID"] as? String).flatMap(UUID.init(uuidString:)).map(AccountID.init(rawValue:))
        let source = SnapshotSource.fromStored(json["source"] as? String)
        // 三个时间任一解不出就整条丢弃（同缺 kind）——静默变 1970-01-01 会把
        // 坏行伪装成一条上古读数，月窗口筛选还会把它当真。
        guard
            let fetchedAt = date(json["fetchedAt"]),
            let periodStart = date(json["periodStart"]),
            let periodEnd = date(json["periodEnd"])
        else {
            return nil
        }
        return Snapshot(
            providerID: ProviderID(rawValue: providerRaw),
            accountID: accountID,
            kind: kind,
            source: source,
            fetchedAt: fetchedAt,
            periodStart: periodStart,
            periodEnd: periodEnd,
            currentSpendUSD: money(json["currentSpendUSD"]),
            balanceUSD: money(json["balanceUSD"]),
            committedMonthlyUSD: money(json["committedMonthlyUSD"]),
            chargeDayOfMonth: int(json["chargeDayOfMonth"]),
            freeQuotaUsedRatio: double(json["freeQuotaUsedRatio"]),
            dailyUSD: dailyUSD(json["dailyUSD"]),
            converted: convertedAmount(json["converted"]),
            wallets: wallets(json["wallets"]),
            lines: spendLines(json["lines"])
        )
    }

    /// 换算注记：丢掉它会把换算来的账单当成精确值展示。
    private static func convertedAmount(_ value: Any?) -> ConvertedAmount? {
        guard let raw = value as? [String: Any],
              let currency = raw["currency"] as? String,
              let amount = decimal(raw["amount"]),
              let usdPerUnit = decimal(raw["usdPerUnit"]),
              let usd = decimal(raw["usd"])
        else {
            return nil
        }
        return ConvertedAmount(currency: currency, amount: amount, usdPerUnit: usdPerUnit, usd: usd)
    }

    private static func wallets(_ value: Any?) -> [ConvertedAmount]? {
        guard let raw = value as? [[String: Any]] else { return nil }
        let parsed = raw.compactMap { convertedAmount($0) }
        return parsed.isEmpty ? nil : parsed
    }

    /// {"毫秒": "usd 十进制串"}。有日粒度的几家靠它画真柱，而不是相邻累计做差。
    private static func dailyUSD(_ value: Any?) -> [Date: Money]? {
        guard let raw = value as? [String: Any], !raw.isEmpty else { return nil }
        var result: [Date: Money] = [:]
        for (key, amount) in raw {
            guard let millis = Int64(key), let money = money(amount) else { continue }
            result[ProductClock.date(millis: millis)] = money
        }
        return result.isEmpty ? nil : result
    }

    package static func json(from snapshot: Snapshot) -> [String: Any] {
        var object: [String: Any] = [
            "providerID": snapshot.providerID.rawValue,
            "kind": snapshot.kind.rawValue,
            "source": snapshot.source.rawValue,
            "fetchedAt": Int(ProductClock.millis(snapshot.fetchedAt)),
            "periodStart": Int(ProductClock.millis(snapshot.periodStart)),
            "periodEnd": Int(ProductClock.millis(snapshot.periodEnd)),
        ]
        if let accountID = snapshot.accountID {
            object["accountID"] = accountID.rawValue.uuidString
        }
        if let spend = snapshot.currentSpendUSD {
            object["currentSpendUSD"] = decimalString(spend.usd)
        }
        if let balance = snapshot.balanceUSD {
            object["balanceUSD"] = decimalString(balance.usd)
        }
        if let committed = snapshot.committedMonthlyUSD {
            object["committedMonthlyUSD"] = decimalString(committed.usd)
        }
        if let day = snapshot.chargeDayOfMonth {
            object["chargeDayOfMonth"] = day
        }
        if let ratio = snapshot.freeQuotaUsedRatio {
            object["freeQuotaUsedRatio"] = ratio
        }
        if let daily = snapshot.dailyUSD, !daily.isEmpty {
            var encoded: [String: String] = [:]
            for (day, amount) in daily {
                encoded[String(ProductClock.millis(day))] = decimalString(amount.usd)
            }
            object["dailyUSD"] = encoded
        }
        if let converted = snapshot.converted {
            object["converted"] = json(from: converted)
        }
        if let wallets = snapshot.wallets, !wallets.isEmpty {
            object["wallets"] = wallets.map { json(from: $0) }
        }
        if let lines = snapshot.lines, !lines.isEmpty {
            object["lines"] = lines.map(json(from:))
        }
        return object
    }

    /// 明细数组单独解一份：「花在哪了」那一屏只要 `lines`，不必把整条快照递过来。
    package static func spendLines(fromJSONArray json: String) -> [SpendLine] {
        spendLines(JNIJSON.array(json)) ?? []
    }

    private static func spendLines(_ value: Any?) -> [SpendLine]? {
        guard let raw = value as? [[String: Any]], !raw.isEmpty else { return nil }
        let parsed = raw.compactMap(spendLine(from:))
        return parsed.isEmpty ? nil : parsed
    }

    private static func spendLine(from json: [String: Any]) -> SpendLine? {
        guard let category = json["category"] as? String,
              let label = json["label"] as? String,
              let amount = money(json["amountUSD"])
        else { return nil }
        return SpendLine(
            category: category,
            label: label,
            scope: json["scope"] as? String,
            amountUSD: amount,
            listUSD: money(json["listUSD"]),
            quantity: decimal(json["quantity"]),
            unit: json["unit"] as? String,
            allowanceNote: json["allowanceNote"] as? String
        )
    }

    private static func json(from line: SpendLine) -> [String: Any] {
        var object: [String: Any] = [
            "category": line.category,
            "label": line.label,
            "amountUSD": decimalString(line.amountUSD.usd),
        ]
        if let scope = line.scope { object["scope"] = scope }
        if let list = line.listUSD { object["listUSD"] = decimalString(list.usd) }
        if let quantity = line.quantity { object["quantity"] = decimalString(quantity) }
        if let unit = line.unit { object["unit"] = unit }
        if let note = line.allowanceNote { object["allowanceNote"] = note }
        return object
    }

    private static func json(from converted: ConvertedAmount) -> [String: Any] {
        [
            "currency": converted.currency,
            "amount": decimalString(converted.amount),
            "usdPerUnit": decimalString(converted.usdPerUnit),
            "usd": decimalString(converted.usd),
        ]
    }

    package static func subscription(from json: [String: Any], calendar: Calendar) -> MonthlySubscription? {
        guard
            let name = json["name"] as? String,
            let amount = money(json["amountUSD"]),
            let periodRaw = json["period"] as? String,
            let period = SubscriptionPeriod(rawValue: periodRaw),
            let year = int(json["anchorYear"]),
            let month = int(json["anchorMonth"]),
            let day = int(json["anchorDay"])
        else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        guard let anchor = calendar.date(from: components) else { return nil }
        let accountID = (json["accountID"] as? String).flatMap(UUID.init(uuidString:)).map(AccountID.init(rawValue:))
        let providerID = (json["providerID"] as? String).map(ProviderID.init(rawValue:))
        return MonthlySubscription(
            name: name,
            amount: amount,
            period: period,
            anchorDate: anchor,
            endDate: endDate(from: json, calendar: calendar),
            accountID: accountID,
            providerID: providerID,
            quantity: int(json["quantity"]) ?? 1
        )
    }

    /// 退订那个月。三个分量缺一就是「还在付」——半条记录不猜日期。
    /// 漏接这三个键，Android 上退掉的订阅会一直扣下去。
    private static func endDate(from json: [String: Any], calendar: Calendar) -> Date? {
        guard
            let year = int(json["endYear"]),
            let month = int(json["endMonth"]),
            let day = int(json["endDay"])
        else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)
    }

    package static func json(from subscription: MonthlySubscription, calendar: Calendar) -> [String: Any] {
        let components = calendar.dateComponents([.year, .month, .day], from: subscription.anchorDate)
        var object: [String: Any] = [
            "name": subscription.name,
            "amountUSD": decimalString(subscription.amount.usd),
            "period": subscription.period.rawValue,
            "anchorYear": components.year ?? 0,
            "anchorMonth": components.month ?? 0,
            "anchorDay": components.day ?? 0,
            "quantity": subscription.quantity,
        ]
        if let accountID = subscription.accountID {
            object["accountID"] = accountID.rawValue.uuidString
        }
        if let endDate = subscription.endDate {
            let end = calendar.dateComponents([.year, .month, .day], from: endDate)
            object["endYear"] = end.year ?? 0
            object["endMonth"] = end.month ?? 0
            object["endDay"] = end.day ?? 0
        }
        if let providerID = subscription.providerID {
            object["providerID"] = providerID.rawValue
        }
        return object
    }

    package static func credentialFields(_ json: [String: Any]) -> [CredentialField: String] {
        var fields: [CredentialField: String] = [:]
        for (key, value) in json {
            guard let field = CredentialField(rawValue: key) else { continue }
            let text: String
            if let string = value as? String {
                text = string
            } else {
                text = "\(value)"
            }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                fields[field] = trimmed
            }
        }
        return fields
    }

    private static func date(_ value: Any?) -> Date? {
        if let millis = value as? Int64 {
            return ProductClock.date(millis: millis)
        }
        if let number = value as? NSNumber {
            return ProductClock.date(millis: number.int64Value)
        }
        if let string = value as? String, let millis = Int64(string) {
            return ProductClock.date(millis: millis)
        }
        return nil
    }

    private static func money(_ value: Any?) -> Money? {
        guard let decimal = decimal(value) else { return nil }
        return Money(usd: decimal)
    }

    private static func decimal(_ value: Any?) -> Decimal? {
        switch value {
        case let string as String:
            return Decimal(string: string)
        case let number as NSNumber:
            return Decimal(string: number.stringValue)
        default:
            return nil
        }
    }

    private static func int(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string)
        default:
            return nil
        }
    }

    private static func double(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }

    package static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}
