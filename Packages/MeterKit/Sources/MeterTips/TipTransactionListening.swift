import Foundation

public protocol TipTransactionListening: Sendable {
    func updates() -> AsyncStream<TipTransaction>
    /// 调用方把这笔打赏持久化之后再调。在那之前不 finish，进程中途被杀时
    /// StoreKit 会在下次 `updates` 里重放这笔，钱付了打赏不会丢。
    func finish(transactionID: String) async
}

extension TipTransactionListening {
    public func finish(transactionID: String) async {}
}
