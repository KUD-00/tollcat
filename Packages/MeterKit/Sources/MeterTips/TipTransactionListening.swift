import Foundation

public protocol TipTransactionListening: Sendable {
    func updates() -> AsyncStream<TipTransaction>
}
