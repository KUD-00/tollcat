import Foundation
import MeterBridge

struct CatalogDocument: Equatable, Sendable {
    var providers: [CatalogProvider]
    var currencies: [String]

    static func load(localeTag: String) -> CatalogDocument {
        parse(ProductCatalog.json(localeTag: localeTag))
    }

    static func parse(_ json: String) -> CatalogDocument {
        let object = JNIJSON.object(json)
        let raw = object["providers"] as? [[String: Any]] ?? []
        let providers = raw.compactMap(provider(from:))
        let currencies = object["currencies"] as? [String] ?? ["USD"]
        return CatalogDocument(providers: providers, currencies: currencies)
    }

    func match(_ query: String) -> CatalogProvider? {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty { return nil }
        if let exact = providers.first(where: { $0.id.lowercased() == needle }) {
            return exact
        }
        if let named = providers.first(where: { $0.displayName.lowercased() == needle }) {
            return named
        }
        return providers.first { provider in
            provider.searchKeywords.contains { $0.lowercased() == needle }
        }
    }

    var offered: [CatalogProvider] {
        providers.filter(\.isOffered)
    }

    private static func provider(from json: [String: Any]) -> CatalogProvider? {
        guard let id = json["id"] as? String else { return nil }
        let fields = (json["fields"] as? [[String: Any]] ?? []).compactMap { field -> CatalogField? in
            guard let key = field["key"] as? String else { return nil }
            return CatalogField(
                key: key,
                label: field["label"] as? String ?? key,
                isSecret: field["isSecret"] as? Bool ?? false,
                hint: field["hint"] as? String ?? ""
            )
        }
        return CatalogProvider(
            id: id,
            displayName: json["displayName"] as? String ?? id,
            kind: json["kind"] as? String ?? "",
            summary: json["summary"] as? String ?? "",
            accessStatus: json["accessStatus"] as? String ?? "available",
            declineReason: json["declineReason"] as? String ?? "",
            hasLiveFetch: json["hasLiveFetch"] as? Bool ?? false,
            costsMoneyToRefresh: json["costsMoneyToRefresh"] as? Bool ?? false,
            minimumRefreshInterval: json["minimumRefreshInterval"] as? Int
                ?? (json["minimumRefreshInterval"] as? NSNumber)?.intValue
                ?? 0,
            credentialSetupURL: json["credentialSetupURL"] as? String ?? "",
            fields: fields,
            searchKeywords: json["searchKeywords"] as? [String] ?? []
        )
    }
}
