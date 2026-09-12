import Foundation
import MeterCore

/// 设置界面和调度逻辑都只依赖这个协议，真实 UN 和内存 mock 可以互换。
protocol ReminderScheduling: Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    func requestAuthorization() async -> Bool
    func pendingRequestCount() async -> Int
    func replacePending(specs: [ReminderTriggerSpec], content: ReminderNotificationContent) async throws
    func cancelAll() async
}
