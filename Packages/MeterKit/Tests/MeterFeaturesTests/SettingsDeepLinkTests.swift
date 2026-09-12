import Foundation
import Testing
@testable import MeterFeatures

struct SettingsDeepLinkTests {
    @Test("scheme 和仪表深链共用，host 分开")
    func settingsHostIsDistinct() {
        let url = SettingsDeepLink.settingsURL
        #expect(url.scheme == "tollcat")
        #expect(url.host() == SettingsDeepLink.host)
        #expect(SettingsDeepLink.matches(url))
        #expect(SettingsDeepLink.navigation(from: url) == .root)
    }

    @Test("路径能落到对应设置页；提醒落在第一屏")
    func knownPathsMapToNavigation() {
        let cases: [(String, SettingsNavigation)] = [
            ("tollcat://settings", .root),
            ("tollcat://settings/", .root),
            ("tollcat://settings/reminders", .root),
            ("tollcat://settings/inbox", .route(.inbox)),
            ("tollcat://settings/import", .route(.importExport)),
            ("tollcat://settings/transfer", .route(.importExport)),
            ("tollcat://settings/feedback", .route(.feedback)),
            ("tollcat://settings/about", .route(.about)),
            ("tollcat://settings/tip", .route(.tip)),
            ("tollcat://settings/whats-new", .route(.whatsNew)),
        ]
        for (raw, expected) in cases {
            let url = URL(string: raw)!
            #expect(SettingsDeepLink.navigation(from: url) == expected, "\(raw)")
        }
    }

    @Test("不认识的路径只打开设置列表，仪表 URL 不当设置")
    func unknownAndDashboardURLs() {
        #expect(SettingsDeepLink.navigation(from: URL(string: "tollcat://settings/nope")!) == .root)
        #expect(SettingsDeepLink.navigation(from: URL(string: "tollcat://dashboard")!) == nil)
        #expect(SettingsDeepLink.navigation(from: URL(string: "https://tollcat.app/settings")!) == nil)
        #expect(!SettingsDeepLink.matches(URL(string: "tollcat://dashboard")!))
    }

    @Test("写出的 URL 能原样认回来")
    func writtenURLsRoundTrip() {
        #expect(SettingsDeepLink.navigation(from: SettingsDeepLink.url()) == .root)
        #expect(SettingsDeepLink.navigation(from: SettingsDeepLink.url(path: "inbox")) == .route(.inbox))
        #expect(SettingsDeepLink.navigation(from: SettingsDeepLink.url(path: "reminders")) == .root)
    }
}
