import Foundation
import Observation
import MeterCore
import MeterPersistence
import MeterProviders

@MainActor
@Observable
final class SetupWizardModel {
    enum Mode: Hashable, Sendable {
        case create(ProviderID)
        // 带上 ProviderID：入口本来就知道是哪家，构造时不查表、更不默认 Cloudflare。
        case rotate(AccountID, ProviderID)
    }

    let mode: Mode
    let providerID: ProviderID
    /// 信箱接到已经手填过的那份用量上。
    let attachingAccountID: AccountID?
    var step: SetupWizardStep = .guide
    var fieldValues: [String: String] = [:]
    var isTesting = false
    var isSaving = false
    var didAttemptTest = false
    /// 测通之后又改了字段。点「测试连接」本身不算改过。
    private(set) var needsRetest = false
    var saveToken = 0
    var copyToken = 0
    /// 测试连接失败时加一，给错误触觉。字段校验失败不加。
    var testFailureToken = 0
    var fieldErrors: [String: String] = [:]
    /// 加第二份时：已有账号的昵称框。空昵称预填「账号 1」。
    var siblingNickname = ""
    /// 加第二份时：新账号昵称，必填、无预填。
    var newNickname = ""
    private(set) var saveFailureCaption: String?
    private(set) var outcome: SetupVerifyOutcome?
    /// 这次测试发出去的 HTTP。生产 UI 默认不展示；反馈开关打开才出站。
    private(set) var capturedExchanges: [HTTPExchange] = []
    #if DEBUG
    var debugExchanges: [HTTPExchange] { capturedExchanges }
    #endif
    private(set) var verifiedSnapshot: Snapshot?
    private(set) var guide: SetupGuide
    private(set) var notices: [Notice] = []
    private(set) var catalog: Catalog
    private(set) var fingerprintCollisionReason: String?

    var dashboard: DashboardModel
    private let catalogSource: any CatalogSource

    var rotatingAccountID: AccountID? {
        if case .rotate(let id, _) = mode { return id }
        return nil
    }

    var descriptor: ProviderDescriptor? {
        ProviderCatalog.descriptor(id: providerID)
    }

    var displayName: String {
        descriptor?.displayName ?? providerID.rawValue
    }

    var colorKey: String {
        descriptor?.colorKey ?? providerID.rawValue
    }

    var credentialSetupURL: URL? {
        descriptor?.credentialSetupURL
    }

    var usesInbox: Bool {
        descriptor?.supportsInboxIngest == true
    }

    var siblingConnections: [ProviderConnectionState] {
        dashboard.connectionStates().filter {
            $0.providerID == providerID && $0.accountID != rotatingAccountID
        }
    }

    var showsNicknameFields: Bool {
        if case .rotate = mode { return false }
        return siblingConnections.count >= 1
    }

    var existingSibling: ProviderConnectionState? {
        siblingConnections.sorted { $0.sortIndex < $1.sortIndex }.first
    }

