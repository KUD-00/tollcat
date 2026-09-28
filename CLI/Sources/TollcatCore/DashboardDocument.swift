import Foundation
import MeterBridge

struct DashboardComposition: Equatable, Sendable {
    var displayName: String
    var amount: String
    var percent: Int
}

struct DashboardDocument: Equatable, Sendable {
    var empty: Bool
    var rawJSON: String
    var formattedVariable: String
    var formattedProjected: String
    var monthTitle: String
    var comparisonCaption: String?
    var comparisonPercentText: String?
    var comparisonTone: String?
    var staleCaption: String?
    var currencyNote: String?
    var subscriptionCaption: String?
    var composition: [DashboardComposition]

    static func parse(_ json: String) -> DashboardDocument {
        let object = JNIJSON.object(json)
        let rows = object["composition"] as? [[String: Any]] ?? []
        return DashboardDocument(
            empty: object["empty"] as? Bool ?? false,
            rawJSON: json,
            formattedVariable: object["formattedVariable"] as? String
                ?? object["formattedTotal"] as? String
                ?? "",
            formattedProjected: object["formattedProjected"] as? String ?? "",
            monthTitle: object["monthTitle"] as? String ?? "",
            comparisonCaption: string(object["comparisonCaption"]),
            comparisonPercentText: string(object["comparisonPercentText"]),
            comparisonTone: string(object["comparisonTone"]),
            staleCaption: string(object["staleCaption"]),
            currencyNote: string(object["currencyNote"]),
            subscriptionCaption: string(object["subscriptionCaption"]),
            composition: rows.compactMap { row in
                guard let name = row["displayName"] as? String else { return nil }
                let percent: Int
                if let number = row["percent"] as? Int {
                    percent = number
                } else if let number = row["percent"] as? NSNumber {
                    percent = number.intValue
                } else {
                    percent = 0
                }
                return DashboardComposition(
                    displayName: name,
                    amount: row["amount"] as? String ?? "",
                    percent: percent
                )
            }
        )
    }

    private static func string(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return string
    }
}
