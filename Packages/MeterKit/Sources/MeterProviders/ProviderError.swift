import Foundation
import MeterCore

/// 取数失败。带 HTTP 状态、是哪家、以及可操作的修复建议 key，不带拼好的中文。
public struct ProviderError: Error, Hashable, Sendable {
    public var providerID: ProviderID
    public var httpStatus: Int?
    public var code: Code
    public var remediationKey: RemediationKey

    public enum Code: String, Hashable, Sendable, Codable {
        case unauthorized
        case forbidden
        case networkFailure
        case fixtureUnavailable
        case rateLimited
        case serviceUnavailable
        case malformedResponse
        case unsupportedCurrency
        case missingCredential
        case billingAPIUnavailable
    }

    public init(
        providerID: ProviderID,
        httpStatus: Int?,
        code: Code,
        remediationKey: RemediationKey
    ) {
        self.providerID = providerID
        self.httpStatus = httpStatus
        self.code = code
        self.remediationKey = remediationKey
    }

    public static func unauthorized(providerID: ProviderID) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: 401,
            code: .unauthorized,
            remediationKey: .invalidCredentials
        )
    }

    public static func forbidden(providerID: ProviderID) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: 403,
            code: .forbidden,
            remediationKey: .insufficientPermissions
        )
    }

    public static func networkFailure(providerID: ProviderID, httpStatus: Int? = nil) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: httpStatus,
            code: .networkFailure,
            remediationKey: .networkUnavailable
        )
    }

    public static func fixtureUnavailable(providerID: ProviderID) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: nil,
            code: .fixtureUnavailable,
            remediationKey: .fixtureUnavailable
        )
    }

    public static func rateLimited(providerID: ProviderID) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: 429,
            code: .rateLimited,
            remediationKey: .rateLimited
        )
    }

    public static func serviceUnavailable(providerID: ProviderID, httpStatus: Int) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: httpStatus,
            code: .serviceUnavailable,
            remediationKey: .serviceUnavailable
        )
    }

    public static func malformedResponse(providerID: ProviderID, httpStatus: Int? = 200) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: httpStatus,
            code: .malformedResponse,
            remediationKey: .malformedResponse
        )
    }

    public static func unsupportedCurrency(providerID: ProviderID) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: 200,
            code: .unsupportedCurrency,
            remediationKey: .unsupportedCurrency
        )
    }

    public static func missingCredential(providerID: ProviderID) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: nil,
            code: .missingCredential,
            remediationKey: .missingCredential
        )
    }

    public static func billingAPIUnavailable(providerID: ProviderID, httpStatus: Int = 404) -> ProviderError {
        ProviderError(
            providerID: providerID,
            httpStatus: httpStatus,
            code: .billingAPIUnavailable,
            remediationKey: .billingAPIUnavailable
        )
    }

    /// 传输层把状态码交上来，映射只在这里做一份。
    public static func fromHTTPStatus(_ status: Int, providerID: ProviderID) -> ProviderError? {
        switch status {
        case 200..<300:
            return nil
        case 401:
            return .unauthorized(providerID: providerID)
        case 403:
            return .forbidden(providerID: providerID)
        case 404:
            return .billingAPIUnavailable(providerID: providerID, httpStatus: 404)
        case 429:
            return .rateLimited(providerID: providerID)
        case 500...599:
            return .serviceUnavailable(providerID: providerID, httpStatus: status)
        default:
            return .networkFailure(providerID: providerID, httpStatus: status)
        }
    }
}