    var trimmedNewNickname: String {
        newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSiblingNickname: String {
        siblingNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        guard fingerprintCollisionReason == nil else { return false }
        guard let verifiedSnapshot, verifiedSnapshot.hasBillableMetrics else {
            return false
        }
        if showsNicknameFields, trimmedNewNickname.isEmpty {
            return false
        }
        return !isTesting && !isSaving
    }

    /// 理论支持的服务，测完（成功或失败）在凭据下面出一节反馈。
    var showsSetupFeedback: Bool {
        guard !isTesting, outcome != nil else { return false }
        return SetupProviderFacts.offersSetupFeedback(for: descriptor)
    }

    /// 测通且没撞车：底栏主按钮从「测试连接」变成「保存到 Keychain」。
    /// 撞车时主按钮整颗拿掉，只留原因。
    var showsSavePrimaryAction: Bool {
        fingerprintCollisionReason == nil && verifiedSnapshot != nil
    }

    var isCredentialPrimaryEnabled: Bool {
        if showsSavePrimaryAction {
            return canSave
        }
        // 测试进行中不要 disabled：系统会把按钮洗成灰，绿色铺色就没了。
        if isTesting { return true }
        return !isSaving && allFieldsFilled
    }

    /// 文本框空着时「测试连接」该是灰的，不要点下去才报请填写。
    var allFieldsFilled: Bool {
        guide.fields.allSatisfy { field in
            !trimmedValue(for: field.key).isEmpty
        }
    }

    var saveBlockedReason: String? {
        if isTesting { return nil }
        if let fingerprintCollisionReason { return fingerprintCollisionReason }
        guard !canSave else { return nil }
        if showsNicknameFields, trimmedNewNickname.isEmpty, verifiedSnapshot != nil {
            return String(localized: L("第二份账号需要一个昵称，用来和已有的区分开。"))
        }
        if needsRetest {
            return String(localized: L("凭据改过了，请再测一次再保存。"))
        }
        return nil
    }

    var showsDuplicateOrgWarning: Bool {
        showsNicknameFields
            && verifiedSnapshot != nil
            && AccountFingerprint.hash(providerID: providerID, fields: fieldValues) == nil
            && fingerprintCollisionReason == nil
    }

    var fieldsAreValid: Bool {
        fieldErrors.isEmpty && guide.fields.allSatisfy { field in
            !trimmedValue(for: field.key).isEmpty
        }
    }

    init(
        mode: Mode,
        dashboard: DashboardModel,
        catalogSource: (any CatalogSource)? = nil,
        attachingAccountID: AccountID? = nil
    ) {
        self.mode = mode
        self.dashboard = dashboard
        self.attachingAccountID = attachingAccountID
        switch mode {
        case .create(let id):
            self.providerID = id
            self.step = .guide
        case .rotate(_, let providerID):
            self.providerID = providerID
            self.step = .guide
        }
        self.catalogSource = catalogSource ?? dashboard.catalogResolver
        // 第一帧就用仪表已经握着的目录。空着等 prepare，连接参考会先画
        // 「说明还没写好」，量一次矮高度，正文进来再撑高，抽屉容易被系统收掉。
        let seeded = Self.catalogMaterials(dashboard.catalog, providerID: self.providerID)
        self.catalog = seeded.catalog
        self.guide = seeded.guide
        self.notices = seeded.notices
        prepareNicknameDraft()
    }

    convenience init(
        providerID: ProviderID,
        dashboard: DashboardModel,
        catalogSource: (any CatalogSource)? = nil
    ) {
        self.init(mode: .create(providerID), dashboard: dashboard, catalogSource: catalogSource)
    }

    func prepare() async {
        do {
            applyCatalog(try await catalogSource.load())
        } catch {
            // 仪表目录已经铺过第一帧。再写成空目录会把连接参考抽成「说明还没写好」。
            if guide.parts.isEmpty {
                applyCatalog(
                    Catalog(
                        schemaVersion: CatalogCodec.supportedSchemaVersion,
                        updatedAt: .distantPast,
                        guides: [:],
                        plans: [],
                        notices: []
                    )
                )
            }
        }
        prefillExistingFields()
        prepareNicknameDraft()
        validateFields()
    }

    private func applyCatalog(_ catalog: Catalog) {
        let materials = Self.catalogMaterials(catalog, providerID: providerID)
        self.catalog = materials.catalog
        guide = materials.guide
        notices = materials.notices
    }

    private static func catalogMaterials(
        _ catalog: Catalog,
        providerID: ProviderID
    ) -> (catalog: Catalog, guide: SetupGuide, notices: [Notice]) {
        let localized = catalog.localized(for: CatalogDisplay.language)
        return (
            localized,
            localized.guides[providerID] ?? SetupGuide(
                parts: [],
                verifyHint: "",
                troubleshooting: []
            ),
            localized.notices.filter { $0.providerID == providerID }
        )
    }

    func advanceFromGuide() {
        step = .credentials
    }

    func returnToGuide() {
        step = .guide
    }

    func updateField(_ key: String, value: String) {
        let previous = fieldValues[key] ?? ""
        // TextField 失焦常会把同一串写回来。那不是改凭据，不能把测通作废。
        guard previous != value else { return }
        fieldValues[key] = value
        if verifiedSnapshot != nil {
            needsRetest = true
        }
        verifiedSnapshot = nil
        outcome = nil
        capturedExchanges = []
        saveFailureCaption = nil
        fingerprintCollisionReason = nil
        validateFields()
    }

    func copy(_ text: String) {
        SystemClipboard.copy(text)
        copyToken += 1
    }

    func testConnection() async {
        didAttemptTest = true
        needsRetest = false
        saveFailureCaption = nil
        fingerprintCollisionReason = nil
        validateFields()
        if !guide.fields.isEmpty, !fieldsAreValid { return }
        guard !isTesting else { return }
        isTesting = true
        verifiedSnapshot = nil
        outcome = nil
        capturedExchanges = []
        defer { isTesting = false }

        let inspector = InspectingHTTPClient(wrapping: dashboard.httpClient)
        defer { capturedExchanges = inspector.exchanges }
        let clock = dashboard.clock
        // 为了记下这次往返会再组装一份 provider，必须带上同一张汇率表。
        // 默认 `SharedExchangeRates()` 只认美元，国内站人民币会误报「币种不在表里」。
        let provider = ProviderAssembly.liveProvider(
            id: providerID,
            now: { clock.now },
            calendar: clock.calendar,
            httpClient: inspector,
            rateSource: dashboard.rateSource
        ) ?? dashboard.billingProvider(for: providerID)
        guard let provider else {
            verifiedSnapshot = nil
            publish(
                SetupVerifyFormatter.outcome(
                    snapshot: nil,
                    error: ProviderError.billingAPIUnavailable(providerID: providerID),
                    troubleshooting: guide.troubleshooting,
                    calendar: dashboard.clock.calendar,
                    presentation: dashboard.moneyPresentation
                )
            )
            return
        }
        do {
            let snapshot = try await provider.fetch(credential: makeCredential())
            verifiedSnapshot = snapshot.hasBillableMetrics ? snapshot : nil
            publish(
                SetupVerifyFormatter.outcome(
                    snapshot: snapshot,
                    error: nil,
                    troubleshooting: guide.troubleshooting,
                    calendar: dashboard.clock.calendar,
                    presentation: dashboard.moneyPresentation
                )
            )
            evaluateFingerprint()
        } catch {
            verifiedSnapshot = nil
            publish(
                SetupVerifyFormatter.outcome(
                    snapshot: nil,
                    error: error,
                    troubleshooting: guide.troubleshooting,
                    calendar: dashboard.clock.calendar,
                    presentation: dashboard.moneyPresentation
                )
            )
        }
    }

    func save() {
        saveFailureCaption = nil
        evaluateFingerprint()
        guard canSave, let verified = verifiedSnapshot else { return }
        isSaving = true
        defer { isSaving = false }
        let fingerprint = AccountFingerprint.hash(providerID: providerID, fields: fieldValues)
        let hint = AccountFingerprint.identityHint(from: fieldValues)
        do {
            switch mode {
            case .create:
                let siblingToRename = showsNicknameFields ? existingSibling : nil
                let id = AccountID(rawValue: UUID())
                var stamped = verified
                stamped.accountID = id
                try dashboard.applyConnection(
                    accountID: id,
                    providerID: providerID,
                    nickname: showsNicknameFields ? trimmedNewNickname : nil,
                    identityHint: hint,
                    remoteIdentityFingerprint: fingerprint,
                    fields: fieldValues,
                    snapshots: [stamped],
                    mode: .create
                )
                if let siblingToRename {
                    let name = trimmedSiblingNickname.isEmpty
                        ? String(localized: L("账号 1"))
                        : trimmedSiblingNickname
                    try dashboard.updateAccountNickname(name, for: siblingToRename.accountID)
                }
                saveToken += 1
                Task { await dashboard.backfillHistory(accountID: id) }
            case .rotate(let accountID, _):
                var stamped = verified
                stamped.accountID = accountID
                try dashboard.applyConnection(
                    accountID: accountID,
                    providerID: providerID,
                    nickname: nil,
                    identityHint: hint,
                    remoteIdentityFingerprint: fingerprint,
                    fields: fieldValues,
                    snapshots: [stamped],
                    mode: .rotate
                )
                saveToken += 1
            }
        } catch {
            saveFailureCaption = String(localized: L("没法写进 Keychain。设备解锁后再试一次。"))
        }
    }

    private func prepareNicknameDraft() {
        guard showsNicknameFields, let sibling = existingSibling else { return }
        if siblingNickname.isEmpty {
            let existing = sibling.nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            siblingNickname = existing.isEmpty ? String(localized: L("账号 1")) : existing
        }
    }

    private func evaluateFingerprint() {
        fingerprintCollisionReason = nil
        let fingerprint = AccountFingerprint.hash(providerID: providerID, fields: fieldValues)
        if case .rotate(let accountID, _) = mode {
            let old = dashboard.connectionStates().first { $0.accountID == accountID }?
                .remoteIdentityFingerprint
            if let fingerprint, let old, fingerprint != old {
                fingerprintCollisionReason = String(localized: L("这不是换密钥，是换远程账号。请再加一份。"))
                return
            }
        }
        if let hit = dashboard.collidingConnection(
            providerID: providerID,
            fingerprint: fingerprint,
            fields: fieldValues,
            excluding: rotatingAccountID
        ) {
            let vendor = displayName
            let title = AccountTitle.context(
                for: hit.accountID,
                connections: dashboard.connectionStates(),
                providerDisplayName: vendor
            )
            let name = hit.nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
            let shown = (name?.isEmpty == false ? name! : title.visual)
            fingerprintCollisionReason = String(localized: L("这把凭据已经接入为「\(shown)」。"))
        }
    }

    private func prefillExistingFields() {
        guard case .rotate(let accountID, _) = mode else { return }
        let stored = dashboard.storedFields(for: accountID)
        for field in guide.fields {
            if field.isSecret {
                fieldValues[field.key] = ""
            } else {
                fieldValues[field.key] = stored[field.key] ?? fieldValues[field.key] ?? ""
            }
        }
    }

    private func validateFields() {
        var errors: [String: String] = [:]
        for field in guide.fields {
            if let message = field.errorMessage(for: fieldValues[field.key, default: ""]) {
                errors[field.key] = message
            }
        }
        fieldErrors = errors
    }

    private func trimmedValue(for key: String) -> String {
        fieldValues[key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeCredential() -> Credential {
        let raw = (try? StoredCredentialFields.encode(fieldValues)) ?? "{}"
        return (try? StoredCredentialFields.credential(providerID: providerID, raw: raw))
            ?? Credential(providerID: providerID, fields: [:])
    }

    func applyLaunchOutcome(_ raw: String?) {
        guard let raw else { return }
        didAttemptTest = true
        needsRetest = false
        switch raw {
        case "success":
            fieldValues = SetupFieldPreviewValue.dictionary(for: guide.fields)
            let calendar = dashboard.clock.calendar
            let now = dashboard.clock.now
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? now
            let snapshot = Snapshot(
                providerID: providerID,
                kind: descriptor?.kind ?? .usage,
                fetchedAt: now,
                periodStart: start,
                periodEnd: end,
                currentSpendUSD: Money(roundedUSD: 11.05),
                dailyUSD: [:]
            )
            verifiedSnapshot = snapshot
            publish(
                SetupVerifyFormatter.outcome(
                    snapshot: snapshot,
                    error: nil,
                    troubleshooting: guide.troubleshooting,
                    calendar: dashboard.clock.calendar,
                    presentation: dashboard.moneyPresentation
                )
            )
            evaluateFingerprint()
        case "401":
            publish(httpOutcome(status: 401))
        case "403":
            publish(httpOutcome(status: 403))
        case "network":
            publish(.network)
        case "empty":
            publish(.emptyReading)
        case "unknown":
            publish(.unknown)
        default:
            break
        }
    }

    private func publish(_ outcome: SetupVerifyOutcome) {
        self.outcome = outcome
        if case .success = outcome { return }
        testFailureToken += 1
    }

    private func httpOutcome(status: Int) -> SetupVerifyOutcome {
        if let match = guide.troubleshooting.first(where: { $0.httpStatus == status }) {
            return .http(match)
        }
        return .http(
            ErrorCase(
                httpStatus: status,
                explanation: status == 401
                    ? String(localized: L("这个 token 无效，或者已经被撤销了。"))
                    : String(localized: L("这个 token 缺权限，所以读不到账单。")),
                nextStep: String(localized: L("回上一步检查权限后再测一次。"))
            )
        )
    }

    static func preview(
        providerID: ProviderID = .cloudflare,
        step: SetupWizardStep = .guide,
        outcome: SetupVerifyOutcome? = nil
    ) -> SetupWizardModel {
        let model = SetupWizardModel(providerID: providerID, dashboard: .preview)
        model.step = step
        model.outcome = outcome
        if case .success = outcome {
            model.fieldValues = SetupFieldPreviewValue.dictionary(for: model.guide.fields)
            model.verifiedSnapshot = Snapshot(
                providerID: providerID,
                kind: .usage,
                fetchedAt: model.dashboard.clock.now,
                periodStart: model.dashboard.clock.now,
                periodEnd: model.dashboard.clock.now,
                currentSpendUSD: Money(roundedUSD: 11.05)
            )
        }
        return model
    }
}
