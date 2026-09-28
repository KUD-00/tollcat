struct LedgerSnapshot: Codable, Equatable, Sendable {
    var providerId: String
    var accountId: String
    var kind: String
    var source: String
    var currentSpendUsd: String?
    var balanceUsd: String?
    var committedMonthlyUsd: String?
    var chargeDayOfMonth: Int?
    var freeQuotaUsedRatio: Double?
    var dailyUsdJson: String?
    var convertedJson: String?
    var walletsJson: String?
    var periodStartMillis: Int64
    var periodEndMillis: Int64
    var fetchedAtMillis: Int64
}
