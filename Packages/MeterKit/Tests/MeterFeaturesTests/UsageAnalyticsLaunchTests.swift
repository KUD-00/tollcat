import Testing
@testable import MeterFeatures

struct UsageAnalyticsLaunchTests {
    @Test("DEBUG 构建不把匿名页面计数发到 Worker")
    func debugBuildStubsUsageAnalytics() {
        #if DEBUG
        #expect(FeatureLaunchArguments.stubUsageAnalytics)
        #else
        #expect(!FeatureLaunchArguments.stubUsageAnalytics)
        #endif
    }
}
