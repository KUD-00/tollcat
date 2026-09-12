// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。

import MeterDesign

/// 每一班车的更新说明。新的在上。
///
/// 三语都编在这里，展示时按 `CatalogLanguage` 选列——和目录同一条规矩，
/// 不走 xcstrings（那边是界面外壳的文案，这边是内容）。
///
/// **编译期，不下发。** 它描述的是正在跑的这个二进制，打 tag 那一刻就全部已知；
/// 而抽屉在「更新后第一次冷启动」弹，那一刻远程缓存里按定义没有这条。
/// 以后若要支持远程改错别字，能被覆盖的只有 `title` / `body`，按 `WhatsNewItem.id` 认。
enum WhatsNewCatalog {
    static let entries: [WhatsNewEntry] = [
        WhatsNewEntry(
            version: "1.1.0",
            platforms: [.ios],
            showsDrawer: true,
            hero: .cat(.normal),
            title: WhatsNewText(zh: "TollCat 1.1：看哪个月，就说哪个月", en: "TollCat 1.1: says the month you’re looking at", ja: "TollCat 1.1：見ている月の言葉で話す"),
            items: [
                WhatsNewItem(
                    id: "periodAwareCopy",
                    symbol: "calendar",
                    title: WhatsNewText(zh: "换了月份，页面上的字也跟着换", en: "Pick a month, and the page talks about that month", ja: "月を選べば、画面の言葉もその月に"),
                    body: WhatsNewText(zh: "选了七月或者近 3 个月，仪表盘上原来写「本月」的地方都会改成那段时间。「之最」那一节也一样。固定订阅卡在跨月区间里列的是那几个月实际扣过的每一笔，中途退掉的也算在里面。", en: "Choose July or the last 3 months and every spot that used to say “this month” now names that period, the superlatives section included. Over a multi-month range the subscriptions card lists what was actually charged in those months, cancelled ones too.", ja: "7月や直近3か月を選ぶと、これまで「今月」と書いていた場所がすべてその期間の名前になります。「トップ」のセクションも同じです。複数月の範囲では、サブスクリプションのカードにその期間に実際に引き落とされた分が並びます。途中で解約したものも含みます。")
                ),
                WhatsNewItem(
                    id: "subscriptionLine",
                    symbol: "creditcard",
                    title: WhatsNewText(zh: "订阅金额搬到日期上面", en: "The subscription amount now sits above the date", ja: "サブスクの金額は日付の上に"),
                    body: WhatsNewText(zh: "算进固定订阅的时候，大数字底下多一行「（订阅 $X）」，告诉你总数里有多少是订阅。关掉订阅这一行就不出现，不再写「已计入」「未计入」。", en: "With subscriptions included, a line like “(Subscriptions $20)” appears under the big number so you can see how much of the total is subscriptions. Turn them off and the line goes away. No more “included” or “not included”.", ja: "サブスクリプションを含める設定にすると、大きな数字の下に「（サブスク $20）」のような一行が出て、合計のうちいくらがサブスクかがわかります。含めない設定ではこの行は出ません。「計上済み」「未計上」という表記はなくしました。")
                ),
                WhatsNewItem(
                    id: "guidesRewritten",
                    symbol: "book.pages",
                    title: WhatsNewText(zh: "155 家的接入说明重写了", en: "Setup guides for 155 services, rewritten", ja: "155 サービスの接続ガイドを書き直しました"),
                    body: WhatsNewText(zh: "每一步都指到真正创建密钥的那一页，顺手写清要哪些权限、密钥只显示一次这类容易踩的坑。连接失败时的提示也按每家的实际情况改准了。", en: "Each step now points at the exact page where the key gets created, and calls out the traps along the way: which permission to tick, keys that are shown only once. The messages you see when a connection fails were made specific to each service too.", ja: "どの手順も、実際にキーを作るページを指すようにしました。必要な権限や、キーが一度しか表示されないことなど、つまずきやすい点も添えています。接続に失敗したときの案内も、サービスごとの実情に合わせました。")
                ),
                WhatsNewItem(
                    id: "fourVerified",
                    symbol: "checkmark.seal",
                    title: WhatsNewText(zh: "DigitalOcean、Stripe、Botpress、Neo4j Aura 用真实账单核对过了", en: "DigitalOcean, Stripe, Botpress and Neo4j Aura checked against real bills", ja: "DigitalOcean、Stripe、Botpress、Neo4j Aura を実際の請求で確認"),
                    body: WhatsNewText(zh: "这四家从「待验证」升为「完全支持」。接上去，数字就是你账单上的数字。", en: "These four move from “pending verification” to fully supported. Connect one and the number you see is the number on your bill.", ja: "この4社は「検証待ち」から「完全対応」になりました。接続すれば、表示される数字はそのまま請求書の数字です。")
                ),
                WhatsNewItem(
                    id: "exchangeRedaction",
                    symbol: "lock.shield",
                    title: WhatsNewText(zh: "反馈里附带的响应，打码更严了", en: "Stricter redaction in feedback attachments", ja: "フィードバックに添える応答のマスクを厳しくしました"),
                    body: WhatsNewText(zh: "发反馈时选择附带测试连接的响应，所有以 token 结尾的字段一律打掉，之前有几家的写法漏了。用量统计里的 tokens 数字不受影响。", en: "If you attach the test-connection response to a feedback report, every field ending in “token” is now blanked out. A few services spelled theirs in a way that slipped through before. Usage counts like total_tokens are untouched.", ja: "フィードバックに接続テストの応答を添えるとき、「token」で終わる項目はすべて伏せ字にします。以前は一部のサービスの書き方がすり抜けていました。利用量の tokens の数字はそのまま残ります。")
                ),
            ]
        ),
        WhatsNewEntry(
            version: "1.0.0",
            platforms: [.ios],
            showsDrawer: false,
            hero: .cat(.normal),
            title: WhatsNewText(zh: "TollCat 1.0：云账单，装进口袋", en: "TollCat 1.0: your cloud bills, in your pocket", ja: "TollCat 1.0：クラウドの請求を、ポケットに"),
            items: [
                WhatsNewItem(
                    id: "firstRelease",
                    symbol: "sparkles",
                    title: WhatsNewText(zh: "第一版上架了", en: "The first release", ja: "はじめてのリリース"),
                    body: WhatsNewText(zh: "先从 iPhone 和 iPad 开始。把各家云和 AI 服务的花费加在一起，打开就能看到这个月到现在一共花了多少。", en: "iPhone and iPad first. TollCat adds up what you spend across your cloud and AI services, so one glance tells you how much this month has cost so far.", ja: "まずは iPhone と iPad から。クラウドや AI サービスの利用料をまとめて、今月ここまでいくら使ったかがひと目でわかります。")
                ),
            ]
        ),
    ]
}
