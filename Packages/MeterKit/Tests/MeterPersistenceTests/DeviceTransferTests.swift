import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct DeviceTransferTests {
    private let knownSecret = "sk-test-LEAK-PROBE-7f2a9c1e4b88"
    private let now = Date(timeIntervalSince1970: 1_787_000_000)

    @Test("往返：导出再导入，凭据和接入关系一致")
    func exportImportRoundTrip() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )

        let destination = try makeDestinationStoreWithNoise()
        try DeviceTransfer.applyImport(
            fileBytes: exported.fileBytes,
            code: code,
            container: destination.container,
            credentials: destination.credentials,
            now: now.addingTimeInterval(60),
            calendar: utcCalendar
        )

        let destContext = ModelContext(destination.container)
        let configs = try destContext.fetch(FetchDescriptor<ProviderConfigRecord>())
            .sorted { $0.sortIndex < $1.sortIndex }
        #expect(configs.map(\.providerIDRaw) == ["cloudflare", "openai"])
        #expect(configs[0].isEnabled)
        #expect(configs[0].credentialReference == "credential.cloudflare")
        #expect(configs[0].includeInGlobalRefresh == true)
        #expect(configs[1].providerID == .openai)
        #expect(configs[1].includeInGlobalRefresh == false)

        let cfRaw = try #require(try destination.credentials.read(reference: "credential.cloudflare"))
        #expect(try CredentialFieldsCodec.decode(cfRaw)["apiToken"] == knownSecret)
        #expect(try CredentialFieldsCodec.decode(cfRaw)["accountID"] == "acct_cf")
        let oaRaw = try #require(try destination.credentials.read(reference: "credential.openai"))
        #expect(try CredentialFieldsCodec.decode(oaRaw)["apiToken"] == "oa-admin-key")

        let subscriptions = try destContext.fetch(FetchDescriptor<SubscriptionRecord>())
        #expect(subscriptions.count == 1)
        #expect(subscriptions[0].name == "ChatGPT Plus")
        #expect(subscriptions[0].amountUSD == Decimal(string: "20"))
        #expect(subscriptions[0].periodRaw == SubscriptionPeriod.monthly.rawValue)
        #expect(subscriptions[0].anchorYear == 2026)
        #expect(subscriptions[0].anchorMonth == 8)
        #expect(subscriptions[0].anchorDay == 3)
        #expect(subscriptions[0].providerIDRaw == "openai")
        #expect(subscriptions[0].quantity == 3)

        let preferences = try AppPreferencesRecord.load(from: destContext)
        #expect(preferences.appearance == .dark)
        #expect(preferences.isReminderEnabled)
        #expect(preferences.reminderSchedule.hour == 9)
        #expect(preferences.hasCompletedOnboarding)
        #expect(preferences.includeAWSInGlobalRefresh)
        #expect(preferences.providerHistoryRange == .months12)
        #expect(!preferences.isDemoModeEnabled)
        #expect(preferences.hidesCat)
        #expect(preferences.refreshesUsageOnActivate)
        #expect(preferences.displayCurrency == "CNY")
        #expect(preferences.seenUsageGuideIDs == ["awsRefreshCostsMoney", "heroExcludesSubscriptions"])

        #expect(try destContext.fetch(FetchDescriptor<SnapshotRecord>()).isEmpty)
        #expect(try destination.credentials.read(reference: "credential.neon") == nil)

        let tips = try TipRecord.all(from: destContext)
        #expect(tips.count == 1)
        #expect(tips[0].transactionID == "keep-me")
    }

    @Test("错码解密失败")
    func wrongCodeFailsAuthentication() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        let wrong = try #require(TransferCode(userInput: "ZZZZZZZZZZ"))
        let destination = try makeEmptyStore()

        #expect(throws: TransferImportError.authenticationFailed) {
            try DeviceTransfer.applyImport(
                fileBytes: exported.fileBytes,
                code: wrong,
                container: destination.container,
                credentials: destination.credentials,
                now: now,
                calendar: utcCalendar
            )
        }
    }

    @Test("过期文件被拒")
    func expiredFileIsRejected() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        let destination = try makeEmptyStore()

        #expect(throws: TransferImportError.expired) {
            try DeviceTransfer.applyImport(
                fileBytes: exported.fileBytes,
                code: code,
                container: destination.container,
                credentials: destination.credentials,
                now: now.addingTimeInterval(TransferLifetime.duration + 1),
                calendar: utcCalendar
            )
        }
    }

    @Test("迭代数被改小：在派生之前就拒绝")
    func tamperedIterationsAreRejectedBeforeDeriving() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        var tampered = exported.fileBytes
        let offset = TransferFileFormat.iterationsOffset
        tampered[offset] = 0
        tampered[offset + 1] = 0
        tampered[offset + 2] = 0
        tampered[offset + 3] = 1
        let destination = try makeEmptyStore()

        #expect(throws: TransferImportError.weakKeyDerivation) {
            try DeviceTransfer.applyImport(
                fileBytes: tampered,
                code: code,
                container: destination.container,
                credentials: destination.credentials,
                now: now,
                calendar: utcCalendar
            )
        }
    }

    /// 迭代数在被认证之前就决定了要烧多少 CPU（要验 AAD 得先有密钥，
    /// 要有密钥得先按它跑 PBKDF2）。所以上限必须在派生之前生效，
    /// 否则一个写着 40 亿轮的文件能让导入空转一个多小时。
    @Test("迭代数被改到天文数字：立刻拒绝，不会空转")
    func absurdIterationsAreRejectedQuickly() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        var tampered = exported.fileBytes
        let offset = TransferFileFormat.iterationsOffset
        tampered[offset] = 0xFF
        tampered[offset + 1] = 0xFF
        tampered[offset + 2] = 0xFF
        tampered[offset + 3] = 0xFF
        let destination = try makeEmptyStore()

        let started = ContinuousClock.now
        #expect(throws: TransferImportError.weakKeyDerivation) {
            try DeviceTransfer.applyImport(
                fileBytes: tampered,
                code: code,
                container: destination.container,
                credentials: destination.credentials,
                now: now,
                calendar: utcCalendar
            )
        }
        // 真跑 40 亿轮要一个多小时。这里给足余量，只要没在派生就一定过。
        #expect(started.duration(to: .now) < .seconds(10))
    }

    /// 上面两条都在派生之前被拦下，所以还需要一条真正走到认证的头部篡改测试。
    @Test("改头部的过期时间后认证失败")
    func tamperedExpiryFailsAuthentication() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        var tampered = exported.fileBytes
        let offset = TransferFileFormat.notAfterOffset
        tampered[offset + 7] = tampered[offset + 7] &+ 1
        let destination = try makeEmptyStore()

        #expect(throws: TransferImportError.authenticationFailed) {
            try DeviceTransfer.applyImport(
                fileBytes: tampered,
                code: code,
                container: destination.container,
                credentials: destination.credentials,
                now: now,
                calendar: utcCalendar
            )
        }
    }

    @Test("改密文一个字节后认证失败")
    func tamperedCiphertextFailsAuthentication() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        var tampered = exported.fileBytes
        tampered[TransferFileFormat.headerByteCount] ^= 0x01
        let destination = try makeEmptyStore()

        #expect(throws: TransferImportError.authenticationFailed) {
            try DeviceTransfer.applyImport(
                fileBytes: tampered,
                code: code,
                container: destination.container,
                credentials: destination.credentials,
                now: now,
                calendar: utcCalendar
            )
        }
    }

    @Test("已知测试 key 不得出现在导出的全部字节里")
    func knownSecretDoesNotAppearInFileBytes() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )

        let needle = Data(knownSecret.utf8)
        #expect(exported.fileBytes.range(of: needle) == nil)

        let header = exported.fileBytes.prefix(TransferFileFormat.headerByteCount)
        #expect(header.range(of: Data("cloudflare".utf8)) == nil)
        #expect(header.range(of: Data("openai".utf8)) == nil)
        #expect(header.range(of: Data("apiToken".utf8)) == nil)
        #expect(header.range(of: Data(code.rawValue.utf8)) == nil)
        #expect(header.count == TransferFileFormat.headerByteCount)
    }

    @Test("导出临时文件一次性写入密文，盘上也搜不到明文")
    func temporaryFileContainsOnlyCiphertext() throws {
        let source = try makeSourceStore(secret: knownSecret)
        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source.container,
            credentials: source.credentials,
            now: now,
            calendar: utcCalendar,
            code: code
        )
        let url = try TransferTemporaryFile.write(exported.fileBytes)
        defer { TransferTemporaryFile.delete(url) }

        let onDisk = try Data(contentsOf: url)
        #expect(onDisk == exported.fileBytes)
        #expect(onDisk.range(of: Data(knownSecret.utf8)) == nil)
        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test("凭据 JSON 对象往返")
    func credentialFieldsJSONRoundTrips() throws {
        let raw = try CredentialFieldsCodec.encode(["apiToken": "secret", "accountID": "acct"])
        let decoded = try CredentialFieldsCodec.decode(raw)
        #expect(decoded["apiToken"] == "secret")
        #expect(decoded["accountID"] == "acct")
    }

    @Test("非 JSON 凭据不解成 apiToken")
    func credentialFieldsPlainStringFails() {
        #expect(throws: CredentialFieldsCodec.CodecError.decodingFailed) {
            try CredentialFieldsCodec.decode("sk-plain-MUST-NOT-BE-A-TOKEN")
        }
    }

    private func makeSourceStore(secret: String) throws -> Store {
        let credentials = InMemoryCredentialStore()
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)

        try credentials.save(
            CredentialFieldsCodec.encode(["apiToken": secret, "accountID": "acct_cf"]),
            reference: "credential.cloudflare"
        )
        try credentials.save(
            CredentialFieldsCodec.encode(["apiToken": "oa-admin-key"]),
            reference: "credential.openai"
        )

        context.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare,
                isEnabled: true,
                sortIndex: 0,
                credentialReference: "credential.cloudflare",
                includeInGlobalRefresh: true
            )
        )
        context.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                isEnabled: true,
                sortIndex: 1,
                credentialReference: "credential.openai",
                includeInGlobalRefresh: false
            )
        )
        context.insert(
            SubscriptionRecord(
                domain: MonthlySubscription(
                    name: "ChatGPT Plus",
                    amount: Money(usd: Decimal(string: "20")!),
                    period: .monthly,
                    anchorDate: date(2026, 8, 3),
                    providerID: .openai,
                    quantity: 3
                ),
                calendar: utcCalendar
            )
        )
        context.insert(
            try SnapshotRecord(
                domain: Snapshot(
                    providerID: .cloudflare,
                    accountID: AccountID.fixture(for: .cloudflare),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: now,
                    periodEnd: now,
                    currentSpendUSD: Money(roundedUSD: 11.05)
                ),
                calendar: utcCalendar
            )
        )
        try AppPreferencesRecord.save(
            AppPreferences(
                includeAWSInGlobalRefresh: true,
                isDemoModeEnabled: true,
                isReminderEnabled: true,
                reminderSchedule: ReminderSchedule(frequency: .daily, hour: 9, minute: 15),
                appearance: .dark,
                hasCompletedOnboarding: true,
                providerHistoryRange: .months12,
                hidesCat: true,
                refreshesUsageOnActivate: true,
                displayCurrency: "CNY",
                seenUsageGuideIDs: ["heroExcludesSubscriptions", "awsRefreshCostsMoney"]
            ),
            to: context
        )
        return Store(container: container, credentials: credentials)
    }

    private func makeDestinationStoreWithNoise() throws -> Store {
        let credentials = InMemoryCredentialStore()
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try credentials.save("old-neon-secret", reference: "credential.neon")
        context.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .neon),
                providerID: .neon,
                isEnabled: true,
                sortIndex: 0,
                credentialReference: "credential.neon"
            )
        )
        context.insert(
            try SnapshotRecord(
                domain: Snapshot(
                    providerID: .neon,
                    accountID: AccountID.fixture(for: .neon),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: now,
                    periodEnd: now,
                    currentSpendUSD: Money(roundedUSD: 3.13)
                ),
                calendar: utcCalendar
            )
        )
        context.insert(
            SubscriptionRecord(
                domain: MonthlySubscription(
                    name: "旧订阅",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: date(2026, 1, 1)
                ),
                calendar: utcCalendar
            )
        )
        try TipRecord.upsert(
            transactionID: "keep-me",
            productID: "com.zhechengqi.tollcat.tip.small",
            displayPrice: "6.00",
            purchasedAt: now,
            jws: "jws",
            appVersion: "0.1.0",
            in: context
        )
        try context.save()
        return Store(container: container, credentials: credentials)
    }

    private func makeEmptyStore() throws -> Store {
        Store(
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore()
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return utcCalendar.date(from: components)!
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private struct Store {
        var container: ModelContainer
        var credentials: InMemoryCredentialStore
    }
}
