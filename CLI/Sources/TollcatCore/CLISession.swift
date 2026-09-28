import Foundation
import MeterBridge
import MeterProviders

struct CLISession {
    var ledger: JsonLedgerStore
    var vault: any CredentialVault
    var environment: [String: String]
    var localeTag: String
    var maxAge: TimeInterval
    var now: Date
    var currency: String

    func catalog() -> CatalogDocument {
        CatalogDocument.load(localeTag: localeTag)
    }

    func dashboard() -> DashboardDocument {
        let snapshots = ledger.snapshots().map(SnapshotBridge.bridgeObject(from:))
        let subscriptions = ledger.subscriptions().map(SnapshotBridge.subscriptionObject(from:))
        let json = ProductDashboard.json(
            snapshotsJSON: JNIJSON.stringify(snapshots),
            subscriptionsJSON: JNIJSON.stringify(subscriptions),
            nowMillis: ProductClock.millis(now),
            currency: currency,
            localeTag: localeTag,
            filterJSON: "{}"
        )
        return DashboardDocument.parse(json)
    }

    func refresh(force: Bool) -> RefreshTally {
        let catalog = catalog()
        var ok = 0
        var fail = 0
        for account in ledger.accounts() {
            guard let provider = catalog.providers.first(where: { $0.id == account.providerId }) else {
                continue
            }
            if provider.costsMoneyToRefresh, !force {
                continue
            }
            let last = ledger.snapshots()
                .filter { $0.accountId == account.accountId }
                .map { ProductClock.date(millis: $0.fetchedAtMillis) }
                .max()
            let should = RefreshPolicy.shouldFetch(
                lastFetchedAt: last,
                now: now,
                minimumRefreshInterval: TimeInterval(provider.minimumRefreshInterval),
                maxAge: maxAge,
                force: force
            )
            guard should else { continue }
            let outcome = fetch(account: account, provider: provider)
            if outcome.ok, let snapshot = outcome.snapshot {
                ledger.replaceAccountSnapshots(accountID: account.accountId, snapshot: snapshot)
                ok += 1
            } else {
                fail += 1
            }
        }
        return RefreshTally(ok: ok, fail: fail)
    }

    func add(
        query: String,
        prompt: any PromptIO
    ) -> Result<CatalogProvider, AddError> {
        let catalog = catalog()
        guard let provider = catalog.match(query) else {
            return .failure(.unknownService(query))
        }
        guard provider.isOffered else {
            return .failure(.declined(provider))
        }
        guard provider.hasLiveFetch else {
            return .failure(.noLiveFetch(provider))
        }
        let keys = provider.fields.map(\.key)
        var fields = EnvironmentField.fields(
            providerID: provider.id,
            keys: keys,
            environment: environment
        )
        for field in provider.fields where fields[field.key] == nil {
            if !prompt.isInteractive {
                return .failure(.needEnvironment(provider))
            }
            let hint = field.hint.isEmpty ? "" : " (\(field.hint))"
            prompt.writePrompt("\(field.label)\(hint): ")
            let value = prompt.readLine(secret: field.isSecret)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if value.isEmpty {
                return .failure(.missingField(field.key))
            }
            fields[field.key] = value
        }
        let account = existingOrNewAccount(providerID: provider.id)
        if ledger.memberships().contains(where: { $0.providerId == provider.id }) == false {
            ledger.upsertMembership(
                LedgerMembership(providerId: provider.id, sortIndex: ledger.memberships().count)
            )
        }
        ledger.upsertAccount(account)
        do {
            try vault.save(JSONCredentials.encode(fields), reference: account.credentialReference)
        } catch {
            // 无 Secret Service 的 Linux 机器仍把 membership 留下，下次靠环境变量取。
        }
        let outcome = fetch(account: account, provider: provider, fields: fields)
        if outcome.ok, let snapshot = outcome.snapshot {
            ledger.replaceAccountSnapshots(accountID: account.accountId, snapshot: snapshot)
            return .success(provider)
        }
        return .failure(.fetchFailed(outcome.error ?? ""))
    }

    func remove(query: String) -> Result<CatalogProvider, AddError> {
        let catalog = catalog()
        guard let provider = catalog.match(query) else {
            return .failure(.unknownService(query))
        }
        let accounts = ledger.accounts(providerID: provider.id)
        guard ledger.memberships().contains(where: { $0.providerId == provider.id }) || !accounts.isEmpty else {
            return .failure(.notConnected(provider))
        }
        for account in accounts {
            try? vault.delete(reference: account.credentialReference)
        }
        ledger.deleteMembership(providerID: provider.id)
        return .success(provider)
    }

    private func existingOrNewAccount(providerID: String) -> LedgerAccount {
        if let existing = ledger.accounts(providerID: providerID).first {
            return existing
        }
        let accountID = UUID().uuidString
        return LedgerAccount(
            accountId: accountID,
            providerId: providerID,
            credentialReference: "acct." + accountID,
            sortIndex: 0
        )
    }

    private func fetch(
        account: LedgerAccount,
        provider: CatalogProvider,
        fields: [String: String]? = nil
    ) -> FetchOutcome {
        let merged = fields ?? loadFields(account: account, provider: provider)
        let json = ProductFetch.json(
            providerIDRaw: provider.id,
            fieldsJSON: JSONCredentials.encode(merged),
            nowMillis: ProductClock.millis(now)
        )
        let object = JNIJSON.object(json)
        let ok = object["ok"] as? Bool ?? false
        if ok, let snapshot = SnapshotBridge.ledgerRow(from: object, accountID: account.accountId) {
            var stored = snapshot
            stored.accountId = account.accountId
            return FetchOutcome(ok: true, snapshot: stored, error: nil)
        }
        return FetchOutcome(ok: false, snapshot: nil, error: object["error"] as? String)
    }

    private func loadFields(account: LedgerAccount, provider: CatalogProvider) -> [String: String] {
        let stored = JSONCredentials.decode(try? vault.read(reference: account.credentialReference))
        let env = EnvironmentField.fields(
            providerID: provider.id,
            keys: provider.fields.map(\.key),
            environment: environment
        )
        return stored.merging(env) { _, new in new }
    }
}

enum AddError: Error, Equatable {
    case unknownService(String)
    case declined(CatalogProvider)
    case noLiveFetch(CatalogProvider)
    case needEnvironment(CatalogProvider)
    case missingField(String)
    case fetchFailed(String)
    case notConnected(CatalogProvider)
}
