// GENERATED — 由 scripts/generate-shared.py 从 shared/jni-copy.json + 各模块 Localizable.xcstrings 生成。
// 不要手改：改 shared/jni-copy.json + 各模块 Localizable.xcstrings 后重跑生成器。


import Foundation

/// 桥出口的用户可见文案。Android / Windows 的 SwiftPM 构建不编 String Catalog，
/// `String(localized:)` 会静默回落源语言，所以把需要的键连三语译文一起编进动态库。
package enum JNICopy {
    /// languageTag 前缀匹配；表里没有或语言对不上就回落中文源串。
    static func text(_ key: String, _ localeTag: String) -> String {
        guard let entry = table[key] else { return key }
        if localeTag.hasPrefix("en") { return entry.en }
        if localeTag.hasPrefix("ja") { return entry.ja }
        return key
    }

    /// %@ / %lld（含 %1$@ 位置式）按顺序或位置替换。实参先由调用方转成字符串。
    static func format(_ key: String, _ localeTag: String, _ args: String...) -> String {
        let pattern = text(key, localeTag)
        var result = ""
        var next = 0
        var index = pattern.startIndex
        while index < pattern.endIndex {
            guard pattern[index] == "%" else {
                result.append(pattern[index])
                index = pattern.index(after: index)
                continue
            }
            var cursor = pattern.index(after: index)
            if cursor < pattern.endIndex, pattern[cursor] == "%" {
                result.append("%")
                index = pattern.index(after: cursor)
                continue
            }
            var position: Int?
            var digits = ""
            while cursor < pattern.endIndex, pattern[cursor].isNumber {
                digits.append(pattern[cursor])
                cursor = pattern.index(after: cursor)
            }
            if !digits.isEmpty, cursor < pattern.endIndex, pattern[cursor] == "$" {
                position = Int(digits)
                cursor = pattern.index(after: cursor)
            } else if !digits.isEmpty {
                // %20 这种不是占位符，原样放回
                result.append("%" + digits)
                index = cursor
                continue
            }
            let rest = pattern[cursor...]
            var consumed = 0
            if rest.hasPrefix("@") { consumed = 1 }
            else if rest.hasPrefix("lld") { consumed = 3 }
            else if rest.hasPrefix("ld") { consumed = 2 }
            else if rest.hasPrefix("d") { consumed = 1 }
            guard consumed > 0 else {
                result.append(pattern[index])
                index = pattern.index(after: index)
                continue
            }
            let argIndex = (position ?? (next + 1)) - 1
            if position == nil { next += 1 }
            result.append(argIndex < args.count ? args[argIndex] : "")
            index = pattern.index(cursor, offsetBy: consumed)
        }
        return result
    }

    private struct Entry {
        let en: String
        let ja: String
    }

    private static let table: [String: Entry] = [
        "用量后付费": Entry(en: "Pay-as-you-go", ja: "従量課金"),
        "预充值余额": Entry(en: "Prepaid balance", ja: "プリペイド残高"),
        "固定订阅": Entry(en: "Subscription", ja: "定額サブスクリプション"),
        "免费额度内": Entry(en: "Free tier", ja: "無料枠内"),
        "月费加超额": Entry(en: "Plan plus overage", ja: "定額＋超過"),
        "%@ · 刷新要花钱 约 $0.01": Entry(en: "%@ · Refresh costs about $0.01", ja: "%@ · 更新に約 $0.01"),
        "%@ · 读数信箱": Entry(en: "%@ · Reading inbox", ja: "%@ · 検針ポスト"),
        "按 %@ 显示": Entry(en: "Shown in %@", ja: "%@ で表示"),
        "用了 %lld%%": Entry(en: "%lld%% used", ja: "%lld%%使用"),
        "对比 %@同期 %@": Entry(en: "vs %@ %@", ja: "%@の同期 %@"),
        "含还不能对比 %@": Entry(en: "Includes %@ not yet comparable", ja: "まだ比べられない %@ を含む"),
        "%@ 余额 %@ · 按当前速度还能用 %lld 天": Entry(en: "%1$@ balance %2$@ · %3$lld days left at the current pace", ja: "%1$@の残高 %2$@ · 今のペースであと %3$lld日"),
        "持平": Entry(en: "Unchanged", ja: "横ばい"),
        "今天": Entry(en: "Today", ja: "今日"),
        "明天": Entry(en: "Tomorrow", ja: "明日"),
        "刚刚": Entry(en: "Just now", ja: "たった今"),
        "这回没读到账单。": Entry(en: "No bill came back this time.", ja: "今回は請求を読み取れませんでした。"),
        "还没有账单。": Entry(en: "No bills yet.", ja: "請求はまだない。"),
        "这个月比上个月同期涨了一倍多。": Entry(en: "This month more than doubled versus last month.", ja: "今月は先月同期の倍以上。"),
        "合计较上月同期涨了 %lld%%。": Entry(en: "Total is up %lld%% versus last month.", ja: "合計は先月同期比 %lld%% 増。"),
        "这个月涨得有点猛。": Entry(en: "This month jumped hard.", ja: "今月の伸びがきつい。"),
        "%@ 的余额快见底了。": Entry(en: "%@’s balance is almost gone.", ja: "%@ の残高がもうすぐ尽きる。"),
        "%@ 较上月同期涨了 %lld%%。": Entry(en: "%@ is up %lld%% versus last month.", ja: "%@ は先月同期比 %lld%% 増。"),
        "有一项需要留意。": Entry(en: "Something needs a look.", ja: "ひとつ気になることがある。"),
        "有几家没刷上来，先看上次的数字。": Entry(en: "A few providers didn’t refresh. These are the last good numbers.", ja: "いくつか更新できていない。前回の数字を表示している。"),
        "这个月比上个月同期少花了 %lld%%。": Entry(en: "This month is %lld%% less than last month.", ja: "今月は先月同期より %lld%% 少ない。"),
        "这个月还都在免费额度里。": Entry(en: "Everything is still inside the free quota.", ja: "まだ全部無料枠の中。"),
        "那个月合计 %@。": Entry(en: "That month came to %@.", ja: "その月は合計 %@。"),
        "本月至今 %@，预计月底 %@。": Entry(en: "%1$@ so far this month, %2$@ by month end.", ja: "今月ここまで %1$@、月末見込み %2$@。"),
        "还不能对比": Entry(en: "Not enough to compare", ja: "まだ比べられない"),
        "花得最多：%@，%@": Entry(en: "Most expensive day: %1$@, %2$@", ja: "最も使った日：%1$@、%2$@"),
        "每月": Entry(en: "Monthly", ja: "毎月"),
        "每年": Entry(en: "Yearly", ja: "年ごと"),
        "%lld 笔，折算每月。年付按 12 摊。": Entry(en: "%lld subscriptions, as a monthly figure. Annual plans are spread over 12 months.", ja: "%lld 件、月額換算。年払いは 12 で割っています。"),
        "下一笔：%@，%@": Entry(en: "Next: %1$@, %2$@", ja: "次回：%1$@、%2$@"),
        "本月订阅 %@ · 已计入": Entry(en: "Subscriptions %@ · included", ja: "サブスク %@ · 計上済み"),
        "本月订阅 %@ · 未计入": Entry(en: "Subscriptions %@ · not included", ja: "サブスク %@ · 未計上"),
        "部分数据陈旧，仍显示上次成功的数字": Entry(en: "Some data is stale. Showing the last successful numbers.", ja: "一部のデータが古い。前回成功した数字を表示している。"),
    ]
}
