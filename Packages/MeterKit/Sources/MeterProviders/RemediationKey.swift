import Foundation

/// 修复建议的稳定 key。拼中文是展示层和 catalog 的事，对照 SPEC 第 12.5 节对 Fact 的处理。
public enum RemediationKey: String, Hashable, Sendable, Codable {
    /// 401：key 填错了，回向导重新创建。
    case invalidCredentials
    /// 403：key 权限不够，回上一步检查 scope。
    case insufficientPermissions
    case networkUnavailable
    case fixtureUnavailable
    /// 429：先等一等，不要连点刷新。
    case rateLimited
    /// 5xx：对方挂了，过一会儿再试。
    case serviceUnavailable
    /// 200 但 JSON 对不上文档，或必填字段缺失。
    case malformedResponse
    /// 币种不在汇率表里，没法折成美元。
    case unsupportedCurrency
    /// 向导该填的字段空了。
    case missingCredential
    /// 404 / 接口对这个账号不存在（例如还没切到新账单平台）。
    case billingAPIUnavailable
}
