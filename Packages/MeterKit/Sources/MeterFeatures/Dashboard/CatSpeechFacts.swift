import Foundation
import MeterCore
import MeterProviders

enum CatSpeechFacts {
    static func make(
        from monthToDate: MonthToDate?,
        mood: CatMood,
        hasAnyProvider: Bool,
        runways: [PrepaidRunway],
        locale: Locale = .current,
        presentation: MoneyPresentation = .usd
    ) -> CatSpeechPrompt {
        // 和 MonthToDateModuleContent 的首屏主角同一笔钱：跟着取景框的口径，
        // 算进订阅时是 totalUSD / projectedMonthEndUSD。猫只说按量的话，
        // 切到「合计」时就会和首屏在同一屏说出两个对不上的数。
        let totalText = monthToDate?.totalUSD.formatted(using: presentation)
            ?? Money.zero.formatted(using: presentation)
        let projectedText = monthToDate?.projectedMonthEndUSD.formatted(using: presentation)
            ?? Money.zero.formatted(using: presentation)
        let changePercent = monthToDate?.changeRatio.map { Int(($0 * 100).rounded()) }

        let leadAnomaly = monthToDate?.facts
            .compactMap { fact -> (String, Int, Double)? in
                guard
                    let ratio = fact.changeRatio,
                    ratio >= CatMoodResolver.shockedChangeRatio,
                    let id = fact.providerID
                else {
                    return nil
                }
                switch fact.type {
                case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded:
                    return (displayName(id), Int((ratio * 100).rounded()), ratio)
                case .subscriptionSuperseded, .freeQuota, .fetchFailed:
                    return nil
                }
            }
            .max(by: { $0.2 < $1.2 })

        let leadBalance = runways
            .filter { $0.daysRemaining <= CatMoodResolver.prepaidAlertDays }
            .min(by: { $0.daysRemaining < $1.daysRemaining })

        return CatSpeechPrompt(
            locale: locale,
            mood: mood,
            hasAnyProvider: hasAnyProvider,
            totalText: totalText,
            projectedText: projectedText,
            allowsProjection: monthToDate?.filter.allowsProjection ?? true,
            changePercent: changePercent,
            leadAnomalyName: leadAnomaly?.0,
            leadAnomalyPercent: leadAnomaly?.1,
            leadBalanceName: leadBalance.map { displayName($0.providerID) },
            includesSubscriptions: monthToDate?.filter.includesSubscriptions ?? true
        )
    }

    private static func displayName(_ id: ProviderID) -> String {
        ProviderCatalog.descriptor(id: id)?.displayName ?? id.rawValue
    }
}
