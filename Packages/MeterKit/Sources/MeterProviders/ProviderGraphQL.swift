import Foundation
import MeterCore

/// 只读 GraphQL。mutation 不许走这里。
enum ProviderGraphQL: Sendable {
    static func query<T: Decodable>(
        _ type: T.Type,
        url: URL,
        query: String,
        variables: [String: String] = [:],
        headers: [String: String],
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> T {
        var requestHeaders = headers
        if requestHeaders["Content-Type"] == nil {
            requestHeaders["Content-Type"] = "application/json"
        }
        let body = try encode(query: query, variables: variables, providerID: providerID)
        let data = try await ProviderHTTP.post(
            url: url,
            headers: requestHeaders,
            body: body,
            client: client,
            providerID: providerID
        )
        let envelope = try ProviderHTTP.decode(Envelope<T>.self, from: data, providerID: providerID)
        if let payload = envelope.data {
            return payload
        }
        throw mappedError(envelope.errors, providerID: providerID)
    }

    private static func encode(
        query: String,
        variables: [String: String],
        providerID: ProviderID
    ) throws -> Data {
        let payload: [String: Any] = [
            "query": query,
            "variables": variables,
        ]
        do {
            return try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw ProviderError.malformedResponse(providerID: providerID)
        }
    }

    private static func mappedError(_ errors: [GraphQLError]?, providerID: ProviderID) -> ProviderError {
        let combined = (errors ?? []).compactMap(\.message).joined(separator: " ").lowercased()
        if combined.contains("unauthor") || combined.contains("not authenticated") {
            return .unauthorized(providerID: providerID)
        }
        if combined.contains("forbidden") || combined.contains("not authorized") {
            return .forbidden(providerID: providerID)
        }
        return .malformedResponse(providerID: providerID)
    }

    private struct Envelope<T: Decodable>: Decodable {
        var data: T?
        var errors: [GraphQLError]?
    }

    private struct GraphQLError: Decodable {
        var message: String?
    }
}
