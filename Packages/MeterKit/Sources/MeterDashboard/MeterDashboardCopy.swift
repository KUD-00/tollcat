// GENERATED — 由 scripts/generate-shared.py 从 Packages/MeterKit/Sources/MeterDashboard/Resources/Localizable.xcstrings 生成。
// 不要手改：改 Packages/MeterKit/Sources/MeterDashboard/Resources/Localizable.xcstrings 后重跑生成器。


import Foundation
import MeterFormat

/// MeterDashboard 的文案出处（见 `PortableCatalog`）：键是中文源串，值是 en / ja。
/// 桥上设了 `PortableLocale.languageTag` 时查这张表；Apple 平台不设时走 String Catalog。
enum MeterDashboardCopy {
    static let catalog: PortableCatalog = {
        #if canImport(Darwin)
        PortableCatalog(table: table, bundleURL: { Bundle.module.bundleURL })
        #else
        PortableCatalog(table: table)
        #endif
    }()

    private static let table: [String: PortableTranslation] = [
        "%@ %@，%@扣款": PortableTranslation(en: "%1$@ %2$@, charges %3$@", ja: "%1$@ %2$@、%3$@に引き落とし"),
        "%@ 余额 %@ · 按当前速度还能用 %lld 天": PortableTranslation(en: "%1$@ balance %2$@ · %3$lld days left at the current pace", ja: "%1$@の残高 %2$@ · 今のペースであと %3$lld日"),
        "%@ 余额 %@，按当前速度还能用 %lld 天": PortableTranslation(en: "%1$@ balance %2$@, %3$lld days left at the current pace", ja: "%1$@の残高 %2$@、今のペースであと %3$lld日"),
        "%@ 免费额度，%@": PortableTranslation(en: "%1$@ free quota, %2$@", ja: "%1$@の無料枠、%2$@"),
        "%@ 本月 %@，还不能和上月同期对比": PortableTranslation(en: "%@ is %@ this month, not enough to compare with last month", ja: "%@ は今月 %@、先月同期とはまだ比べられない"),
        "%@ 较上月同期 %@，%@": PortableTranslation(en: "%1$@ vs same period last month %2$@, %3$@", ja: "%1$@は先月同期比 %2$@、%3$@"),
        "%@ 较上月同期持平，本月 %@": PortableTranslation(en: "%@ is unchanged versus last month, %@ this month", ja: "%@ は先月同期と横ばい、今月 %@"),
        "%@之最": PortableTranslation(en: "%@ extremes", ja: "%@のトップ"),
        "%@（自%@起）": PortableTranslation(en: "%1$@ (since %2$@)", ja: "%1$@（%2$@ から）"),
        "%@，%@": PortableTranslation(en: "%@, %@", ja: "%@、%@"),
        "%lld 天": PortableTranslation(en: "%lld days", ja: "%lld日"),
        "%lld 天前": PortableTranslation(en: "%lld days ago", ja: "%lld日前"),
        "%lld 笔，折算每月。年付按 12 摊。": PortableTranslation(en: "%lld subscriptions, as a monthly figure. Annual plans are spread over 12 months.", ja: "%lld 件、月額換算。年払いは 12 で割っています。"),
        "%lld 笔，这段时间合计。": PortableTranslation(en: "%lld subscriptions, totaled over this period.", ja: "%lld 件、この期間の合計。"),
        "1 天前": PortableTranslation(en: "1 day ago", ja: "1日前"),
        "AI 推理": PortableTranslation(en: "AI inference", ja: "AI 推論"),
        "CI 与测试": PortableTranslation(en: "CI and testing", ja: "CI とテスト"),
        "GPU 算力": PortableTranslation(en: "GPU compute", ja: "GPU 計算資源"),
        "上升百分之 %lld": PortableTranslation(en: "up %lld percent", ja: "%lldパーセント上昇"),
        "上月": PortableTranslation(en: "Last month", ja: "先月"),
        "下一笔：%@，%@": PortableTranslation(en: "Next: %1$@, %2$@", ja: "次回：%1$@、%2$@"),
        "下降百分之 %lld": PortableTranslation(en: "down %lld percent", ja: "%lldパーセント下降"),
        "仅按量": PortableTranslation(en: "Usage only", ja: "従量のみ"),
        "今天": PortableTranslation(en: "Today", ja: "今日"),
        "今年至今": PortableTranslation(en: "Year to date", ja: "今年に入ってから"),
        "余额 %@": PortableTranslation(en: "Balance %@", ja: "残高 %@"),
        "免费额度": PortableTranslation(en: "Free Quota", ja: "無料枠"),
        "其他": PortableTranslation(en: "Other", ja: "その他"),
        "内容与建站": PortableTranslation(en: "Content and websites", ja: "コンテンツとサイト制作"),
        "分析": PortableTranslation(en: "Analytics", ja: "分析"),
        "协作": PortableTranslation(en: "Collaboration", ja: "コラボレーション"),
        "占比最大": PortableTranslation(en: "Biggest share", ja: "最大の割合"),
        "合计": PortableTranslation(en: "Total", ja: "合計"),
        "合计较上月同期 %@，%@": PortableTranslation(en: "Total vs last month %1$@, %2$@", ja: "合計は先月同期比%1$@、%2$@"),
        "含估算": PortableTranslation(en: "Includes estimates", ja: "見積もりを含む"),
        "含订阅": PortableTranslation(en: "Incl. subs", ja: "サブスク込み"),
        "含还不能对比 %@": PortableTranslation(en: "Includes %@ not yet comparable", ja: "まだ比べられない %@ を含む"),
        "媒体": PortableTranslation(en: "Media", ja: "メディア"),
        "存储": PortableTranslation(en: "Storage", ja: "ストレージ"),
        "对比 %@同期 %@": PortableTranslation(en: "vs %@ %@", ja: "%@の同期 %@"),
        "开发平台": PortableTranslation(en: "Developer platforms", ja: "開発プラットフォーム"),
        "手动订阅": PortableTranslation(en: "Manual Subscription", ja: "手動サブスクリプション"),
        "托管": PortableTranslation(en: "Hosting", ja: "ホスティング"),
        "持平": PortableTranslation(en: "Unchanged", ja: "横ばい"),
        "按量较上月同期 %@，%@": PortableTranslation(en: "Variable spend vs last month %1$@, %2$@", ja: "従量は先月同期比%1$@、%2$@"),
        "排除 %@": PortableTranslation(en: "Excl. %@", ja: "%@ を除外"),
        "排除 %lld 个账号": PortableTranslation(en: "Excl. %lld accounts", ja: "%lld 件のアカウントを除外"),
        "搜索": PortableTranslation(en: "Search", ja: "検索"),
        "收款": PortableTranslation(en: "Payments", ja: "決済"),
        "数据库": PortableTranslation(en: "Databases", ja: "データベース"),
        "数据管道": PortableTranslation(en: "Data pipelines", ja: "データパイプライン"),
        "整月 · %@": PortableTranslation(en: "Full month · %@", ja: "月全体 · %@"),
        "最久没刷新": PortableTranslation(en: "Longest since refresh", ja: "最も更新が古い"),
        "有数据以来": PortableTranslation(en: "All time", ja: "全期間"),
        "本月": PortableTranslation(en: "This month", ja: "今月"),
        "本月 %@ · %@同期 %@": PortableTranslation(en: "This month %1$@ · %2$@ same period %3$@", ja: "今月 %1$@ · %2$@の同期 %3$@"),
        "本月之最": PortableTranslation(en: "This month’s extremes", ja: "今月のトップ"),
        "每年": PortableTranslation(en: "Yearly", ja: "年ごと"),
        "每月": PortableTranslation(en: "Monthly", ja: "毎月"),
        "每月 × %lld": PortableTranslation(en: "Monthly × %lld", ja: "毎月 × %lld"),
        "涨得最多": PortableTranslation(en: "Biggest rise", ja: "最も増えた"),
        "用了 %lld%%": PortableTranslation(en: "%lld%% used", ja: "%lld%%使用"),
        "监控": PortableTranslation(en: "Observability", ja: "監視"),
        "统计区间 %@": PortableTranslation(en: "Period %@", ja: "集計期間 %@"),
        "网络与边缘": PortableTranslation(en: "Network and edge", ja: "ネットワークとエッジ"),
        "自动化": PortableTranslation(en: "Automation", ja: "自動化"),
        "花得最多：%@，%@": PortableTranslation(en: "Most expensive day: %1$@, %2$@", ja: "最も使った日：%1$@、%2$@"),
        "订阅": PortableTranslation(en: "Subscription", ja: "サブスクリプション"),
        "订阅 %@": PortableTranslation(en: "Subscriptions %@", ja: "サブスク %@"),
        "超出 %@": PortableTranslation(en: "%@ over budget", ja: "%@ 超過"),
        "身份与安全": PortableTranslation(en: "Identity and security", ja: "認証とセキュリティ"),
        "近 %lld 个月": PortableTranslation(en: "Last %lld months", ja: "直近 %lld か月"),
        "近几个月合计": PortableTranslation(en: "Total, recent months", ja: "ここ数か月の合計"),
        "近几个月合计，从 %@ 到 %@": PortableTranslation(en: "Total from %1$@ to %2$@", ja: "ここ数か月の合計、%1$@から%2$@"),
        "近几个月合计，只有 %@": PortableTranslation(en: "Total, %@ only", ja: "ここ数か月の合計、%@のみ"),
        "近几个月按量": PortableTranslation(en: "Variable spend, recent months", ja: "ここ数か月の従量"),
        "近几个月按量，从 %@ 到 %@": PortableTranslation(en: "Variable spend from %1$@ to %2$@", ja: "ここ数か月の従量、%1$@から%2$@"),
        "近几个月按量，只有 %@": PortableTranslation(en: "Variable spend, %@ only", ja: "ここ数か月の従量、%@のみ"),
        "还不能和上月同期对比": PortableTranslation(en: "Not enough history to compare with last month", ja: "先月同期と比べられない"),
        "还不能对比": PortableTranslation(en: "Not enough to compare", ja: "まだ比べられない"),
        "还剩 %@，%@": PortableTranslation(en: "%1$@ left, %2$@", ja: "残り %1$@、%2$@"),
        "还没刷过": PortableTranslation(en: "Never refreshed", ja: "まだ更新していません"),
        "通讯": PortableTranslation(en: "Messaging", ja: "メッセージング"),
        "部分数据陈旧，仍显示上次成功的数字": PortableTranslation(en: "Some data is stale. Showing the last successful numbers.", ja: "一部のデータが古い。前回成功した数字を表示している。"),
        "预算 %@，已花 %@，%@": PortableTranslation(en: "Budget %1$@, spent %2$@, %3$@", ja: "予算 %1$@、使用済み %2$@、%3$@"),
        "预计月底 %@": PortableTranslation(en: "Projected %@", ja: "月末見込み %@"),
        "预计月底 %@，统计区间 %@": PortableTranslation(en: "Projected %@, period %@", ja: "月末見込み %@、集計期間 %@"),
        "（订阅 %@）": PortableTranslation(en: "(Subscriptions %@)", ja: "（サブスク %@）"),
    ]
}
