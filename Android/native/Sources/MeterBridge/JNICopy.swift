// GENERATED — 由 scripts/generate-shared.py 从 shared/jni-copy.json + 各模块 Localizable.xcstrings 生成。
// 不要手改：改 shared/jni-copy.json + 各模块 Localizable.xcstrings 后重跑生成器。


import Foundation

/// 桥出口的用户可见文案。Android / Windows 的 SwiftPM 构建不编 String Catalog，
/// `String(localized:)` 会静默回落源语言，所以把需要的键连三语译文一起编进动态库。
package enum JNICopy {
    /// languageTag 前缀匹配；表里没有或语言对不上就回落中文源串。
    package static func text(_ key: String, _ localeTag: String) -> String {
        guard let entry = table[key] else { return key }
        if localeTag.hasPrefix("en") { return entry.en }
        if localeTag.hasPrefix("ja") { return entry.ja }
        return key
    }

    /// %@ / %lld（含 %1$@ 位置式）按顺序或位置替换。实参先由调用方转成字符串。
    package static func format(_ key: String, _ localeTag: String, _ args: String...) -> String {
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
        "本月订阅 %@ · 已计入": Entry(en: "Subscriptions %@ · included", ja: "サブスク %@ · 計上済み"),
        "本月订阅 %@ · 未计入": Entry(en: "Subscriptions %@ · not included", ja: "サブスク %@ · 未計上"),
        "本月至今": Entry(en: "Month to date", ja: "今月の累計"),
        "预计月底": Entry(en: "Projected", ja: "月末見込み"),
        "还没有接入任何服务。": Entry(en: "No services connected yet.", ja: "まだサービスを接続していません。"),
        "用法：": Entry(en: "Usage:", ja: "使い方："),
        "用法:\n  tollcat                 本月合计\n  tollcat --oneline       一行，给状态栏\n  tollcat --json          机器可读\n  tollcat add <服务>      写入凭据\n  tollcat remove <服务>   移除\n  tollcat refresh         强制拉新\n  tollcat providers       支持的服务\n  tollcat --version\n\n旗标:\n  --no-color              关闭颜色（也认 NO_COLOR）\n  --locale <tag>          覆盖 LANG\n  --max-age <分钟>        账本缓存时长，默认 30，0 表示总是拉新": Entry(en: "Usage:\n  tollcat                 this month's total\n  tollcat --oneline       one line, for a status bar\n  tollcat --json          machine-readable\n  tollcat add <service>   save credentials\n  tollcat remove <service>\n  tollcat refresh         fetch now\n  tollcat providers       supported services\n  tollcat --version\n\nFlags:\n  --no-color              no color (also honors NO_COLOR)\n  --locale <tag>          override LANG\n  --max-age <minutes>     ledger cache, default 30, 0 = always fetch", ja: "使い方:\n  tollcat                 今月の合計\n  tollcat --oneline       1行。ステータスバー用\n  tollcat --json          機械可読\n  tollcat add <サービス>  認証情報を保存\n  tollcat remove <サービス>\n  tollcat refresh         今すぐ取得\n  tollcat providers       対応サービス\n  tollcat --version\n\nフラグ:\n  --no-color              色を消す（NO_COLOR も見る）\n  --locale <tag>          LANG を上書き\n  --max-age <分>          台帳キャッシュ。既定 30。0 で毎回取得"),
        "未知服务：%@": Entry(en: "Unknown service: %@", ja: "未知のサービス：%@"),
        "这家服务不接入。": Entry(en: "This service isn't supported.", ja: "このサービスは対象外。"),
        "CLI 读不了这家：没有公开的账单接口。": Entry(en: "The CLI can't read this one: no public billing API.", ja: "CLI では読めない。公開の請求 API がない。"),
        "教程：%@": Entry(en: "Guide: %@", ja: "手順：%@"),
        "要花钱取数，默认刷新会跳过。接入测试仍会打一次。": Entry(en: "This one costs money to refresh, so the default refresh skips it. A connection test still hits the API once.", ja: "取得にお金がかかるので、通常の更新では飛ばす。接続テストでは一度だけ打つ。"),
        "已接入 %@。": Entry(en: "Connected %@.", ja: "%@ を接続した。"),
        "已移除 %@。": Entry(en: "Removed %@.", ja: "%@ を削除した。"),
        "部分刷新失败。": Entry(en: "Some refreshes failed.", ja: "一部の更新に失敗した。"),
        "未知旗标：%@": Entry(en: "Unknown flag: %@", ja: "未知のフラグ：%@"),
        "未知命令：%@": Entry(en: "Unknown command: %@", ja: "未知のコマンド：%@"),
        "用法错误。": Entry(en: "Usage error.", ja: "使い方が違う。"),
        "非交互环境请设置环境变量 TOLLCAT_<服务>_<字段>。": Entry(en: "In a non-interactive session, set TOLLCAT_<SERVICE>_<FIELD>.", ja: "対話できない環境では、環境変数 TOLLCAT_<サービス>_<フィールド> を設定して。"),
        "缺必填字段：%@": Entry(en: "Missing required field: %@", ja: "必須項目が足りない：%@"),
        "取数失败：%@": Entry(en: "Fetch failed: %@", ja: "取得に失敗：%@"),
        "没有接入 %@。": Entry(en: "%@ isn't connected.", ja: "%@ は接続されていない。"),
        "%@ ↗ 预计 %@": Entry(en: "%@ ↗ projected %@", ja: "%@ ↗ 見込み %@"),
        "%@ ↘ 预计 %@": Entry(en: "%@ ↘ projected %@", ja: "%@ ↘ 見込み %@"),
        "%@ · 预计 %@": Entry(en: "%@ · projected %@", ja: "%@ · 見込み %@"),
        "Secret Service 不可用。凭据请用环境变量 TOLLCAT_<服务>_<字段>。": Entry(en: "Secret Service isn't available. Set credentials with TOLLCAT_<SERVICE>_<FIELD>.", ja: "Secret Service が使えない。認証情報は環境変数 TOLLCAT_<サービス>_<フィールド> で渡して。"),
    ]
}
