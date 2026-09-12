import Foundation

/// 按钥匙记住上一次算出来的东西。**钥匙必须装下全部输入。**
///
/// ## 为什么值得有这么个东西
///
/// 详情页原来手搓了 12 份同一个四行模式：
///
/// ```swift
/// let key = dashboard.revision.scoped(to: providerID)
/// if let cached = historyCache, cached.token == token, cached.range == historyRange {
///     return cached.value
/// }
/// let value = …
/// historyCache = (token, historyRange, value)
/// ```
///
/// 重复本身不是问题，**每一处都得自己记得把第二个输入也写进比较条件**才是：
/// `historyRange`、`breakdownGrouping` 这些不在展示版本里，
/// 漏一个的表现是「换了档位，数字不变」——不崩、不报错，只是屏幕上那个数
/// 停在上一个档位，而没有任何一步会发现。
///
/// 换成这个类型之后，钥匙是一个值：漏输入 = 钥匙里少一样 = 一眼看得见，
/// 而且编译器会盯着它的类型。
///
/// ## 用法
///
/// ```swift
/// @ObservationIgnored private var history = Memo<MemoKey<Int, ProviderHistoryRange>, [Item]>()
/// var items: [Item] {
///     history(MemoKey(key, historyRange)) { …重算… }
/// }
/// ```
///
/// 只记**一份**（上一次那份），不是字典：这几处的读法都是「同一个钥匙连着问好几遍」
/// （body 一次求值问三四回），换钥匙就再也不会回头问旧的了。存一份够用，
/// 而字典要额外操心什么时候清。
///
/// 在 `@Observable` 类里放它要配 `@ObservationIgnored`：缓存不是状态，
/// 在 body 求值中写它不能触发失效。
struct Memo<Key: Equatable, Value> {
    private var key: Key?
    private var value: Value?

    /// 钥匙没变就还上一次那份；变了就重算、记下、还回去。
    mutating func callAsFunction(_ key: Key, _ make: () -> Value) -> Value {
        if let stored = self.key, stored == key, let value {
            return value
        }
        let fresh = make()
        self.key = key
        self.value = fresh
        return fresh
    }
}

/// 两样东西合成一把钥匙。Swift 的元组不是 `Equatable`，所以要这么一个壳。
struct MemoKey<A: Equatable, B: Equatable>: Equatable {
    var a: A
    var b: B

    init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
}
