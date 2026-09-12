import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore
import MeterProviders

package enum ProductFetch {
    package static func json(
        providerIDRaw: String,
        fieldsJSON: String,
        nowMillis: Int64
    ) -> String {
        let providerID = ProviderID(rawValue: providerIDRaw)
        let calendar = ProductClock.calendar()
        let now = ProductClock.date(millis: nowMillis)
        do {
            let snapshot = try fetch(
                providerID: providerID,
                fields: ProductSnapshotCodec.credentialFields(JNIJSON.object(fieldsJSON)),
                now: now,
                calendar: calendar
            )
            var object = ProductSnapshotCodec.json(from: snapshot)
            object["ok"] = true
            if let spend = snapshot.currentSpendUSD {
                object["spend"] = spend.formatted()
            } else if let balance = snapshot.balanceUSD {
                object["spend"] = balance.formatted()
            } else if let committed = snapshot.committedMonthlyUSD {
                object["spend"] = committed.formatted()
            } else if let ratio = snapshot.freeQuotaUsedRatio {
                object["spend"] = "\(Int((ratio * 100).rounded()))%"
            }
            return JNIJSON.stringify(object)
        } catch {
            return JNIJSON.stringify([
                "ok": false,
                "providerID": providerIDRaw,
                "error": String(describing: error),
            ])
        }
    }

    package static func fetch(
        providerID: ProviderID,
        fields: [CredentialField: String],
        now: Date,
        calendar: Calendar
    ) throws -> Snapshot {
        guard let provider = ProviderAssembly.liveProvider(
            id: providerID,
            now: { now },
            calendar: calendar,
            httpClient: LiveHTTPTransport.make(),
            rateSource: SharedExchangeRates(ProductRates.bundled)
        ) else {
            throw ProviderError.fixtureUnavailable(providerID: providerID)
        }
        let credential = Credential(providerID: providerID, fields: fields)
        return try JNIAsync.run {
            try await provider.fetch(credential: credential)
        }
    }
}
