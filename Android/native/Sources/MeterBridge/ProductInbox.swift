import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterProviders

/// 读数信箱。App 只建箱、取回、签/吊销投递 key，不投递。
package enum ProductInbox {
    package static func createJson() -> String {
        request(url: URL(string: "https://api.tollcat.app/v1/inbox")!, method: "POST", bearer: nil, body: "{}")
    }

    package static func deleteJson(readKey: String) -> String {
        request(url: URL(string: "https://api.tollcat.app/v1/inbox")!, method: "DELETE", bearer: readKey, body: nil)
    }

    package static func readingsJson(readKey: String) -> String {
        request(url: URL(string: "https://api.tollcat.app/v1/readings")!, method: "GET", bearer: readKey, body: nil)
    }

    package static func listKeysJson(readKey: String) -> String {
        request(url: URL(string: "https://api.tollcat.app/v1/inbox/ingest-keys")!, method: "GET", bearer: readKey, body: nil)
    }

    package static func mintKeyJson(readKey: String, label: String) -> String {
        let payload = JNIJSON.stringify(["label": label])
        return request(
            url: URL(string: "https://api.tollcat.app/v1/inbox/ingest-keys")!,
            method: "POST",
            bearer: readKey,
            body: payload
        )
    }

    package static func revokeKeyJson(readKey: String, keyID: String) -> String {
        let encoded = keyID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? keyID
        return request(
            url: URL(string: "https://api.tollcat.app/v1/inbox/ingest-keys/\(encoded)")!,
            method: "DELETE",
            bearer: readKey,
            body: nil
        )
    }

    private static func request(url: URL, method: String, bearer: String?, body: String?) -> String {
        do {
            let pair: (Data, Int) = try JNIAsync.run {
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.timeoutInterval = 20
                if method != "GET" {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = (body ?? "{}").data(using: .utf8)
                }
                if let bearer, !bearer.isEmpty {
                    request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
                }
                let (data, response) = try await LiveHTTPTransport.make().send(request)
                return (data, response.statusCode)
            }
            let status = pair.1
            if status == 429 {
                return JNIJSON.stringify(["ok": false, "rateLimited": true, "status": 429])
            }
            let parsed = JNIJSON.parse(String(data: pair.0, encoding: .utf8) ?? "")
            var object: [String: Any] = ["ok": (200..<300).contains(status), "status": status]
            if let parsed {
                object["body"] = parsed
            }
            return JNIJSON.stringify(object)
        } catch {
            return JNIJSON.stringify(["ok": false, "error": String(describing: error)])
        }
    }
}
