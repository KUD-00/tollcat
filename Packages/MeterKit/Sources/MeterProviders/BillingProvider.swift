import Foundation
import MeterCore

/// 一家账单源。有公开只读账单接口的各占一个类型。
///
/// 构造一律吃 `HTTPClient`。App 注入真传输；单测注入 `StubHTTPClient`。
public protocol BillingProvider: Sendable {
    func fetch(credential: Credential) async throws -> Snapshot
    func fetch(credential: Credential, horizon: BillingFetchHorizon) async throws -> Snapshot
}

extension BillingProvider {
    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        try await fetch(credential: credential)
    }
}
