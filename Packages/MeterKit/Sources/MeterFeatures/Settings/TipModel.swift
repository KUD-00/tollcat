import Foundation
import Observation
import SwiftData
import MeterPersistence
import MeterTips

@MainActor
@Observable
final class TipModel {
    enum CatalogState: Equatable {
        case loading
        case ready
        case unavailable
    }

    enum PurchaseNotice: Equatable {
        case cancelled
        case pending
        case failed
    }

    var catalogState: CatalogState = .loading
    var offerings: [TipOffering] = []
    var records: [TipHistoryItem] = []
    var isPurchasing = false
    var purchaseNotice: PurchaseNotice?
    var thanksVisible = false
    /// 这次买的是哪一档 / 是不是回头客——付款成功那两句照这两个值挑，见 `TipThanks`。
    var thanksTreat: TipProductID?
    var thanksIsRepeat = false
    var composerVisible = false
    var draftName = ""
    var draftMessage = ""
    var pendingTransactionID: String?
    var willRetryMessage = false

    private let container: ModelContainer
    private let catalog: any TipCataloging
    private let purchaser: any TipPurchasing
    private let messenger: any TipMessageSubmitting
    private let listener: any TipTransactionListening
    private let appVersion: String

    init(
        container: ModelContainer,
        catalog: any TipCataloging = StoreKitTipCatalog(),
        purchaser: any TipPurchasing = StoreKitTipPurchaser(),
        messenger: any TipMessageSubmitting = TipWorkerClient(),
        listener: any TipTransactionListening = StoreKitTipTransactionListener(),
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    ) {
        self.container = container
        self.catalog = catalog
        self.purchaser = purchaser
        self.messenger = messenger
        self.listener = listener
        self.appVersion = appVersion
        reloadHistory()
        thanksVisible = !records.isEmpty
    }

    var thanks: TipThanks {
        TipThanks.make(treat: thanksTreat, isRepeat: thanksIsRepeat)
    }

    func load() async {
        catalogState = .loading
        do {
            var products = try await catalog.loadProducts()
            if products.isEmpty {
                // StoreKit 本地店面刚挂上时，第一次查询经常是空数组。
                try await Task.sleep(for: .milliseconds(400))
                products = try await catalog.loadProducts()
            }
            if products.isEmpty {
                offerings = []
                catalogState = .unavailable
            } else {
                offerings = products
                catalogState = .ready
            }
        } catch {
            offerings = []
            catalogState = .unavailable
        }
        reloadHistory()
        await retryUnsentMessages()
    }

    func observeTransactions() async {
        for await transaction in listener.updates() {
            ingest(transaction, showComposer: true)
            await retryUnsentMessages()
        }
    }

    func buy(_ offering: TipOffering) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseNotice = nil
        let outcome = await purchaser.purchase(productID: offering.id)
        isPurchasing = false

        switch outcome {
        case .success(let transaction):
            ingest(transaction, showComposer: true)
        case .cancelled:
            purchaseNotice = .cancelled
        case .pending:
            purchaseNotice = .pending
        case .failed:
            purchaseNotice = .failed
        }
    }

    func submitComposer() async {
        guard let transactionID = pendingTransactionID else {
            composerVisible = false
            return
        }
        applyDraft(to: transactionID)
        composerVisible = false
        pendingTransactionID = nil
        await submit(transactionID: transactionID)
    }

    func skipComposer() async {
        guard let transactionID = pendingTransactionID else {
            composerVisible = false
            return
        }
        composerVisible = false
        pendingTransactionID = nil
        await submit(transactionID: transactionID)
    }

    /// 划掉这页等于「这次不留」。已经点过写好了就什么都不做。
    func abandonComposerIfNeeded() async {
        guard composerVisible, pendingTransactionID != nil else { return }
        await skipComposer()
    }

    func retryUnsentMessages() async {
        let context = ModelContext(container)
        let pending = (try? TipRecord.unsynced(from: context)) ?? []
        for record in pending {
            if composerVisible, record.transactionID == pendingTransactionID {
                continue
            }
            await submit(transactionID: record.transactionID)
        }
    }

    private func ingest(_ transaction: TipTransaction, showComposer: Bool) {
        let context = ModelContext(container)
        let existed = (try? TipRecord.fetch(
            transactionID: transaction.id,
            from: context
        )) != nil
        _ = try? TipRecord.upsert(
            transactionID: transaction.id,
            productID: transaction.productID,
            displayPrice: transaction.displayPrice,
            purchasedAt: transaction.purchasedAt,
            jws: transaction.jws,
            appVersion: appVersion,
            in: context
        )
        reloadHistory()
        thanksVisible = true
        thanksTreat = TipProductID(rawValue: transaction.productID)
        // reloadHistory 已经把这一笔算进去了，所以「不止一笔」就是回头客。
        thanksIsRepeat = records.count > 1
        purchaseNotice = nil
        if showComposer, !existed {
            pendingTransactionID = transaction.id
            composerVisible = true
            draftName = ""
            draftMessage = ""
        }
    }

    private func applyDraft(to transactionID: String) {
        let context = ModelContext(container)
        guard let record = try? TipRecord.fetch(transactionID: transactionID, from: context) else {
            return
        }
        record.name = TipFieldLimits.clampName(draftName)
        record.message = TipFieldLimits.clampMessage(draftMessage)
        try? context.save()
        reloadHistory()
    }

    private func submit(transactionID: String) async {
        let context = ModelContext(container)
        guard let record = try? TipRecord.fetch(transactionID: transactionID, from: context) else {
            return
        }
        let payload = TipMessagePayload(
            transactionID: record.transactionID,
            jws: record.jws,
            productID: record.productID,
            displayPrice: record.displayPrice,
            name: record.name,
            message: record.message,
            appVersion: record.appVersion
        )
        do {
            try await messenger.submit(payload)
            let latest = ModelContext(container)
            if let stored = try TipRecord.fetch(transactionID: transactionID, from: latest) {
                stored.isSubmitted = true
                try latest.save()
            }
            let remaining = (try? TipRecord.unsynced(from: ModelContext(container))) ?? []
            willRetryMessage = remaining.contains { $0.transactionID != pendingTransactionID }
            reloadHistory()
        } catch {
            willRetryMessage = true
            reloadHistory()
        }
    }

    private func reloadHistory() {
        let context = ModelContext(container)
        let stored = (try? TipRecord.all(from: context)) ?? []
        records = stored.map { record in
            TipHistoryItem(
                transactionID: record.transactionID,
                productID: record.productID,
                displayPrice: record.displayPrice,
                purchasedAt: record.purchasedAt,
                name: record.name,
                message: record.message,
                isSubmitted: record.isSubmitted
            )
        }
    }
}

