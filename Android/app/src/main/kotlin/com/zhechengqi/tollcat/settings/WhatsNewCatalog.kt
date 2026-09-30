// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。


package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

/** 更新说明的三语文本。中文是规范列，展示时按 locale 选。 */
data class WhatsNewText(val zh: String, val en: String, val ja: String) {
    fun resolve(language: String): String = when {
        language == "en" || language.startsWith("en-") -> en
        language == "ja" || language.startsWith("ja-") -> ja
        else -> zh
    }
}

/** 抽屉里的一条。`id` 稳定，改名等于换一条。图标直接是枚举：写错名字编译不过，也没有空值。 */
data class WhatsNewItem(
    val id: String,
    val symbol: MaterialSymbol,
    val title: WhatsNewText,
    val body: WhatsNewText,
)

sealed interface WhatsNewHero {
    data class Cat(val mood: String) : WhatsNewHero
    data class Glyph(val provider: String) : WhatsNewHero
    data class Shot(val name: String) : WhatsNewHero
}

data class WhatsNewEntry(
    val version: String,
    val platforms: Set<String>,
    val showsDrawer: Boolean,
    val hero: WhatsNewHero?,
    val title: WhatsNewText,
    val items: List<WhatsNewItem>,
)

/** 新的在上。编译期铺进来，不下发——理由见 shared/changelog.json 的注释。 */
object WhatsNewCatalog {
    val entries: List<WhatsNewEntry> = listOf(
        WhatsNewEntry(
            version = "1.3.0",
            platforms = setOf("ios", "mac", "android"),
            showsDrawer = true,
            hero = WhatsNewHero.Cat("normal"),
            title = WhatsNewText(zh = "TollCat 1.3：上了 Android，也上了手表", en = "TollCat 1.3: on Android, and on your wrist", ja = "TollCat 1.3：Android と Apple Watch に"),
            items = listOf(
                WhatsNewItem(
                    id = "pocketIcon",
                    symbol = MaterialSymbol.Pets,
                    title = WhatsNewText(zh = "新图标：装在口袋里的猫", en = "A new icon: a cat in your pocket", ja = "新しいアイコン：ポケットの中の猫"),
                    body = WhatsNewText(zh = "图标换成一只装在口袋里的猫，身后插着云、AI 和数据库三枚圆牌。打开 App 时，这三枚圆牌会从口袋里飞出来，落到仪表盘上对应的服务旁边。", en = "The icon is now a cat sitting in a pocket, with three round badges tucked behind it for cloud, AI and database services. When you open the app, the badges fly out of the pocket and land next to the matching services on your dashboard.", ja = "アイコンを、ポケットに入った猫に変えました。後ろにはクラウド、AI、データベースを表す 3 つの丸いバッジが差してあります。アプリを開くと、バッジがポケットから飛び出して、ダッシュボードの対応するサービスの横に収まります。"),
                ),
                WhatsNewItem(
                    id = "watchGlance",
                    symbol = MaterialSymbol.Watch,
                    title = WhatsNewText(zh = "手表上也能看", en = "On your wrist, too", ja = "手首でも見られます"),
                    body = WhatsNewText(zh = "iPhone 版带上了 Apple Watch App 和表盘上的小组件，抬手就能看到这个月到现在花了多少。锁屏上也能放一个。", en = "The iPhone app now comes with an Apple Watch app and watch face complications, so one look at your wrist tells you what this month has cost so far. You can put one on the Lock Screen as well.", ja = "iPhone 版に Apple Watch アプリと文字盤のコンプリケーションが加わりました。手首を見るだけで、今月ここまでの金額がわかります。ロック画面にも置けます。"),
                ),
                WhatsNewItem(
                    id = "androidFirstRelease",
                    symbol = MaterialSymbol.Widgets,
                    title = WhatsNewText(zh = "Android 版来了", en = "TollCat on Android", ja = "Android 版ができました"),
                    body = WhatsNewText(zh = "和 iPhone 上是同一套算法、同一份接入说明，仪表盘按 Material 3 重新做了一遍。凭据只存在这台手机的 Android Keystore 里。", en = "The same calculations and the same setup guides as on iPhone, with the dashboard rebuilt in Material 3. Your credentials stay in this phone’s Android Keystore.", ja = "iPhone と同じ計算、同じ接続ガイドで、ダッシュボードは Material 3 に合わせて作り直しました。認証情報はこのスマートフォンの Android Keystore にだけ保存されます。"),
                ),
                WhatsNewItem(
                    id = "readingAccuracy",
                    symbol = MaterialSymbol.CheckCircle,
                    title = WhatsNewText(zh = "读数更可靠了", en = "More reliable readings", ja = "金額がより正確になりました"),
                    body = WhatsNewText(zh = "用欧元、日元等币种结账的服务，明细行现在和总数用同一个汇率换算，不再把原币的数字标成美元。凭据失效或接口出错时，也不会再把这个月报成 \$0，而是告诉你这次没读到，数字停在上一次。", en = "For services billed in euros, yen or other currencies, itemized lines now use the same exchange rate as the total instead of showing the original amount as dollars. And when a credential has expired or an API returns an error, the month no longer shows \$0: you’re told the update failed and the last number stays.", ja = "ユーロや円などで請求されるサービスでは、明細の行も合計と同じレートで換算するようにしました。元の通貨の金額をドルとして表示することはありません。認証情報の期限切れや API のエラーのときも、今月を \$0 と表示せず、取得に失敗したことをお知らせして前回の数字を残します。"),
                ),
                WhatsNewItem(
                    id = "securityPass",
                    symbol = MaterialSymbol.Shield,
                    title = WhatsNewText(zh = "做了一轮安全检查", en = "A security review", ja = "セキュリティを見直しました"),
                    body = WhatsNewText(zh = "删除一个服务时，会先吊销它在信箱里的投递 key，再清掉本地记录。断网删不掉会告诉你，不会悄悄留下一把还能用的 key。", en = "This release went through a security review. Removing a service now revokes its inbox ingest key before clearing local records, and if you’re offline you’ll be told, instead of a working key being left behind.", ja = "今回のリリースではセキュリティを点検しました。サービスを削除するときは、検針ポストの投函キーを取り消してからローカルの記録を消します。オフラインで取り消せないときはお知らせし、使えるキーを残したままにはしません。"),
                ),
            ),
        ),
    )
}
