import Foundation
import SwiftData
import Testing
import MeterPersistence
import MeterTips
@testable import MeterFeatures

@MainActor
struct TipModelTests {
    @Test("购买成功会留下记录并打开留言表单")
    func successfulPurchaseOpensComposer() async throws {
        let env = try makeEnvironment(purchase: .success)
        await env.model.load()
        #expect(env.model.catalogState == .ready)
        #expect(env.model.offerings.count == 3)

        await env.model.buy(env.model.offerings[0])
        #expect(env.model.records.count == 1)
        #expect(env.model.thanksVisible)
        #expect(env.model.composerVisible)
        #expect(env.model.purchaseNotice == nil)
        #expect(env.model.records[0].displayPrice == env.model.offerings[0].displayPrice)
    }

    @Test("取消、待批准、失败是三种提示")
    func purchaseOutcomesStayDistinct() async throws {
        let cancelled = try makeEnvironment(purchase: .cancelled)
        await cancelled.model.load()
        await cancelled.model.buy(cancelled.model.offerings[0])
        #expect(cancelled.model.purchaseNotice == .cancelled)
        #expect(cancelled.model.records.isEmpty)

        let pending = try makeEnvironment(purchase: .pending)
        await pending.model.load()
        await pending.model.buy(pending.model.offerings[0])
        #expect(pending.model.purchaseNotice == .pending)

        let failed = try makeEnvironment(purchase: .failed)
        await failed.model.load()
        await failed.model.buy(failed.model.offerings[0])
        #expect(failed.model.purchaseNotice == .failed)
    }

    @Test("留言发送失败不回滚购买，下次打开会重试")
    func messageFailureDoesNotUndoPurchase() async throws {
        let env = try makeEnvironment(purchase: .success, messageShouldFail: true)
        await env.model.load()
        await env.model.buy(env.model.offerings[0])
        env.model.draftName = "陈"
        env.model.draftMessage = "好用"
        await env.model.submitComposer()

        #expect(env.model.records.count == 1)
        #expect(env.model.records[0].isSubmitted == false)
        #expect(env.model.willRetryMessage)
        #expect(env.messenger.submitted.count == 1)

        env.messenger.shouldFail = false
        await env.model.load()
        #expect(env.model.records[0].isSubmitted)
        #expect(env.messenger.submitted.count == 2)
    }

    @Test("划掉打赏页等于这次不留")
    func leavingAbandonsComposer() async throws {
        let env = try makeEnvironment(purchase: .success)
        await env.model.load()
        await env.model.buy(env.model.offerings[0])
        #expect(env.model.composerVisible)
        #expect(env.model.records[0].isSubmitted == false)

        await env.model.abandonComposerIfNeeded()
        #expect(env.model.composerVisible == false)
        #expect(env.model.pendingTransactionID == nil)
        #expect(env.model.records[0].isSubmitted)
        #expect(env.messenger.submitted.count == 1)

        await env.model.abandonComposerIfNeeded()
        #expect(env.messenger.submitted.count == 1)
    }

    @Test("打赏页不再用档位标题和这次不留")
    func tipViewDropsTierHeaderAndSkipButton() throws {
        let settings = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Settings")
        let view = try String(contentsOf: settings.appending(path: "TipView.swift"), encoding: .utf8)
        let label = try String(contentsOf: settings.appending(path: "TipOfferingLabel.swift"), encoding: .utf8)
        let text = view + label
        #expect(!text.contains("L(\"档位\")"))
        #expect(!text.contains("L(\"这次不留\")"))
        #expect(!text.contains("L(\"感谢\")"))
        #expect(text.contains("TipTreatView"))
        #expect(view.contains("meterPrimaryActionBar"))
        #expect(view.contains("abandonComposerIfNeeded"))
        #expect(view.contains("catTipCelebrating"))
    }