extension TipModel {
    static var preview: TipModel {
        preview(seedHistory: false, catalog: .loaded)
    }

    static var previewUnavailable: TipModel {
        preview(seedHistory: false, catalog: .unavailable)
    }

    static var previewHistory: TipModel {
        preview(seedHistory: true, catalog: .loaded)
    }

    static var previewComposer: TipModel {
        let model = preview(seedHistory: true, catalog: .loaded)
        model.composerVisible = true
        model.pendingTransactionID = "preview-1"
        model.thanksTreat = .large
        return model
    }

    private enum PreviewCatalog {
        case loaded
        case unavailable
    }

    private static func preview(seedHistory: Bool, catalog: PreviewCatalog) -> TipModel {
        let container = try! PersistenceContainer.makeContainer(inMemory: true)
        if seedHistory {
            let context = ModelContext(container)
            _ = try? TipRecord.upsert(
                transactionID: "preview-1",
                productID: TipProductID.small.rawValue,
                displayPrice: "6.00",
                purchasedAt: Date(timeIntervalSince1970: 1_787_000_000),
                name: String(localized: L("陈")),
                message: String(localized: L("好用")),
                jws: "preview-jws",
                appVersion: "0.1.0",
                in: context
            )
        }
        let model = TipModel(
            container: container,
            catalog: PreviewTipCatalog(isUnavailable: catalog == .unavailable),
            purchaser: PreviewTipPurchaser(),
            messenger: PreviewTipMessenger(),
            listener: IdleTipTransactionListener(),
            appVersion: "0.1.0"
        )
        if seedHistory {
            model.thanksVisible = true
        }
        return model
    }
}

private struct PreviewTipCatalog: TipCataloging {
    var isUnavailable: Bool

    func loadProducts() async throws -> [TipOffering] {
        if isUnavailable { return [] }
        return [
            TipOffering(id: TipProductID.small.rawValue, displayName: TipProductID.small.listTitle, displayPrice: "6.00"),
            TipOffering(id: TipProductID.medium.rawValue, displayName: TipProductID.medium.listTitle, displayPrice: "18.00"),
            TipOffering(id: TipProductID.large.rawValue, displayName: TipProductID.large.listTitle, displayPrice: "45.00"),
        ]
    }
}

private struct PreviewTipPurchaser: TipPurchasing {
    func purchase(productID: String) async -> TipPurchaseOutcome {
        .success(
            TipTransaction(
                id: "preview-\(productID)",
                productID: productID,
                displayPrice: "6.00",
                jws: "preview-jws",
                purchasedAt: Date(timeIntervalSince1970: 1_787_000_000)
            )
        )
    }
}

private struct PreviewTipMessenger: TipMessageSubmitting {
    func submit(_ payload: TipMessagePayload) async throws {}
}

private struct IdleTipTransactionListener: TipTransactionListening {
    func updates() -> AsyncStream<TipTransaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
