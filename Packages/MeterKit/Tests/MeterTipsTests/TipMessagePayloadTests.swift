import Foundation
import Testing
@testable import MeterTips

struct TipMessagePayloadTests {
    @Test("编码只有约定字段，没有账单数据")
    func encodedKeysAreExactlyTheAllowedSet() throws {
        let payload = TipMessagePayload(
            transactionID: "tx-1",
            jws: "jws-token",
            productID: TipProductID.small.rawValue,
            displayPrice: "6.00",
            name: "陈",
            message: "好用",
            appVersion: "0.1.0"
        )
        let data = try JSONEncoder().encode(payload)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let keys = Set((object ?? [:]).keys)
        #expect(
            keys == [
                "transactionID",
                "jws",
                "productID",
                "displayPrice",
                "name",
                "message",
                "appVersion",
            ]
        )
        #expect(object?["provider"] == nil)
        #expect(object?["snapshots"] == nil)
        #expect(object?["total"] == nil)
    }

    @Test("名字和留言超长会截断")
    func clampsNameAndMessage() throws {
        let payload = TipMessagePayload(
            transactionID: "tx-2",
            jws: "jws",
            productID: TipProductID.medium.rawValue,
            displayPrice: "18.00",
            name: String(repeating: "甲", count: 80),
            message: String(repeating: "乙", count: 600),
            appVersion: "0.1.0"
        )
        #expect(payload.name?.count == TipFieldLimits.name)
        #expect(payload.message?.count == TipFieldLimits.message)
    }

    /// 原来这里断言的是占位 host `meter-tips.invalid`,一部署就必然失败 ——
    /// 那测的是「当前值」而不是不变量。真正要锁的是三件事:走 https、
    /// 已经配置过(不是 .invalid 占位就上线)、以及路径拼装正确。
    @Test("Worker 源是编译期常量且已配置")
    func workerURLIsCompiledIn() {
        #expect(TipWorkerEndpoint.origin.scheme == "https")
        #expect(TipWorkerEndpoint.origin.host?.isEmpty == false)
        #expect(TipWorkerEndpoint.origin.host?.hasSuffix(".invalid") == false)
        #expect(TipWorkerEndpoint.tipURL.lastPathComponent == "tip")
    }
}
