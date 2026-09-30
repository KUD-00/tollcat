import Testing
@testable import TollcatCore

struct OnelineRendererTests {
    @Test func up() {
        let document = DashboardDocument(
            empty: false,
            rawJSON: "{}",
            formattedTotal: "$43.20",
            formattedProjected: "$61.00",
            monthTitle: "September",
            comparisonCaption: nil,
            comparisonPercentText: "+12%",
            comparisonTone: "up",
            staleCaption: nil,
            currencyNote: nil,
            subscriptionCaption: nil,
            composition: []
        )
        let line = OnelineRenderer.render(document, localeTag: "en")
        #expect(line.contains("$43.20"))
        #expect(line.contains("$61.00"))
        #expect(line.contains("↗"))
        #expect(!line.lowercased().contains("apikey"))
    }

    @Test func empty() {
        let document = DashboardDocument(
            empty: true,
            rawJSON: "{}",
            formattedTotal: "",
            formattedProjected: nil,
            monthTitle: "",
            comparisonCaption: nil,
            comparisonPercentText: nil,
            comparisonTone: nil,
            staleCaption: nil,
            currencyNote: nil,
            subscriptionCaption: nil,
            composition: []
        )
        #expect(OnelineRenderer.render(document, localeTag: "zh-Hans") == "—")
    }
}
