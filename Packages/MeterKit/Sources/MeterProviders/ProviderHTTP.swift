import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// 真实适配器共用的出网入口：只读请求、状态码映射只走 `ProviderError`。
/// 出站白名单由真正的出网边界（live 传输层的 HTTPClient）把守，这里不再查第二遍。
enum ProviderHTTP: Sendable {
    static func get(
        url: URL,
        headers: [String: String],
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> Data {
        try await send(
            method: "GET",
            url: url,
            headers: headers,
            body: nil,
            client: client,
            providerID: providerID
        ).0
    }

    static func getResponse(
        url: URL,
        headers: [String: String],
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> (Data, HTTPURLResponse) {
        try await send(
            method: "GET",
            url: url,
            headers: headers,
            body: nil,
            client: client,
            providerID: providerID
        )
    }

    static func post(
        url: URL,
        headers: [String: String],
        body: Data,
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> Data {
        try await send(
            method: "POST",
            url: url,
            headers: headers,
            body: body,
            client: client,
            providerID: providerID
        ).0
    }

    private static func send(
        method: String,
        url: URL,
        headers: [String: String],
        body: Data?,
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // 各家都要 JSON，统一在这里声明，适配器不用逐个抄。
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.send(request)
        } catch let error as ProviderError {
            throw error
        } catch {
            throw ProviderError.networkFailure(providerID: providerID)
        }

        if let mapped = ProviderError.fromHTTPStatus(response.statusCode, providerID: providerID) {
            throw mapped
        }
        return (data, response)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        providerID: ProviderID
    ) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ProviderError.malformedResponse(providerID: providerID)
        }
    }
}
