import Foundation
import MeterCore

/// Click2Mail 本月作业费用合计。
///
/// 文档：`GET /molpro/jobs` + `GET /molpro/jobs/{id}/cost`
/// 认证：HTTP Basic（用户名 + 密码）。
///
/// `cost` 是美元。先列作业，再逐个取费用；只计本月作业。
public struct Click2MailBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.click2mail }
    public static let maxJobs = 50

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let username = try RequiredCredential.value(.clientID, in: credential, providerID: .click2mail)
        let password = try RequiredCredential.value(.clientSecret, in: credential, providerID: .click2mail)
        let auth = Self.basicAuthorization(username: username, password: password)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)

        let listData = try await ProviderHTTP.get(
            url: Self.jobsURL,
            headers: [
                "Authorization": auth,
                "Accept": "application/json",
            ],
            client: httpClient,
            providerID: .click2mail
        )
        let list = try ProviderHTTP.decode(JobsEnvelope.self, from: listData, providerID: .click2mail)
        let jobs = Array((list.jobs ?? list.job ?? []).prefix(Self.maxJobs))

        var total = Decimal(0)
        for job in jobs {
            guard let id = job.id else { continue }
            let day = (job.dateSubmitted ?? job.submittedAt ?? job.createdAt)
                .flatMap { BillingDateParser.parse($0, calendar: calendar) }
            if let day, day < window.start || day >= window.nextStart { continue }

            let costData = try await ProviderHTTP.get(
                url: Self.costURL(jobID: id),
                headers: [
                    "Authorization": auth,
                    "Accept": "application/json",
                ],
                client: httpClient,
                providerID: .click2mail
            )
            let costPayload = try ProviderHTTP.decode(Cost.self, from: costData, providerID: .click2mail)
            total += costPayload.cost?.value ?? 0
        }

        return Snapshot(
            providerID: .click2mail,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: total)
        )
    }

    static func basicAuthorization(username: String, password: String) -> String {
        "Basic \(ProviderOAuth.basicValue(id: username, secret: password))"
    }

    static let jobsURL = URL(string: "https://rest.click2mail.com/molpro/jobs")!

    static func costURL(jobID: Int64) -> URL {
        URL(string: "https://rest.click2mail.com/molpro/jobs/\(jobID)/cost")!
    }

    struct JobsEnvelope: Decodable, Sendable {
        var jobs: [Job]?
        /// 有的响应把单数 `job` 当列表用。
        var job: [Job]?
    }

    struct Job: Decodable, Sendable {
        var id: Int64?
        var dateSubmitted: String?
        var submittedAt: String?
        var createdAt: String?
    }

    struct Cost: Decodable, Sendable {
        var cost: FlexibleDecimal?
    }
}
