import Foundation
import MeterCore

actor InMemoryReminderScheduler: ReminderScheduling {
    private var status: ReminderAuthorization
    private var grantOnRequest: Bool
    private var pending: [ReminderTriggerSpec]
    private(set) var lastContent: ReminderNotificationContent?
    private(set) var replaceCount = 0
    private(set) var cancelCount = 0
    private(set) var requestCount = 0

    init(
        status: ReminderAuthorization = .notDetermined,
        grantOnRequest: Bool = true
    ) {
        self.status = status
        self.grantOnRequest = grantOnRequest
        self.pending = []
    }

    func authorizationStatus() async -> ReminderAuthorization {
        status
    }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        switch status {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            status = grantOnRequest ? .authorized : .denied
            return grantOnRequest
        }
    }

    func pendingRequestCount() async -> Int {
        pending.count
    }

    func replacePending(
        specs: [ReminderTriggerSpec],
        content: ReminderNotificationContent
    ) async throws {
        pending = specs
        lastContent = content
        replaceCount += 1
    }

    func cancelAll() async {
        pending = []
        lastContent = nil
        cancelCount += 1
    }
}
