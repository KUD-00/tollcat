// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。


using System.Collections.Generic;

namespace TollCat.Generated;

public sealed record WhatsNewText(string Zh, string En, string Ja)
{
    public string Resolve(string language) =>
        language.StartsWith("en") ? En : language.StartsWith("ja") ? Ja : Zh;
}

public sealed record WhatsNewItem(
    string Id,
    string? Symbol,
    WhatsNewText Title,
    WhatsNewText Body);

public sealed record WhatsNewEntry(
    string Version,
    IReadOnlyList<string> Platforms,
    bool ShowsDrawer,
    string? HeroKind,
    string? HeroValue,
    WhatsNewText Title,
    IReadOnlyList<WhatsNewItem> Items);

/// <summary>新的在上。P0 之前只生成，不接界面。</summary>
public static class WhatsNewCatalog
{
    public static readonly IReadOnlyList<WhatsNewEntry> Entries = new List<WhatsNewEntry>
    {
        new WhatsNewEntry(
            "1.2.0",
            new[] { "mac" },
            false,
            "cat",
            "normal",
            new WhatsNewText("TollCat 上 Mac 了", "TollCat comes to the Mac", "TollCat が Mac にやってきました"),
            new List<WhatsNewItem>
            {
                new WhatsNewItem(
                    "macFirstRelease",
                    null,
                    new WhatsNewText("Mac 版来了", "The Mac app is here", "Mac 版ができました"),
                    new WhatsNewText("和 iPhone 上是同一个 App，同一份接入说明，同一套数字。凭据仍然只待在你输入它的那台机器上。", "The same app as on iPhone, with the same setup guides and the same numbers. Your credentials still never leave the machine you typed them into.", "iPhone と同じアプリで、接続ガイドも数字も同じです。認証情報は入力したその Mac から出ません。")),
                new WhatsNewItem(
                    "macMenuBar",
                    null,
                    new WhatsNewText("菜单栏上就能看见", "Right there in the menu bar", "メニューバーからすぐ"),
                    new WhatsNewText("猫蹲在菜单栏里，点开就是这个月到现在花了多少。想让金额一直露在外面也行，设置里三种样式随便挑。", "The cat sits in the menu bar, and clicking it shows what this month has cost so far. Prefer the amount always on show? Settings has three styles to choose from.", "猫がメニューバーに座っていて、クリックすると今月ここまでの金額が出ます。金額を出しっぱなしにもできます。設定にスタイルが三つあります。")),
                new WhatsNewItem(
                    "macStaysAround",
                    null,
                    new WhatsNewText("关掉窗口它还在", "Closing the window does not quit it", "ウィンドウを閉じても残ります"),
                    new WhatsNewText("窗口关了只是收进菜单栏，不退出。也可以设成开机就启动，早上打开电脑，数字已经在那儿了。", "Close the window and it tucks itself into the menu bar instead of quitting. You can also have it start with the Mac, so the number is already waiting for you in the morning.", "ウィンドウを閉じるとメニューバーに収まり、終了はしません。ログイン時に起動する設定にもできるので、朝には数字がもう出ています。")),
                new WhatsNewItem(
                    "macAutoUpdate",
                    null,
                    new WhatsNewText("自己更新", "It updates itself", "自分で更新します"),
                    new WhatsNewText("从官网直接下载的这一版会自己留意有没有新版本，装的时候不用再跑一趟网站。", "The copy you download from the site keeps an eye out for new versions on its own, so you never have to come back just to install one.", "サイトから直接ダウンロードした版は、新しいバージョンを自分で見つけます。入れ直すためにサイトへ戻る必要はありません。")),
            }),
        new WhatsNewEntry(
            "1.1.0",
            new[] { "ios" },
            true,
            "cat",
            "normal",
            new WhatsNewText("TollCat 1.1：看哪个月，就说哪个月", "TollCat 1.1: says the month you’re looking at", "TollCat 1.1：見ている月の言葉で話す"),
            new List<WhatsNewItem>
            {
                new WhatsNewItem(
                    "periodAwareCopy",
                    null,
                    new WhatsNewText("换了月份，页面上的字也跟着换", "Pick a month, and the page talks about that month", "月を選べば、画面の言葉もその月に"),
                    new WhatsNewText("选了七月或者近 3 个月，仪表盘上原来写「本月」的地方都会改成那段时间。「之最」那一节也一样。固定订阅卡在跨月区间里列的是那几个月实际扣过的每一笔，中途退掉的也算在里面。", "Choose July or the last 3 months and every spot that used to say “this month” now names that period, the superlatives section included. Over a multi-month range the subscriptions card lists what was actually charged in those months, cancelled ones too.", "7月や直近3か月を選ぶと、これまで「今月」と書いていた場所がすべてその期間の名前になります。「トップ」のセクションも同じです。複数月の範囲では、サブスクリプションのカードにその期間に実際に引き落とされた分が並びます。途中で解約したものも含みます。")),
                new WhatsNewItem(
                    "subscriptionLine",
                    null,
                    new WhatsNewText("订阅金额搬到日期上面", "The subscription amount now sits above the date", "サブスクの金額は日付の上に"),
                    new WhatsNewText("算进固定订阅的时候，大数字底下多一行「（订阅 $X）」，告诉你总数里有多少是订阅。关掉订阅这一行就不出现，不再写「已计入」「未计入」。", "With subscriptions included, a line like “(Subscriptions $20)” appears under the big number so you can see how much of the total is subscriptions. Turn them off and the line goes away. No more “included” or “not included”.", "サブスクリプションを含める設定にすると、大きな数字の下に「（サブスク $20）」のような一行が出て、合計のうちいくらがサブスクかがわかります。含めない設定ではこの行は出ません。「計上済み」「未計上」という表記はなくしました。")),
                new WhatsNewItem(
                    "guidesRewritten",
                    null,
                    new WhatsNewText("155 家的接入说明重写了", "Setup guides for 155 services, rewritten", "155 サービスの接続ガイドを書き直しました"),
                    new WhatsNewText("每一步都指到真正创建密钥的那一页，顺手写清要哪些权限、密钥只显示一次这类容易踩的坑。连接失败时的提示也按每家的实际情况改准了。", "Each step now points at the exact page where the key gets created, and calls out the traps along the way: which permission to tick, keys that are shown only once. The messages you see when a connection fails were made specific to each service too.", "どの手順も、実際にキーを作るページを指すようにしました。必要な権限や、キーが一度しか表示されないことなど、つまずきやすい点も添えています。接続に失敗したときの案内も、サービスごとの実情に合わせました。")),
                new WhatsNewItem(
                    "fourVerified",
                    null,
                    new WhatsNewText("DigitalOcean、Stripe、Botpress、Neo4j Aura 用真实账单核对过了", "DigitalOcean, Stripe, Botpress and Neo4j Aura checked against real bills", "DigitalOcean、Stripe、Botpress、Neo4j Aura を実際の請求で確認"),
                    new WhatsNewText("这四家从「待验证」升为「完全支持」。接上去，数字就是你账单上的数字。", "These four move from “pending verification” to fully supported. Connect one and the number you see is the number on your bill.", "この4社は「検証待ち」から「完全対応」になりました。接続すれば、表示される数字はそのまま請求書の数字です。")),
                new WhatsNewItem(
                    "exchangeRedaction",
                    null,
                    new WhatsNewText("反馈里附带的响应，打码更严了", "Stricter redaction in feedback attachments", "フィードバックに添える応答のマスクを厳しくしました"),
                    new WhatsNewText("发反馈时选择附带测试连接的响应，所有以 token 结尾的字段一律打掉，之前有几家的写法漏了。用量统计里的 tokens 数字不受影响。", "If you attach the test-connection response to a feedback report, every field ending in “token” is now blanked out. A few services spelled theirs in a way that slipped through before. Usage counts like total_tokens are untouched.", "フィードバックに接続テストの応答を添えるとき、「token」で終わる項目はすべて伏せ字にします。以前は一部のサービスの書き方がすり抜けていました。利用量の tokens の数字はそのまま残ります。")),
            }),
        new WhatsNewEntry(
            "1.0.0",
            new[] { "ios" },
            false,
            "cat",
            "normal",
            new WhatsNewText("TollCat 1.0：云账单，装进口袋", "TollCat 1.0: your cloud bills, in your pocket", "TollCat 1.0：クラウドの請求を、ポケットに"),
            new List<WhatsNewItem>
            {
                new WhatsNewItem(
                    "firstRelease",
                    null,
                    new WhatsNewText("第一版上架了", "The first release", "はじめてのリリース"),
                    new WhatsNewText("先从 iPhone 和 iPad 开始。把各家云和 AI 服务的花费加在一起，打开就能看到这个月到现在一共花了多少。", "iPhone and iPad first. TollCat adds up what you spend across your cloud and AI services, so one glance tells you how much this month has cost so far.", "まずは iPhone と iPad から。クラウドや AI サービスの利用料をまとめて、今月ここまでいくら使ったかがひと目でわかります。")),
            }),
    };
}
