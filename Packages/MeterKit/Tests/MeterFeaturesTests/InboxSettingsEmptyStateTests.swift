import Foundation
import Testing
@testable import MeterFeatures

/// 读数信箱空态必须整页接管。塞进 List 的 Section 就居中不了，也没有系统空态图标。
struct InboxSettingsEmptyStateTests {
    @Test("没有信箱时用系统 ContentUnavailableView 整页接管")
    func emptyStateReplacesTheList() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Settings")
        let empty = try String(
            contentsOf: root.appending(path: "InboxEmptyView.swift"),
            encoding: .utf8
        )
        let page = try String(
            contentsOf: root.appending(path: "InboxSettingsView.swift"),
            encoding: .utf8
        )
        #expect(empty.contains("ContentUnavailableView"))
        #expect(empty.contains("systemImage:"))
        #expect(page.contains("InboxEmptyView()"))
        #expect(!page.contains("emptySection"))
    }
}
