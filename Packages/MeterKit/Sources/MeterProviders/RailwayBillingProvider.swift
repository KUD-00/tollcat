import Foundation
import MeterCore

/// Railway workspace 本周期账单。
///
/// 官方 GraphQL：`workspace.customer.currentUsage`（美元）。
/// 这是 Railway CLI `railway usage` 的同一条读数，不按单价手算。
/// 认证：Account / Workspace token。Workspace ID 从控制台复制。
public struct RailwayBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.railway }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .railway)
        let workspaceID = try RequiredCredential.value(.accountID, in: credential, providerID: .railway)
        let payload = try await ProviderGraphQL.query(
            UsageData.self,
            url: Self.graphqlURL,
            query: Self.usageQuery,
            variables: ["workspaceId": workspaceID],
            headers: [
                "Authorization": "Bearer \(token)",
            ],
            client: httpClient,
            providerID: .railway
        )
        guard let usage = payload.workspace?.customer?.currentUsage?.value else {
            throw ProviderError.malformedResponse(providerID: .railway)
        }
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let billing = payload.workspace?.customer?.billingPeriod
        let period = BillingPeriodResolver.resolve(
            startRaw: billing?.start,
            endRaw: billing?.end,
            endConvention: .exclusiveWhenMonthStart,
            fallback: window,
            calendar: calendar
        )
        return Snapshot(
            providerID: .railway,
            kind: .usage,
            fetchedAt: now,
            periodStart: period.start,
            periodEnd: period.end,
            currentSpendUSD: Money(usd: usage)
        )
    }

    static let graphqlURL = URL(string: "https://backboard.railway.com/graphql/v2")!

    static let usageQuery = """
    query WorkspaceUsageContext($workspaceId: String!) {
      workspace(workspaceId: $workspaceId) {
        customer {
          currentUsage
          billingPeriod {
            start
            end
          }
        }
      }
    }
    """

    struct UsageData: Decodable, Sendable {
        var workspace: Workspace?
    }

    struct Workspace: Decodable, Sendable {
        var customer: Customer?
    }

    struct Customer: Decodable, Sendable {
        var currentUsage: FlexibleDecimal?
        var billingPeriod: BillingPeriod?
    }

    struct BillingPeriod: Decodable, Sendable {
        var start: String?
        var end: String?
    }
}
