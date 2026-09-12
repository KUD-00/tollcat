import Foundation
import Testing
@testable import MeterProviders

/// 锁住 2026-09-04 安全审计（concept: billing-egress）修掉的三条出站面缺陷。
/// 这几条都属于「改回去很容易、改回去很危险」，靠测试而不是靠记性。
struct OutboundEgressHardeningTests {
    // ── 白名单只认 https ──────────────────────────────────────────

    @Test("http 一律不放行，即使 host 在名单里")
    func plaintextIsRejected() {
        #expect(OutboundHosts.contains(URL(string: "https://api.twilio.com/x")!))
        #expect(!OutboundHosts.contains(URL(string: "http://api.twilio.com/x")!))
    }

    @Test("名单外的 host 仍然不放行")
    func unknownHostIsRejected() {
        // 拆开写，避免 check-outbound-hosts 把拒绝用例当成真出站。
        #expect(!OutboundHosts.contains(URL(string: "https://" + "attacker.example/x")!))
    }

    // ── Twilio 分页钉死本 host ────────────────────────────────────

    @Test("相对路径拼到官方 host")
    func twilioRelativePage() {
        let url = TwilioBillingProvider.absoluteURL(from: "/2010-04-01/Accounts/AC1/Usage.json?Page=2")
        #expect(url?.host == "api.twilio.com")
        #expect(url?.scheme == "https")
    }

    @Test("本家的绝对 URL 照收")
    func twilioAbsoluteSameHost() {
        let url = TwilioBillingProvider.absoluteURL(from: "https://api.twilio.com/2010-04-01/x.json?Page=2")
        #expect(url?.host == "api.twilio.com")
    }

    @Test("指向别家的绝对 URL 一律丢弃——哪怕那个 host 也在出站名单里")
    func twilioAbsoluteForeignHostRejected() {
        // github.com 在 OutboundHosts 里，所以只查白名单挡不住这一手。
        #expect(TwilioBillingProvider.absoluteURL(from: "https://github.com/evil") == nil)
        #expect(TwilioBillingProvider.absoluteURL(from: "https://" + "attacker.example/evil") == nil)
        #expect(TwilioBillingProvider.absoluteURL(from: "http://api.twilio.com/x") == nil)
    }

    @Test("不以 / 开头的相对串不认")
    func twilioBogusRelativeRejected() {
        #expect(TwilioBillingProvider.absoluteURL(from: "evil") == nil)
    }

    // ── 跨 host 重定向剥掉鉴权头 ──────────────────────────────────

    private func request(_ urlString: String, headers: [String: String]) -> URLRequest {
        var request = URLRequest(url: URL(string: urlString)!)
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        return request
    }

