#if DEBUG
import Foundation
import MeterProviders

enum DeveloperRefreshLogSearch {
    static func filtered(exchanges: [HTTPExchange], query: String) -> [HTTPExchange] {
        let needle = normalizedQuery(query)
        if needle.isEmpty { return exchanges }
        return exchanges.filter { matches($0, needle: needle) }
    }

    static func showsEmptySearch(exchanges: [HTTPExchange], query: String) -> Bool {
        !normalizedQuery(query).isEmpty
            && !exchanges.isEmpty
            && filtered(exchanges: exchanges, query: query).isEmpty
    }

    static func normalizedQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(_ exchange: HTTPExchange, needle: String) -> Bool {
        exchange.summary.localizedStandardContains(needle)
            || exchange.body.localizedStandardContains(needle)
    }
}
#endif
