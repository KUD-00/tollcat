#if DEBUG
import Foundation
import os
import MeterProviders

/// 真机调试用的内存日志。os.Logger 在没连 Xcode 时不好拷，这里给「复制全部」。
enum DeveloperDebugLog: Sendable {
    static let limit = 300

    private static let storage = OSAllocatedUnfairLock(initialState: [Line]())

    struct Line: Sendable {
        var at: Date
        var category: String
        var message: String
    }

    static func record(category: String, _ message: String) {
        let line = Line(at: Date(), category: category, message: message)
        storage.withLock { buffer in
            buffer.append(line)
            if buffer.count > limit {
                buffer.removeFirst(buffer.count - limit)
            }
        }
    }

    static var lines: [Line] {
        storage.withLock { $0 }
    }

    static func clear() {
        storage.withLock { $0 = [] }
    }

    @MainActor
    static func exportText(
        dashboard: DashboardModel,
        exchanges: [HTTPExchange]
    ) -> String {
        var parts: [String] = [
            "# TollCat debug log",
            "copiedAt \(ISO8601DateFormatter().string(from: Date()))",
        ]
        if !dashboard.lastRefreshSummary.isEmpty {
            parts.append("lastRefresh \(dashboard.lastRefreshSummary)")
        }
        let events = lines
        if !events.isEmpty {
            parts.append("")
            parts.append("## events")
            let formatter = ISO8601DateFormatter()
            for line in events {
                parts.append("\(formatter.string(from: line.at)) [\(line.category)] \(line.message)")
            }
        }
        if !exchanges.isEmpty {
            parts.append("")
            parts.append("## http")
            for exchange in exchanges {
                parts.append(exchange.summary)
                if !exchange.body.isEmpty {
                    parts.append(exchange.body)
                }
                parts.append("")
            }
        }
        parts.append("## store")
        parts.append(DeveloperStoreDump.json(from: dashboard))
        return parts.joined(separator: "\n")
    }
}
#endif