    @Test("谢词按档位分开，回头客换一句招呼")
    func thanksVariesByTreat() {
        let candy = TipThanks.make(treat: .small, isRepeat: false)
        let coffee = TipThanks.make(treat: .medium, isRepeat: false)
        let pizza = TipThanks.make(treat: .large, isRepeat: false)
        // 三档各说各的：一句通用的「谢谢。」正是这次要修掉的东西。
        #expect(candy != coffee)
        #expect(coffee != pizza)
        #expect(candy.note != pizza.note)
        // 回头客只换标题，拿到的东西还是照实说。
        let again = TipThanks.make(treat: .small, isRepeat: true)
        #expect(again.headline != candy.headline)
        #expect(again.note == candy.note)
        // 认不出产品 ID（外部退款回放之类）也得有话说，不能空着。
        let unknown = TipThanks.make(treat: nil, isRepeat: false)
        #expect(unknown.headline == candy.headline)
        #expect(unknown.note != candy.note)
    }

    @Test("买完记下是哪一档，第二笔起算回头客")
    @MainActor
    func purchaseRecordsThanksTreat() async throws {
        let env = try makeEnvironment(purchase: .success)
        await env.model.buy(TipOffering(id: TipProductID.large.rawValue, displayName: "披萨", displayPrice: "45.00"))
        #expect(env.model.thanksTreat == .large)
        #expect(env.model.thanksIsRepeat == false)
    }

    @Test("设置页文案不再写类型和个人自用")
    func settingsDropsTypeRow() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Settings/SettingsView.swift")
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(!text.contains("LabeledContent(\"类型\")"))
        #expect(!text.contains("个人自用"))
        #expect(text.contains("请猫猫吃点东西"))
    }

    private func makeEnvironment(
        purchase: TipPurchaseOutcomeKind,
        messageShouldFail: Bool = false
    ) throws -> TestEnvironment {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let messenger = StubMessenger(shouldFail: messageShouldFail)
        let model = TipModel(
            container: container,
            catalog: StubCatalog(),
            purchaser: StubPurchaser(kind: purchase),
            messenger: messenger,
            listener: IdleListener(),
            appVersion: "0.1.0"
        )
        return TestEnvironment(model: model, messenger: messenger)
    }
}

private struct TestEnvironment {
    var model: TipModel
    var messenger: StubMessenger
}

private enum TipPurchaseOutcomeKind {
    case success
    case cancelled
    case pending
    case failed
}

private struct StubCatalog: TipCataloging {
    func loadProducts() async throws -> [TipOffering] {
        [
            TipOffering(id: TipProductID.small.rawValue, displayName: "糖果", displayPrice: "0.99"),
            TipOffering(id: TipProductID.medium.rawValue, displayName: "咖啡", displayPrice: "4.99"),
            TipOffering(id: TipProductID.large.rawValue, displayName: "披萨", displayPrice: "9.99"),
        ]
    }
}

private struct StubPurchaser: TipPurchasing {
    var kind: TipPurchaseOutcomeKind

    func purchase(productID: String) async -> TipPurchaseOutcome {
        switch kind {
        case .success:
            return .success(
                TipTransaction(
                    id: "tx-\(productID)",
                    productID: productID,
                    displayPrice: "0.99",
                    jws: "jws",
                    purchasedAt: Date(timeIntervalSince1970: 1_787_000_000)
                )
            )
        case .cancelled:
            return .cancelled
        case .pending:
            return .pending
        case .failed:
            return .failed
        }
    }
}

private final class StubMessenger: TipMessageSubmitting, @unchecked Sendable {
    var shouldFail: Bool
    var submitted: [TipMessagePayload] = []

    init(shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func submit(_ payload: TipMessagePayload) async throws {
        submitted.append(payload)
        if shouldFail {
            throw TipMessageError.httpStatus(503)
        }
    }
}

private struct IdleListener: TipTransactionListening {
    func updates() -> AsyncStream<TipTransaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