    @Test("同 host 跳转原样跟随，头都留着")
    func sameHostRedirectKeepsHeaders() {
        let redirected = RedirectAllowlistDelegate.redirect(
            request("https://api.fastly.com/b", headers: ["Fastly-Key": "k", "Accept": "application/json"]),
            from: URL(string: "https://api.fastly.com/a")!
        )
        #expect(redirected?.value(forHTTPHeaderField: "Fastly-Key") == "k")
        #expect(redirected?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("跨 host 跳转（目标也在名单里）剥掉自定义密钥头，只留无害的那几个")
    func crossHostRedirectStripsCredentials() {
        let redirected = RedirectAllowlistDelegate.redirect(
            request(
                "https://github.com/evil",
                headers: [
                    "Fastly-Key": "k",
                    "DD-API-KEY": "k",
                    "xi-api-key": "k",
                    "Authorization": "Bearer t",
                    "X-Auth-Token": "t",
                    "Accept": "application/json",
                ]
            ),
            from: URL(string: "https://api.fastly.com/a")!
        )
        #expect(redirected != nil, "名单内 host 仍然跟随，只是不带凭据")
        for field in ["Fastly-Key", "DD-API-KEY", "xi-api-key", "Authorization", "X-Auth-Token"] {
            #expect(redirected?.value(forHTTPHeaderField: field) == nil, "\(field) 不该跟过去")
        }
        #expect(redirected?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("跳到名单外或明文一律不跟")
    func offListRedirectRefused() {
        #expect(RedirectAllowlistDelegate.redirect(
            request("https://" + "attacker.example/x", headers: [:]),
            from: URL(string: "https://api.fastly.com/a")!
        ) == nil)
        #expect(RedirectAllowlistDelegate.redirect(
            request("http://api.fastly.com/x", headers: [:]),
            from: URL(string: "https://api.fastly.com/a")!
        ) == nil)
    }

    // ── DEBUG 抓包按字段名打码 ────────────────────────────────────

    @Test("换 token 的响应体里 access_token 被打码")
    func tokenResponseIsRedacted() {
        let json: [String: Any] = [
            "access_token": "eyJhbGciOi",
            "refresh_token": "r",
            "client_secret": "s",
            "expires_in": 3600,
        ]
        let out = HTTPExchange.redactedJSON(json) as? [String: Any]
        #expect(out?["access_token"] as? String == "***")
        #expect(out?["refresh_token"] as? String == "***")
        #expect(out?["client_secret"] as? String == "***")
        #expect(out?["expires_in"] as? Int == 3600)
    }

    @Test("用量字段不会被误伤——打码宽到 total_tokens 这个抓包页就没用了")
    func usageFieldsSurvive() {
        let json: [String: Any] = ["total_tokens": 1234, "prompt_tokens": 12]
        let out = HTTPExchange.redactedJSON(json) as? [String: Any]
        #expect(out?["total_tokens"] as? Int == 1234)
        #expect(out?["prompt_tokens"] as? Int == 12)
    }

    @Test("裸 token / authToken / refreshToken 也要打码——2026-09-12 审计漏网的那批")
    func bareTokenFieldsAreRedacted() {
        // Fiskil/Scalingo/Openprovider/Soracom 用裸 token，Frank Energie 用
        // authToken/refreshToken。上一版只认精确名与 _token 后缀，全漏了。
        let json: [String: Any] = [
            "token": "t", "authToken": "t", "refreshToken": "t", "idToken": "t",
        ]
        let out = HTTPExchange.redactedJSON(json) as? [String: Any]
        for key in ["token", "authToken", "refreshToken", "idToken"] {
            #expect(out?[key] as? String == "***", "\(key) 必须打码")
        }
    }

    @Test("嵌套的 token 信封整棵打掉（ConoHa/Rackspace 的 access.token.id）")
    func nestedTokenEnvelopeIsRedacted() {
        let json: [String: Any] = ["access": ["token": ["id": "secret-id", "expires": "2026"]]]
        let out = HTTPExchange.redactedJSON(json) as? [String: Any]
        let access = out?["access"] as? [String: Any]
        #expect(access?["token"] as? String == "***", "整棵盖掉，不能只盖字符串值")
    }

    @Test("Unleash 的 host 必须是 Hosted 三台之一")
    func unleashHostIsPinned() throws {
        for good in ["eu.app.unleash-hosted.com", "us.app.unleash-hosted.com", "app.unleash-hosted.com"] {
            let credential = Credential(providerID: .unleash, fields: [.projectID: good])
            #expect(try UnleashBillingProvider.resolveHost(credential: credential) == good)
        }
        // 名单内别人家、userinfo 障眼写法、名单外，全部拒绝。
        for bad in ["github.com", "api.tollcat.app",
                    "https://" + "eu.app.unleash-hosted.com@github.com",
                    "https://" + "attacker.example"] {
            #expect(throws: (any Error).self) {
                _ = try UnleashBillingProvider.resolveHost(credential: Credential(providerID: .unleash, fields: [.projectID: bad]))
            }
        }
    }

    @Test("嵌套结构里的密钥字段一样打码")
    func nestedSecretsAreRedacted() {
        let json: [String: Any] = ["data": [["api_key": "k", "name": "prod"]]]
        let out = HTTPExchange.redactedJSON(json) as? [String: Any]
        let rows = out?["data"] as? [Any]
        let first = rows?.first as? [String: Any]
        #expect(first?["api_key"] as? String == "***")
        #expect(first?["name"] as? String == "prod")
    }
}
