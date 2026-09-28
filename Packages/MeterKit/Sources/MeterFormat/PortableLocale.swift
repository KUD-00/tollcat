import Foundation

/// 这一段代码要用哪种语言出字。桥（Android / Windows / CLI）进折算之前用
/// `PortableLocale.$languageTag.withValue(tag) { … }` 包一层；App 和 widget 不设，
/// 走系统语言和 String Catalog。
///
/// 用 task-local 而不是给每个 builder 加一个参数：几十个 builder 的签名不用为了
/// 「桥上要换语言」一起变，作用域又是显式的、线程安全的——出了闭包就失效。
public enum PortableLocale {
    @TaskLocal public static var languageTag: String?

    /// 日期格式化该用的 locale：桥钉了语言就用它，没钉就跟系统。
    /// Android 上 `Locale.current` 不可靠（JNI 线程拿不到 App 的语言设置），
    /// 所以 `MeterDateFormat` 的默认参数走这里，而不是直接写 `.current`。
    public static var formatting: Locale {
        languageTag.map { Locale(identifier: $0) } ?? .current
    }
}
