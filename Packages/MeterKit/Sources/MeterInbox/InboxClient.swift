import Foundation
import MeterCore

/// 传输层接缝。和 `HTTPClient` 同一个用意：真实实现只有一个，测试打在这里。
public protocol InboxTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// 读数信箱的全部操作。只读 + 建/删/轮换，没有任何写读数的方法 ——
/// **App 不投递,只取回。** 投递是用户在自己机器上用 ingest key 干的事。
public struct InboxClient: Sendable {
    public var transport: any InboxTransport

    public init(transport: any InboxTransport) {
        self.transport = transport
    }

    /// 建一个新信箱。返回里的 `ingestKey` 只此一次，展示完就丢。
    public func createInbox() async throws -> InboxProvisioning {
        let data = try await send(url: InboxEndpoint.inboxURL, method: "POST", bearer: nil)
        let payload = try decode(InboxProvisioningResponse.self, from: data)
        guard !payload.mailbox.isEmpty, !payload.readKey.isEmpty,
              !payload.ingestKey.isEmpty, !payload.ingestKeyID.isEmpty else {
            throw InboxError(code: .malformedResponse)
        }
        return InboxProvisioning(
            credentials: InboxCredentials(mailbox: payload.mailbox, readKey: payload.readKey),
            ingestKey: IssuedIngestKey(id: payload.ingestKeyID, secret: payload.ingestKey)
        )
    }

    public func fetchReadings(
        readKey: String,
        calendar: Calendar
    ) async throws -> [InboxReading] {
        let data = try await send(
            url: InboxEndpoint.readingsURL,
            method: "GET",
            bearer: readKey
        )
        let payload = try decode(InboxReadingsResponse.self, from: data)
        return (payload.readings ?? []).compactMap { Self.reading(from: $0, calendar: calendar) }
    }

    /// 签一把新的投递 key。**不吊销任何旧的。**
    ///
    /// 轮换是三步：签新的 → 改完脚本 → 吊销旧的。中间那段两把都能用，
    /// 所以不会出现「改到一半全断」。一把一个脚本，`label` 记它是谁。
    public func mintIngestKey(
        readKey: String,
        label: String?
    ) async throws -> IssuedIngestKey {
        let body = label.map { ["label": $0] }
        let data = try await send(
            url: InboxEndpoint.ingestKeysURL,
            method: "POST",
            bearer: readKey,
            jsonBody: body
        )
        let payload = try decode(InboxIngestKeyResponse.self, from: data)
        guard !payload.ingestKey.isEmpty, !payload.ingestKeyID.isEmpty else {
            throw InboxError(code: .malformedResponse)
        }
        return IssuedIngestKey(id: payload.ingestKeyID, secret: payload.ingestKey)
    }

    /// 只回元数据。服务端只有哈希，key 本身谁也拿不回来。
    public func listIngestKeys(readKey: String) async throws -> [IngestKeyInfo] {
        let data = try await send(
            url: InboxEndpoint.ingestKeysURL,
            method: "GET",
            bearer: readKey
        )
        let payload = try decode(InboxIngestKeyListResponse.self, from: data)
        return (payload.keys ?? []).compactMap { row in
            guard let id = row.id, !id.isEmpty else { return nil }
            return IngestKeyInfo(
                id: id,
                label: row.label,
                createdAt: row.createdAt.flatMap { InboxDateParser.instant($0) } ?? .distantPast,
                lastUsedAt: row.lastUsedAt.flatMap { InboxDateParser.instant($0) }
            )
        }
    }

    public func revokeIngestKey(readKey: String, id: String) async throws {
        _ = try await send(
            url: InboxEndpoint.ingestKeyURL(id: id),
            method: "DELETE",
            bearer: readKey
        )
    }

    public func deleteInbox(readKey: String) async throws {
        _ = try await send(url: InboxEndpoint.inboxURL, method: "DELETE", bearer: readKey)
    }

    /// 解不出来的行整条丢掉，不要让一条坏数据把整次取回废掉。
    /// 缺 `ingestKeyID` 的行同样丢：没有归属的读数没有任何账号能认领。
    static func reading(from payload: InboxReadingPayload, calendar: Calendar) -> InboxReading? {
        guard let provider = payload.provider?.trimmingCharacters(in: .whitespacesAndNewlines),
              !provider.isEmpty,
              let ingestKeyID = payload.ingestKeyID, !ingestKeyID.isEmpty,
              let periodRaw = payload.periodStart,
              let periodStart = InboxDateParser.day(periodRaw, calendar: calendar) else {
            return nil
        }
        let amount = payload.currentSpendUSD
            .flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
        return InboxReading(
            providerID: ProviderID(provider),
            ingestKeyID: ingestKeyID,
            periodStart: periodStart,
            currentSpendUSD: amount.map(Money.init(usd:)),
            reportedAt: payload.reportedAt
                .flatMap { InboxDateParser.instant($0) } ?? periodStart
        )
    }

    private func send(
        url: URL,
        method: String,
        bearer: String?,
        jsonBody: [String: String]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearer {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        if method == "POST" {
            // Worker 对 POST 卡 content-type，空体也要带上。
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoded = jsonBody.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
            request.httpBody = encoded ?? Data("{}".utf8)
        }

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let error as InboxError {
            throw error
        } catch {
            throw InboxError(code: .unreachable)
        }
        if let mapped = InboxError.fromHTTPStatus(response.statusCode) {
            throw mapped
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw InboxError(code: .malformedResponse)
        }
    }
}
