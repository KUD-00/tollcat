import Foundation

/// 一班车的更新说明。数据来自 `WhatsNewCatalog`（生成物）。
///
/// 没有 `date`：抽屉不显示日期——你正在看它，因为你刚更新完。日期只有落地页读，
/// 而它在 Publish 那天才补，那次提交不该逼着重出一个包。
struct WhatsNewEntry: Identifiable, Hashable, Sendable {
    var version: String
    var platforms: Set<WhatsNewPlatform>
    /// 值不值得弹抽屉。缺省由生成器按 `X.Y.0` / `X.Y.Z` 算好，这里只是结果。
    /// `false` 只关掉抽屉——设置里的全量列表、落地页、商店文案照常有这一条。
    var showsDrawer: Bool
    var hero: WhatsNewHero?
    var title: WhatsNewText
    var items: [WhatsNewItem]

    var id: String { version }
}

extension WhatsNewEntry {
    /// Preview 和开发层用。真数据在 `WhatsNewCatalog`（生成物），首发之前是空的——
    /// 所以这里必须自带一条，否则抽屉没法看。
    static let preview = WhatsNewEntry(
        version: "1.1.0",
        platforms: [.ios, .mac],
        showsDrawer: true,
        hero: .cat(.saved),
        title: WhatsNewText(
            zh: "仪表盘可以自己摆了",
            en: "Lay out your own dashboard",
            ja: "ダッシュボードを自分で組む"
        ),
        items: [
            WhatsNewItem(
                id: "previewDashboardEdit",
                symbol: "square.grid.2x2",
                title: WhatsNewText(
                    zh: "十三块模块，开关和顺序自己定",
                    en: "Thirteen modules, yours to arrange",
                    ja: "13 のモジュールを自分で並べる"
                ),
                body: WhatsNewText(
                    zh: "长按仪表盘进编辑，拖动排序，不看的关掉。摆好的版式跟着迁移包换机。",
                    en: "Long-press the dashboard to edit, drag to reorder, "
                        + "switch off what you don't read. Your layout travels with a transfer file.",
                    ja: "ダッシュボードを長押しして編集、ドラッグで並べ替え、"
                        + "見ないものはオフに。並べた配置は移行ファイルで引き継げます。"
                )
            ),
            WhatsNewItem(
                id: "previewMenuBar",
                symbol: "menubar.arrow.up.rectangle",
                title: WhatsNewText(
                    zh: "Mac 的菜单栏只露一只猫",
                    en: "Just the cat in the Mac menu bar",
                    ja: "Mac のメニューバーは猫だけ"
                ),
                body: WhatsNewText(
                    zh: "关掉窗口进程继续跑，金额要不要一起露由设置决定。",
                    en: "Close the window and it keeps running. "
                        + "Whether the amount shows next to it is a setting.",
                    ja: "ウインドウを閉じても動き続けます。金額を並べて出すかは設定で。"
                )
            ),
        ]
    )

    /// 被跳过的那一版长什么样：抽屉把它折进「更多更新」，只露标题。
    static let previewOlder = WhatsNewEntry(
        version: "1.0.1",
        platforms: [.ios, .mac],
        showsDrawer: true,
        hero: nil,
        title: WhatsNewText(
            zh: "日元下的合计算对了",
            en: "Totals in yen add up again",
            ja: "円建ての合計が正しくなりました"
        ),
        items: [
            WhatsNewItem(
                id: "previewYenTotal",
                symbol: "yensign",
                title: WhatsNewText(
                    zh: "换算发生在读出来那一步",
                    en: "Conversion happens when the number is read out",
                    ja: "換算は読み上げる直前に行います"
                ),
                body: WhatsNewText(
                    zh: "账本仍然是美元，展示货币只决定怎么写成字。",
                    en: "The ledger stays in dollars. "
                        + "The display currency only decides how it is written.",
                    ja: "台帳はドルのまま。表示通貨は書き方だけを決めます。"
                )
            ),
        ]
    )
}
