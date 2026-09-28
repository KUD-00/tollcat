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

    /// keyID 只能是一个路径段，字符集与 Worker 路由一致（`[A-Za-z0-9_-]{1,64}`）。
    /// 按 urlPathAllowed 编码不转义 `/`：`..` 会把带读钥的 DELETE 改写到 `/v1/inbox`，
    /// 等于把整个信箱删掉。不合规的直接拒绝，不发请求。
    package static func revokeKeyJson(readKey: String, keyID: String) -> String {
        guard isIngestKeyID(keyID),
              let url = URL(string: "https://api.tollcat.app/v1/inbox/ingest-keys/\(keyID)")
        else {
            return JNIJSON.stringify(["ok": false, "error": "invalid key id"])
        }
        return request(url: url, method: "DELETE", bearer: readKey, body: nil)
    }

    static func isIngestKeyID(_ keyID: String) -> Bool {
        (1...64).contains(keyID.utf8.count) && keyID.utf8.allSatisfy { byte in
            switch byte {
            case UInt8(ascii: "A")...UInt8(ascii: "Z"),
                 UInt8(ascii: "a")...UInt8(ascii: "z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "_"), UInt8(ascii: "-"):
                return true
            default:
                return false
            }
        }
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
