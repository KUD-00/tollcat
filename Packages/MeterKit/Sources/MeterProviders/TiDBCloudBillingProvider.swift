import Foundation
import MeterCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// TiDB Cloud 月账单（`GET /v1beta1/bills/{YYYY-MM}` + `billsDetails`）。
///
/// 文档：https://docs.pingcap.com/tidbcloud/api/v1beta1/billing/
/// 认证：HTTP Digest（public key = `accessKeyID`，private key = `secretAccessKey`）。
/// Host：`billing.tidbapi.com`。金额为美分字符串（`totalCost` / `runningTotal`）÷ 100 → USD。
/// 优先 `overview.totalCost`（应付）；`billsDetails` 填日线。可查近 6 个月。
public struct TiDBCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.tidbcloud }
    public static let apiHost = "billing.tidbapi.com"
    static let maxHistoryMonths = 6

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let publicKey = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .tidbcloud)
        let privateKey = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .tidbcloud)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: min(Self.descriptor.historyLookbackMonths, Self.maxHistoryMonths),
            now: now,
            calendar: calendar
        )
        let windows: [CalendarMonthWindow] = horizon == .availableHistory ? months : [current]

        var currencies = CurrencyAccumulator()
        try currencies.observe("USD", providerID: .tidbcloud)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for window in windows {
            let ym = Self.yearMonth(window.start, calendar: calendar)
            let billURL = ProviderURL.https(host: Self.apiHost, path: "/v1beta1/bills/\(ym)")
            let billData = try await DigestAuth.get(
                url: billURL,
                username: publicKey,
                password: privateKey,
                client: httpClient,
                providerID: .tidbcloud
            )
            let bill = try ProviderHTTP.decode(BillsExplorer.self, from: billData, providerID: .tidbcloud)
            let overview = bill.overview
            let cents = Self.cents(overview?.totalCost)
                ?? Self.cents(overview?.runningTotal)
                ?? 0
            let dollars = cents / 100

            if window.start == current.start {
                currentTotal = dollars
                if dollars != 0 {
                    daily.add(day: current.start, amount: Money(usd: dollars))
                }
                for svc in bill.summaryByService ?? [] {
                    let svcCents = Self.cents(svc.totalCost) ?? Self.cents(svc.runningTotal) ?? 0
                    let svcUSD = svcCents / 100
                    guard svcUSD != 0 else { continue }
                    lines.add(
                        SpendLine(
                            category: "service",
                            label: svc.serviceName ?? "service",
                            amountUSD: Money(usd: svcUSD)
                        )
                    )
                }
                for project in bill.summaryByProject?.projects ?? [] {
                    let pCents = Self.cents(project.totalCost) ?? Self.cents(project.runningTotal) ?? 0
                    let pUSD = pCents / 100
                    guard pUSD != 0 else { continue }
                    lines.add(
                        SpendLine(
                            category: "project",
                            label: project.projectName ?? "project",
                            amountUSD: Money(usd: pUSD)
                        )
                    )
                }
            } else if horizon == .availableHistory, dollars != 0 {
                daily.addPastMonth(
                    start: window.start,
                    amount: Money(usd: dollars),
                    current: current,
                    calendar: calendar
                )
            }

            // Daily details (optional; fills day buckets)
            let detailsURL = ProviderURL.https(host: Self.apiHost, path: "/v1beta1/billsDetails/\(ym)")
            if let detailsData = try? await DigestAuth.get(
                url: detailsURL,
                username: publicKey,
                password: privateKey,
                client: httpClient,
                providerID: .tidbcloud
            ), let details = try? ProviderHTTP.decode(BillsDetails.self, from: detailsData, providerID: .tidbcloud) {
                for row in details.details ?? [] {
                    let rowCents = Self.cents(row.totalCost) ?? Self.cents(row.runningTotal) ?? 0
                    let rowUSD = rowCents / 100
                    guard rowUSD != 0 else { continue }
                    let day = row.billedDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? window.start
                    if window.start == current.start {
                        daily.add(day: day, amount: Money(usd: rowUSD))
                    }
                }
            }
        }

        return try Snapshot(
            providerID: .tidbcloud,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    static func yearMonth(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    static func cents(_ raw: String?) -> Decimal? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
              let value = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        return value
    }

    struct BillsExplorer: Decodable, Sendable {
        var overview: Overview?
        var summaryByProject: SummaryByProject?
        var summaryByService: [ServiceCost]?
    }

    struct Overview: Decodable, Sendable {
        var billedMonth: String?
        var credits: String?
        var discounts: String?
        var runningTotal: String?
        var totalCost: String?
    }

    struct SummaryByProject: Decodable, Sendable {
        var projects: [ProjectCost]?
        var otherCharges: [ProjectCost]?
    }

    struct ProjectCost: Decodable, Sendable {
        var projectName: String?
        var otherName: String?
        var credits: String?
        var discounts: String?
        var runningTotal: String?
        var totalCost: String?
    }

    struct ServiceCost: Decodable, Sendable {
        var serviceName: String?
        var credits: String?
        var discounts: String?
        var runningTotal: String?
        var totalCost: String?
    }

    struct BillsDetails: Decodable, Sendable {
        var details: [DetailRow]?
    }

    struct DetailRow: Decodable, Sendable {
        var billedDate: String?
        var projectName: String?
        var clusterName: String?
        var servicePathName: String?
        var credits: String?
        var discounts: String?
        var runningTotal: String?
        var totalCost: String?
    }
}

