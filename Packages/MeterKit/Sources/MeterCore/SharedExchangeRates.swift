import Foundation

/// 目录刷新之后，展示层和各家适配器要看到**同一张**汇率表。
///
/// `ExchangeRates` 是值类型。启动时拷进每个 provider，刷新目录就更新不了
/// 已经在跑的那一轮。这个盒子大家握同一份，`current` 一换，下次取数和
/// 下次写字都跟上。
public final class SharedExchangeRates: @unchecked Sendable {
    private let lock = NSLock()
    private var rates: ExchangeRates

    public init(_ rates: ExchangeRates = .usdOnly) {
        self.rates = rates
    }

    public var current: ExchangeRates {
        get {
            lock.lock()
            defer { lock.unlock() }
            return rates
        }
        set {
            lock.lock()
            rates = newValue
            lock.unlock()
        }
    }
}
