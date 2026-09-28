import Foundation

/// 一条用户可见文案：中文源串（也就是 String Catalog 的键）+ 插值实参。四个平台都能编。
///
/// 为什么不直接用 `String.LocalizationValue`：Android 的 swift-foundation 没有
/// `LocalizedStringResource`，Android / Windows / Linux 的 SwiftPM 构建也不编 String Catalog，
/// `String(localized:)` 在那边会静默回落中文。折算层（MeterDashboard 的 builder、这里的
/// `AccountTitle` / `SpokenMoney`）要在每个平台产出**同一份**字，就得有一个到处都能编的类型。
///
/// 调用点的写法照旧（`L` 里直接写带插值的中文）。插值按 Xcode 抽 catalog 的规矩写成
/// `%@`（字符串）/ `%lld`（整数），字面量里的 `%` 写成 `%%`——于是 `key` 和 catalog 里的
/// 键一字不差，`check-i18n-coverage.py` 照旧能对上。
public struct PortableText: Sendable, Hashable, ExpressibleByStringInterpolation {
    public enum Argument: Sendable, Hashable {
        case string(String)
        case integer(Int)

        var rendered: String {
            switch self {
            case .string(let value): value
            case .integer(let value): String(value)
            }
        }
    }

    enum Segment: Sendable, Hashable {
        case literal(String)
        case argument(Argument)
    }

    let segments: [Segment]

    /// Catalog 的键：插值位是 `%@` / `%lld`，字面量的 `%` 是 `%%`。
    public var key: String {
        segments.map { segment in
            switch segment {
            case .literal(let text): text.replacingOccurrences(of: "%", with: "%%")
            case .argument(.string): "%@"
            case .argument(.integer): "%lld"
            }
        }.joined()
    }

    public var arguments: [Argument] {
        segments.compactMap { segment in
            if case .argument(let argument) = segment { return argument }
            return nil
        }
    }

    public init(stringLiteral value: String) {
        segments = value.isEmpty ? [] : [.literal(value)]
    }

    public init(stringInterpolation: StringInterpolation) {
        segments = stringInterpolation.segments
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        var segments: [Segment] = []

        public init(literalCapacity: Int, interpolationCount: Int) {
            segments.reserveCapacity(interpolationCount * 2 + 1)
        }

        public mutating func appendLiteral(_ literal: String) {
            guard !literal.isEmpty else { return }
            segments.append(.literal(literal))
        }

        public mutating func appendInterpolation(_ value: String) {
            segments.append(.argument(.string(value)))
        }

        public mutating func appendInterpolation(_ value: Substring) {
            segments.append(.argument(.string(String(value))))
        }

        public mutating func appendInterpolation(_ value: Int) {
            segments.append(.argument(.integer(value)))
        }
    }

    #if canImport(Darwin)
    /// 同一条文案在 Apple 平台上的 `LocalizationValue`：交给 String Catalog 解析，
    /// 行为和改造前「`String(localized:)` 包一层 `L`」完全一样（含 `%lld` 的数字格式）。
    var localizationValue: String.LocalizationValue {
        var interpolation = String.LocalizationValue.StringInterpolation(
            literalCapacity: 0,
            interpolationCount: arguments.count
        )
        for segment in segments {
            switch segment {
            case .literal(let text): interpolation.appendLiteral(text)
            case .argument(.string(let value)): interpolation.appendInterpolation(value)
            case .argument(.integer(let value)): interpolation.appendInterpolation(value)
            }
        }
        return String.LocalizationValue(stringInterpolation: interpolation)
    }
    #endif
}
