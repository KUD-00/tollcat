import Foundation
import MeterCore
import MeterPersistence
import MeterProviders

enum SetupVerifyFormatter {
    static func successTitle(
        for snapshot: Snapshot,
        presentation: MoneyPresentation = .usd
    ) -> String {
        switch snapshot.kind {
        case .usage:
            if let spend = snapshot.currentSpendUSD {
                return String(localized: L("本周期至今 \(presentation.string(from: spend, original: snapshot.converted))"))
            }
        case .prepaid:
            if let spend = snapshot.currentSpendUSD {
                return String(localized: L("本周期至今 \(presentation.string(from: spend, original: snapshot.converted))"))
            }
            if let balance = snapshot.balanceUSD {
                return String(localized: L("余额 \(presentation.string(from: balance, original: snapshot.converted))"))
            }
        case .subscription:
            if let committed = snapshot.committedMonthlyUSD {
                return String(localized: L("订阅 \(committed.formatted(using: presentation))"))
            }
        case .freeTier:
            if let ratio = snapshot.freeQuotaUsedRatio {
                let percent = Int((ratio * 100).rounded())
                return String(localized: L("免费额度 · 用了 \(percent)%"))
            }
        case .planAndUsage:
            if let committed = snapshot.committedMonthlyUSD, let spend = snapshot.currentSpendUSD {
                return String(localized: L("月费 \(committed.formatted(using: presentation)) · 超额 \(spend.formatted(using: presentation))"))
            }
            if let committed = snapshot.committedMonthlyUSD {
                return String(localized: L("订阅 \(committed.formatted(using: presentation))"))
            }
            if let spend = snapshot.currentSpendUSD {
                return String(localized: L("本周期至今 \(spend.formatted(using: presentation))"))
            }
        }
        return String(localized: L("本周期至今 —"))
    }

    static func successDetail(for snapshot: Snapshot, calendar: Calendar) -> String {
        let start = MeterDateFormat.monthDayNumeric(snapshot.periodStart, calendar: calendar)
        let end = MeterDateFormat.monthDayNumeric(snapshot.periodEnd, calendar: calendar)
        let granularity = snapshot.dailyUSD == nil
            ? String(localized: L("无日粒度"))
            : String(localized: L("日粒度可用"))
        return String(localized: L("周期 \(start) – \(end) · \(granularity)"))
    }

    static func fallbackErrorCase(for error: ProviderError) -> ErrorCase {
        let status = error.httpStatus ?? 0
        switch error.remediationKey {
        case .invalidCredentials:
            return ErrorCase(
                httpStatus: status == 0 ? 401 : status,
                explanation: String(localized: L("这个 token 无效，或者已经被撤销了。")),
                nextStep: String(localized: L("回上一步重新创建一把，创建后立刻复制。"))
            )
        case .insufficientPermissions:
            return ErrorCase(
                httpStatus: status == 0 ? 403 : status,
                explanation: String(localized: L("这个 token 缺权限，所以读不到账单。")),
                nextStep: String(localized: L("回上一步检查权限后再测一次。"))
            )
        case .rateLimited:
            return ErrorCase(
                httpStatus: 429,
                explanation: String(localized: L("请求太频繁，被限流了。")),
                nextStep: String(localized: L("等一分钟再试，不要连点刷新。"))
            )
        case .serviceUnavailable:
            return ErrorCase(
                httpStatus: status == 0 ? 500 : status,
                explanation: String(localized: L("对方服务器出错了。")),
                nextStep: String(localized: L("过一会儿再试。不是你的密钥坏了。"))
            )
        case .malformedResponse:
            return ErrorCase(
                httpStatus: status,
                explanation: String(localized: L("账单接口返回的字段对不上，没法读出金额。")),
                nextStep: String(localized: L("先去官网账单页核对。还不行就等 App 更新解析。"))
            )
        case .unsupportedCurrency:
            return ErrorCase(
                httpStatus: status,
                explanation: String(localized: L("这家账单的币种不在汇率表里，所以不能计入总额。")),
                nextStep: String(localized: L("去官网确认结算货币，或改用手工录入。"))
            )
        case .missingCredential:
            return ErrorCase(
                httpStatus: status,
                explanation: String(localized: L("还有必填项没填。")),
                nextStep: String(localized: L("回上一步把该填的都填上再测。"))
            )
        case .billingAPIUnavailable:
            return ErrorCase(
                httpStatus: status == 0 ? 404 : status,
                explanation: String(localized: L("这个账号没有可用的账单接口。")),
                nextStep: String(localized: L("确认用的是文档里那种密钥，并且账号已经开通账单 API。"))
            )
        case .networkUnavailable, .fixtureUnavailable:
            return ErrorCase(
                httpStatus: status,
                explanation: String(localized: L("现在连不上这家的账单接口。")),
                nextStep: String(localized: L("检查网络后再试一次。"))
            )
        }
    }

    static func outcome(
        snapshot: Snapshot?,
        error: Error?,
        troubleshooting: [ErrorCase],
        calendar: Calendar,
        presentation: MoneyPresentation = .usd
    ) -> SetupVerifyOutcome {
        if let snapshot {
            if snapshot.hasBillableMetrics {
                return .success(
                    title: successTitle(for: snapshot, presentation: presentation),
                    detail: successDetail(for: snapshot, calendar: calendar)
                )
            }
            return .emptyReading
        }
        if let providerError = error as? ProviderError {
            if let status = providerError.httpStatus,
               let match = troubleshooting.first(where: { $0.httpStatus == status }) {
                return .http(match)
            }
            if providerError.code == .networkFailure {
                return .network
            }
            return .http(fallbackErrorCase(for: providerError))
        }
        return .unknown
    }

}
