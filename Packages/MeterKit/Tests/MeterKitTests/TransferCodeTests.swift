import Foundation
import Testing
@testable import MeterCore

struct TransferCodeTests {
    @Test("码长是 10，改小等于主动降熵")
    func characterCountIsTen() {
        #expect(TransferCode.characterCount == 10)
        #expect(TransferCode.alphabet.count == 32)
    }

    @Test("生成结果是 10 个 Crockford 字符")
    func generateUsesAlphabet() {
        var generator = SeededGenerator(seed: 42)
        let code = TransferCode.generate(using: &generator)
        #expect(code.rawValue.count == 10)
        #expect(code.rawValue.allSatisfy { TransferCode.alphabet.contains($0) })
        #expect(code.displayString == "\(code.rawValue.prefix(5))-\(code.rawValue.suffix(5))")
    }

    @Test("显示成两组五位")
    func displayInsertsHyphen() throws {
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        #expect(code.displayString == "K7M2Q-9XR4T")
        #expect(code.rawValue == "K7M2Q9XR4T")
    }

    @Test("输入忽略连字符、空白和大小写，并按 Crockford 纠正易混字符")
    func normalizesUserInput() throws {
        let code = try #require(TransferCode(userInput: "k7m2q 9xr4t"))
        #expect(code.rawValue == "K7M2Q9XR4T")

        let confused = try #require(TransferCode(userInput: "ILO0-12345A"))
        #expect(confused.rawValue == "110012345A")
    }

    @Test("长度不对或字符不在字母表里就拒")
    func rejectsInvalidInput() {
        #expect(TransferCode(userInput: "SHORT") == nil)
        #expect(TransferCode(userInput: "K7M2Q-9XR4TU") == nil)
        #expect(TransferCode(userInput: "K7M2Q-9XR4U") == nil)
        #expect(TransferCode(userInput: "") == nil)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
