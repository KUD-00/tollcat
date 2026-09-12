#if DEBUG
import Testing
import MeterProviders
@testable import MeterFeatures

struct DeveloperRefreshLogSearchTests {
    private let cloudflare = HTTPExchange(
        summary: "GET https://api.cloudflare.com/client/v4/user/billing\nHTTP 200",
        body: #"{"success": true, "result": {"amount": 11.05}}"#
    )
    private let openai = HTTPExchange(
        summary: "GET https://api.openai.com/v1/organization/costs\nHTTP 401",
        body: #"{"error": "invalid_api_key"}"#
    )

    @Test("空搜索列出全部往返")
    func emptyQueryKeepsAllExchanges() {
        let hits = DeveloperRefreshLogSearch.filtered(
            exchanges: [cloudflare, openai],
            query: "  "
        )
        #expect(hits == [cloudflare, openai])
    }

    @Test("按 URL 过滤")
    func queryMatchesSummary() {
        let hits = DeveloperRefreshLogSearch.filtered(
            exchanges: [cloudflare, openai],
            query: "cloudflare"
        )
        #expect(hits == [cloudflare])
    }

    @Test("按响应体过滤")
    func queryMatchesBody() {
        let hits = DeveloperRefreshLogSearch.filtered(
            exchanges: [cloudflare, openai],
            query: "invalid_api_key"
        )
        #expect(hits == [openai])
    }

    @Test("大小写不敏感")
    func queryIsCaseInsensitive() {
        let hits = DeveloperRefreshLogSearch.filtered(
            exchanges: [cloudflare, openai],
            query: "CLOUDFLARE"
        )
        #expect(hits == [cloudflare])
    }

    @Test("没有命中走空搜索；库里本来就空时仍走无请求空态")
    func unknownQueryShowsEmptySearchOnlyWhenLogsExist() {
        #expect(
            DeveloperRefreshLogSearch.showsEmptySearch(
                exchanges: [cloudflare],
                query: "zzzz-not-in-log"
            )
        )
        #expect(
            !DeveloperRefreshLogSearch.showsEmptySearch(
                exchanges: [],
                query: "cloudflare"
            )
        )
        #expect(
            !DeveloperRefreshLogSearch.showsEmptySearch(
                exchanges: [cloudflare],
                query: "  "
            )
        )
    }

    @Test("搜不存在的词走 ContentUnavailableView.search")
    func emptySearchUsesSystemUnavailableView() throws {
        let text = try GuardrailSourceScan.sourceText(named: "DeveloperRefreshLogView.swift")
        #expect(text.contains("ContentUnavailableView.search"))
    }

    @Test("搜索栏进页就钉在导航栏下，不藏进底部抽屉")
    func searchFieldAlwaysVisibleInNavigationBar() throws {
        let text = try GuardrailSourceScan.sourceText(named: "DeveloperRefreshLogView.swift")
        #expect(text.contains("placement: .navigationBarDrawer(displayMode: .always)"))
        #expect(text.contains("contentMargins(.top, MeterSpacing.xs, for: .scrollContent)"))
    }

    @Test("复制全部仍导出未筛选的往返")
    func copyAllUsesUnfilteredExchanges() throws {
        let text = try GuardrailSourceScan.sourceText(named: "DeveloperRefreshLogView.swift")
        #expect(text.contains("exportText(dashboard: dashboard, exchanges: exchanges)"))
        #expect(!text.contains("exchanges: filteredExchanges"))
    }
}
#endif
