import Foundation

/// Preview、测试和截图用的几份 `Glance`。数字是 SPEC 第 04 节那组设计稿数
/// （合计 $47.20），不是运行时取数。
public enum GlanceSamples {
    /// 2026-09-23 12:00 UTC：9 月第 23 天。
    public static let now = Date(timeIntervalSince1970: 1_790_164_800)
    static let monthStart = Date(timeIntervalSince1970: 1_788_220_800)
    static let monthEnd = Date(timeIntervalSince1970: 1_790_812_800)

    public static let month = Glance(
        monthStart: monthStart,
        monthEnd: monthEnd,
        generatedAt: now.addingTimeInterval(-60),
        lastRefreshAt: now.addingTimeInterval(-12 * 60),
        content: .month(
            GlanceMonth(
                amountText: "$47.20",
                compactAmountText: "$47",
                spokenAmount: "47.20 美元",
                projectionText: "预计月底 $61.57",
                spokenProjection: "预计月底 61.57 美元",
                periodText: "9月1日至23日",
                budget: GlanceBudget(
                    fraction: 0.59,
                    percentText: "59%",
                    limitText: "$80.00",
                    caption: "还剩 $32.80，用了 59%",
                    level: .normal,
                    spokenLabel: "预算 80 美元，已花 47.20 美元"
                ),
                services: [
                    GlanceService(rank: 0, name: "AWS", amountText: "$21.40", spokenAmount: "21.40 美元", detail: awsDetail),
                    GlanceService(rank: 1, name: "Cloudflare", amountText: "$11.05", spokenAmount: "11.05 美元"),
                    GlanceService(rank: 2, name: "OpenAI", amountText: "$7.62", spokenAmount: "7.62 美元"),
                    GlanceService(rank: 3, name: "GitHub", amountText: "$4.00", spokenAmount: "4 美元"),
                    GlanceService(rank: 4, name: "Neon", amountText: "$3.13", spokenAmount: "3.13 美元"),
                ]
            )
        )
    )

    /// 按当前速度月底会超预算。
    public static let overBudget: Glance = {
        var glance = month
        guard case .month(var detail) = glance.content else { return glance }
        detail.amountText = "$71.40"
        detail.compactAmountText = "$71"
        detail.projectionText = "预计月底 $93.13"
        detail.budget = GlanceBudget(
            fraction: 0.8925,
            percentText: "89%",
            limitText: "$80.00",
            caption: "还剩 $8.60，用了 89%",
            level: .close,
            projectedOverspendText: "预计超预算 $13.13",
            spokenLabel: "预算 80 美元，已花 71.40 美元"
        )
        glance.content = .month(detail)
        return glance
    }()

    /// 三个多小时没刷新。
    public static let stale: Glance = {
        var glance = month
        glance.lastRefreshAt = now.addingTimeInterval(-(3 * 3600 + 20 * 60))
        return glance
    }()

    public static let noBills = Glance(
        monthStart: monthStart,
        monthEnd: monthEnd,
        generatedAt: now,
        lastRefreshAt: nil,
        content: .noBills
    )

    /// AWS 那一页。30 天里前 7 天落在 8 月，后 23 天是 9 月 1 日到今天；9 月那段加起来 $21.40。
    static let awsDetail: GlanceServiceDetail = {
        let august: [Double] = [0.62, 0.71, 0.55, 0.80, 0.94, 0.66, 0.58]
        let september: [Double] = [
            0.72, 0.81, 0.64, 0.95, 1.10, 0.58, 0.52, 0.88, 1.32, 0.97, 0.84, 0.79,
            0.61, 0.55, 1.18, 1.05, 0.92, 0.86, 2.14, 1.12, 0.93, 0.70, 1.22,
        ]
        let today = Calendar.utc.startOfDay(for: now)
        let values = august + september
        let days = values.enumerated().map { index, value in
            GlanceDay(
                date: Calendar.utc.date(byAdding: .day, value: index - (values.count - 1), to: today)!,
                value: value,
                amountText: "$" + String(format: "%.2f", value)
            )
        }
        return GlanceServiceDetail(
            shareText: "占本月 45%",
            change: GlanceChange(
                text: "较上月同期 +12%",
                detailText: "本月 $21.40 · 8月同期 $19.10",
                direction: .up
            ),
            days: days,
            sublines: [
                GlanceSubline(id: "ec2", title: "EC2", amountText: "$12.08"),
                GlanceSubline(id: "s3", title: "S3", amountText: "$4.61"),
                GlanceSubline(id: "cloudfront", title: "CloudFront", amountText: "$3.26"),
                GlanceSubline(id: "other", title: "其他", amountText: "$1.45"),
            ]
        )
    }()
}

private extension Calendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