/// TiDB Cloud HTTP Digest（RFC 7616 / MD5）。`ProviderHTTP.get` 会把 401 直接映射成错误，故用 `client.send` 走挑战。
enum DigestAuth: Sendable {
    static func get(
        url: URL,
        username: String,
        password: String,
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> Data {
        var probe = URLRequest(url: url)
        probe.httpMethod = "GET"
        probe.cachePolicy = .reloadIgnoringLocalCacheData
        probe.setValue("application/json", forHTTPHeaderField: "Accept")
        let probeData: Data
        let probeResponse: HTTPURLResponse
        do {
            (probeData, probeResponse) = try await client.send(probe)
        } catch let error as ProviderError {
            throw error
        } catch {
            throw ProviderError.networkFailure(providerID: providerID)
        }
        if probeResponse.statusCode == 200 {
            return probeData
        }
        guard probeResponse.statusCode == 401,
              let challenge = probeResponse.value(forHTTPHeaderField: "WWW-Authenticate"),
              let auth = authorization(
                challenge: challenge,
                method: "GET",
                url: url,
                username: username,
                password: password
              ) else {
            if let mapped = ProviderError.fromHTTPStatus(probeResponse.statusCode, providerID: providerID) {
                throw mapped
            }
            throw ProviderError.malformedResponse(providerID: providerID)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(auth, forHTTPHeaderField: "Authorization")
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.send(request)
        } catch let error as ProviderError {
            throw error
        } catch {
            throw ProviderError.networkFailure(providerID: providerID)
        }
        if let mapped = ProviderError.fromHTTPStatus(response.statusCode, providerID: providerID) {
            throw mapped
        }
        return data
    }

    static func authorization(
        challenge: String,
        method: String,
        url: URL,
        username: String,
        password: String
    ) -> String? {
        let params = parseChallenge(challenge)
        guard let realm = params["realm"], let nonce = params["nonce"] else { return nil }
        let qop = params["qop"]?.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.first { $0 == "auth" || $0 == "auth-int" } ?? params["qop"]
        let opaque = params["opaque"]
        let algorithm = params["algorithm"] ?? "MD5"
        guard algorithm.uppercased().hasPrefix("MD5") else { return nil }
        let uri = url.path.isEmpty ? "/" : url.path
        let uriWithQuery: String
        if let query = url.query, !query.isEmpty {
            uriWithQuery = "\(uri)?\(query)"
        } else {
            uriWithQuery = uri
        }
        let ha1 = md5Hex("\(username):\(realm):\(password)")
        let ha2 = md5Hex("\(method):\(uriWithQuery)")
        let nc = "00000001"
        let cnonce = String(format: "%08x%08x", UInt32.random(in: 0...UInt32.max), UInt32.random(in: 0...UInt32.max))
        let response: String
        if let qop, !qop.isEmpty {
            response = md5Hex("\(ha1):\(nonce):\(nc):\(cnonce):\(qop):\(ha2)")
        } else {
            response = md5Hex("\(ha1):\(nonce):\(ha2)")
        }
        var parts = [
            "Digest username=\"\(username)\"",
            "realm=\"\(realm)\"",
            "nonce=\"\(nonce)\"",
            "uri=\"\(uriWithQuery)\"",
            "response=\"\(response)\"",
        ]
        if let qop, !qop.isEmpty {
            parts.append("qop=\(qop)")
            parts.append("nc=\(nc)")
            parts.append("cnonce=\"\(cnonce)\"")
        }
        if let opaque, !opaque.isEmpty {
            parts.append("opaque=\"\(opaque)\"")
        }
        if algorithm != "MD5" {
            parts.append("algorithm=\(algorithm)")
        }
        return parts.joined(separator: ", ")
    }

    static func parseChallenge(_ header: String) -> [String: String] {
        var result: [String: String] = [:]
        guard let range = header.range(of: "Digest", options: [.caseInsensitive]) else { return result }
        let body = header[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        // Split on commas not inside quotes
        var token = ""
        var inQuotes = false
        var tokens: [String] = []
        for ch in body {
            if ch == "\"" {
                inQuotes.toggle()
                token.append(ch)
            } else if ch == "," && !inQuotes {
                tokens.append(token)
                token = ""
            } else {
                token.append(ch)
            }
        }
        if !token.isEmpty { tokens.append(token) }
        for raw in tokens {
            let piece = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let eq = piece.firstIndex(of: "=") else { continue }
            let key = piece[..<eq].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            var value = piece[piece.index(after: eq)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            result[key] = value
        }
        return result
    }

    static func md5Hex(_ string: String) -> String {
        MeterDigest.md5(Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
