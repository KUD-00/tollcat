import Foundation

enum ReminderAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized

    var isAuthorized: Bool { self == .authorized }
}
