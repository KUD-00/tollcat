import Testing
@testable import MeterCore

struct ConfidenceTests {
    @Test("全精确才保持精确")
    func allExactStaysExact() {
        #expect(Confidence.exact.merging(.exact) == .exact)
    }

    @Test("任一家估算，总体就是估算")
    func anyEstimatedWins() {
        #expect(Confidence.exact.merging(.estimated) == .estimated)
        #expect(Confidence.partial.merging(.estimated) == .estimated)
        #expect(Confidence.estimated.merging(.partial) == .estimated)
    }

    @Test("没有估算、但有一家不全，总体降为不全")
    func partialWhenIncomplete() {
        #expect(Confidence.exact.merging(.partial) == .partial)
    }
}
