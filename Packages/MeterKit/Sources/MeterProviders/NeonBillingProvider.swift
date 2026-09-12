import Foundation
import MeterCore

/// Neon Consumption History v2。
///
/// 文档：`GET /api/v2/consumption_history/v2/projects`
/// 认证：`Authorization: Bearer <API Key>`
/// 组织：`GET /api/v2/users/me/organizations`，或凭据里的 `accountID` 当 `org_id`。
///
/// API 只给用量。美元按官方 Usage and cost calculations 页的公式算，**不是汇率换算**。
public struct NeonBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.neon }
    static let maxConsumptionPages = 20

    public static let metricNames = [
        "compute_unit_seconds",
        "root_branch_bytes_month",
        "child_branch_bytes_month",
        "instant_restore_bytes_month",
        "snapshot_storage_bytes_month",
        "public_network_transfer_bytes",
        "private_network_transfer_bytes",
        "extra_branches_month",
    ]

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .neon)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
        ]
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)

        // 钉死 org 也要拉 organizations——计划名只有这条接口给，
        // 没有计划就没有价目表，宁可失败也不能按 Launch 猜钱。
        let allOrgs = try await loadOrganizations(headers: headers)
        let orgs: [Organization]
        if let pinned = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !pinned.isEmpty {
            guard let match = allOrgs.first(where: { $0.id == pinned }) else {
                throw ProviderError.malformedResponse(providerID: .neon)
            }
            orgs = [match]
        } else {
            orgs = allOrgs
        }

        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var transferCost = Decimal(0)

        for org in orgs {
            // 认不出套餐就是算不出钱。不要用任何计划当缺省价目。
            guard let pricing = NeonPlanPricing.parse(org.plan) else {
                throw ProviderError.malformedResponse(providerID: .neon)
            }
            if pricing == .free {
                // 待核对：v2 consumption 对 Free 计划会 403。这里按 $0 计，不打那条接口。
                continue
            }

            // 传输量按 org 单独攒：免费额度要用**这个** org 的计划去减。
            // 攒成一张跨 org 的表、最后拿某一个计划的价目表套全部，多 org
            // 且计划不同时算出来的是另一个数。
            var publicTransferByProject: [String: Decimal] = [:]
            var seenProjects: Set<String> = []
            var cursor: String?
            var seenCursors: Set<String> = []
            var pages = 0
            while true {
                pages += 1
                let page = try await loadConsumption(
                    orgID: org.id,
                    cursor: cursor,
                    window: window,
                    granularity: "daily",
                    headers: headers
                )
                accumulate(
                    page: page,
                    pricing: pricing,
                    calendar: calendar,
                    into: &daily,
                    lines: &lines,
                    publicTransferByProject: &publicTransferByProject,
                    seenProjects: &seenProjects
                )
                if page.projects?.isEmpty != false { break }
                // 游标没往前走就停：Cloudflare 那次的教训是别替厂商的分页做假设，
                // 原地打转会把同一页累加到 20 遍。
                guard
                    let next = page.pagination?.cursor,
                    !next.isEmpty,
                    seenCursors.insert(next).inserted
                else {
                    break
                }
                // 打满上限还有下一页：截断的合计不是完整账单，宁可失败。
                if pages >= Self.maxConsumptionPages {
                    throw ProviderError.malformedResponse(providerID: .neon)
                }
                cursor = next
            }

            // 公共流量的钱要等整段攒完才算得出来：免费额度是**按项目按月**扣的，
            // 逐个 bucket 加是加不出来的。所以这条明细也只能在这里补，
            // 不能在 `accumulate` 里跟着别的 metric 一起写。
            for (projectID, bytes) in publicTransferByProject {
                let gb = bytes / 1_000_000_000
                let billable = max(0, gb - pricing.publicTransferAllowanceGB)
                let cost = billable * pricing.publicTransferPerGB
                transferCost += cost
                let metric = NeonMetricDisplay.publicNetworkTransferBytes
                lines.add(
                    SpendLine(
                        category: metric.family,
                        label: metric.label,
                        scope: projectID,
                        amountUSD: Money(usd: cost),
                        // 原价是"没有额度的话要收多少"，配上下面那句额度说明，
                        // 才讲得清「用了 1.4 TB 却是 $0」。
                        listUSD: Money(usd: gb * pricing.publicTransferPerGB),
                        quantity: gb,
                        unit: metric.unit,
                        // 这层不 import MeterFormat（依赖方向：Providers 只认 Core）。
                        // 额度是整数 GB，`stringValue` 就够，不值得为它加一条边。
                        allowanceNote: pricing.publicTransferAllowanceGB > 0
                            ? "First \(NSDecimalNumber(decimal: pricing.publicTransferAllowanceGB).stringValue) GB per project included"
                            : nil
                    )
                )
            }
        }

        if transferCost > 0 {
            daily.add(day: window.start, amount: Money(usd: transferCost))
        }

        if horizon == .availableHistory {
            let past = CalendarMonthWindow.spanning(
                for: .availableHistory,
                lookbackMonths: Self.descriptor.historyLookbackMonths,
                now: now,
                calendar: calendar
            )
            // monthly 覆盖到本月月初为止，避免和上面 daily 本月重叠双计。
            let pastWindow = CalendarMonthWindow(
                start: past.start,
                endInclusive: calendar.date(byAdding: .day, value: -1, to: window.start) ?? past.endInclusive,
                nextStart: window.start
            )
            if pastWindow.start < window.start {
                for org in orgs {
                    guard let pricing = NeonPlanPricing.parse(org.plan), pricing != .free else { continue }
                    try await loadMonthlyHistory(
                        orgID: org.id,
                        pricing: pricing,
                        window: pastWindow,
                        headers: headers,
                        into: &daily
                    )
                }
            }
        }

        return Snapshot(
            providerID: .neon,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: daily.total(in: window, calendar: calendar),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        )
    }

    private func loadOrganizations(headers: [String: String]) async throws -> [Organization] {
        let data = try await ProviderHTTP.get(
            url: Self.organizationsURL,
            headers: headers,
            client: httpClient,
            providerID: .neon
        )
        let payload = try ProviderHTTP.decode(OrganizationsEnvelope.self, from: data, providerID: .neon)
        return payload.organizations ?? []
    }

    private func loadMonthlyHistory(
        orgID: String,
        pricing: NeonPlanPricing,
        window: CalendarMonthWindow,
        headers: [String: String],
        into daily: inout DailySpendAccumulator
    ) async throws {
        var cursor: String?
        var seenCursors: Set<String> = []
        var pages = 0
        var dummyLines = SpendLineAccumulator()
        var publicTransferByProject: [String: Decimal] = [:]
        var seenProjects: Set<String> = []
        while true {
            pages += 1
            let page = try await loadConsumption(
                orgID: orgID,
                cursor: cursor,
                window: window,
                granularity: "monthly",
                headers: headers
            )
            accumulate(
                page: page,
                pricing: pricing,
                calendar: calendar,
                into: &daily,
                lines: &dummyLines,
                publicTransferByProject: &publicTransferByProject,
                seenProjects: &seenProjects,
                includeLines: false
            )
            if page.projects?.isEmpty != false { break }
            guard
                let next = page.pagination?.cursor,
                !next.isEmpty,
                seenCursors.insert(next).inserted
            else {
                break
            }
            if pages >= Self.maxConsumptionPages {
                throw ProviderError.malformedResponse(providerID: .neon)
            }
            cursor = next
        }
    }

    private func loadConsumption(
        orgID: String,
        cursor: String?,
        window: CalendarMonthWindow,
        granularity: String,
        headers: [String: String]
    ) async throws -> ConsumptionEnvelope {
        let url = Self.consumptionURL(
            orgID: orgID,
            cursor: cursor,
            window: window,
            granularity: granularity
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .neon
        )
        return try ProviderHTTP.decode(ConsumptionEnvelope.self, from: data, providerID: .neon)
    }

    private func accumulate(
        page: ConsumptionEnvelope,
        pricing: NeonPlanPricing,
        calendar: Calendar,
        into daily: inout DailySpendAccumulator,
        lines: inout SpendLineAccumulator,
        publicTransferByProject: inout [String: Decimal],
        seenProjects: inout Set<String>,
        includeLines: Bool = true
    ) {
        let now = now()
        for project in page.projects ?? [] {
            let projectID = project.project_id ?? "unknown"
            // 分页是按 project 切的，同一个 project 不该出现在两页里。真出现了
            // 就是厂商的游标没往前走——认 id 丢掉，别把它的用量加第二遍。
            // 没有 project_id 的不参与去重，否则几个匿名 project 会互相顶掉。
            if project.project_id != nil, !seenProjects.insert(projectID).inserted { continue }
            for period in project.periods ?? [] {
                let periodPricing = NeonPlanPricing.parse(period.period_plan) ?? pricing
                for bucket in period.consumption ?? [] {
                    let start = bucket.timeframe_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? CalendarMonthWindow.current(now: now, calendar: calendar).start
                    let end = bucket.timeframe_end.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    let hours: Decimal
                    if let end {
                        let seconds = end.timeIntervalSince(start)
                        hours = Decimal(max(seconds / 3600, 1))
                    } else {
                        hours = 24
                    }
                    for metric in bucket.metrics ?? [] {
                        guard let name = metric.metric_name, let raw = metric.value?.value else { continue }
                        if name == "public_network_transfer_bytes" {
                            publicTransferByProject[projectID, default: 0] += raw
                            continue
                        }
                        let usd = periodPricing.costUSD(metric: name, rawValue: raw, hoursInBucket: hours)
                        if usd != 0 {
                            daily.add(day: start, amount: Money(usd: usd))
                        }
                        // 认不出的 metric 不进明细：给不出单位和名字的行，
                        // 界面上就是一条"某某 $0"，不如没有。它的钱照样在日线里。
                        guard includeLines, let display = NeonMetricDisplay(rawValue: name) else { continue }
                        lines.add(
                            SpendLine(
                                category: display.family,
                                label: display.label,
                                scope: project.project_id,
                                amountUSD: Money(usd: usd),
                                quantity: display.quantity(from: raw),
                                unit: display.unit
                            )
                        )
                    }
                }
            }
        }
    }

    static let organizationsURL = URL(string: "https://console.neon.tech/api/v2/users/me/organizations")!

    static func consumptionURL(
        orgID: String,
        cursor: String?,
        window: CalendarMonthWindow,
        granularity: String = "daily"
    ) -> URL {
        var items = [
            URLQueryItem(name: "from", value: window.rfc3339(window.start)),
            URLQueryItem(name: "to", value: window.rfc3339(window.nextStart)),
            URLQueryItem(name: "granularity", value: granularity),
            URLQueryItem(name: "org_id", value: orgID),
            URLQueryItem(name: "metrics", value: metricNames.joined(separator: ",")),
            URLQueryItem(name: "limit", value: "100"),
        ]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return ProviderURL.https(host: "console.neon.tech", path: "/api/v2/consumption_history/v2/projects", query: items)
    }

    struct OrganizationsEnvelope: Decodable, Sendable {
        var organizations: [Organization]?
    }

    struct Organization: Decodable, Sendable {
        var id: String
        var plan: String?
    }

    struct ConsumptionEnvelope: Decodable, Sendable {
        var projects: [Project]?
        var pagination: Pagination?
    }

    struct Pagination: Decodable, Sendable {
        var cursor: String?
    }

    struct Project: Decodable, Sendable {
        var project_id: String?
        var periods: [Period]?
    }

    struct Period: Decodable, Sendable {
        var period_plan: String?
        var consumption: [Bucket]?
    }

    struct Bucket: Decodable, Sendable {
        var timeframe_start: String?
        var timeframe_end: String?
        var metrics: [Metric]?
    }

    struct Metric: Decodable, Sendable {
        var metric_name: String?
        var value: FlexibleDecimal?
    }
}
