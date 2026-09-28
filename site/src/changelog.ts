// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。

import { siteConfig, type Locale } from './config';

export type ChangelogPlatform = 'ios' | 'mac' | 'android' | 'windows';

export type ChangelogItem = {
  /** 稳定 id。改名等于换一条，所以它也是以后远程文本 overlay 的钥匙。 */
  id: string;
  title: string;
  body: string;
};

export type ChangelogLocaleCopy = {
  title: string;
  items: readonly ChangelogItem[];
};

export type ChangelogEntry = {
  version: string;
  /** 上架当天的 YYYY-MM-DD。没上架就省略，页面不编造日期。 */
  date?: string;
  platforms: readonly ChangelogPlatform[];
  /** hero 截图。只有最新一条会带。 */
  shot?: { light: ImageMetadata; dark: ImageMetadata };
  copy: Record<Locale, ChangelogLocaleCopy>;
};

const PLATFORM_ORDER: readonly ChangelogPlatform[] = ['ios', 'mac', 'android', 'windows'];

/** 厂名不进 catalog。ios 那一班车是 iPhone 和 iPad 同一份。 */
export const platformNames: Record<ChangelogPlatform, string> = {
  ios: 'iPhone · iPad',
  mac: 'Mac',
  android: 'Android',
  windows: 'Windows',
};

export const changelog: readonly ChangelogEntry[] = [
    {
      "version": "1.3.0",
      "platforms": [
        "ios",
        "mac",
        "android"
      ],
      "copy": {
        "zh": {
          "title": "TollCat 1.3：上了 Android，也上了手表",
          "items": [
            {
              "id": "watchGlance",
              "title": "手表上也能看",
              "body": "iPhone 版带上了 Apple Watch App 和表盘上的小组件，抬手就能看到这个月到现在花了多少。锁屏上也能放一个。"
            },
            {
              "id": "androidFirstRelease",
              "title": "Android 版来了",
              "body": "和 iPhone 上是同一套算法、同一份接入说明，仪表盘按 Material 3 重新做了一遍。凭据只存在这台手机的 Android Keystore 里。"
            },
            {
              "id": "foreignCurrencyLines",
              "title": "外币账单的明细也换算了",
              "body": "用欧元、日元等币种结账的服务，明细行以前把原币的数字直接标成美元。现在明细和总数用同一个汇率换算。"
            },
            {
              "id": "failedNotZero",
              "title": "读不到账单时不再显示 $0",
              "body": "有几家服务在凭据失效或接口出错时，会把这个月报成 $0。现在会如实告诉你这次没读到，数字停在上一次。"
            },
            {
              "id": "securityPass",
              "title": "做了一轮安全检查",
              "body": "删除一个服务时，会先吊销它在信箱里的投递 key，再清掉本地记录。断网删不掉会告诉你，不会悄悄留下一把还能用的 key。"
            }
          ]
        },
        "en": {
          "title": "TollCat 1.3: on Android, and on your wrist",
          "items": [
            {
              "id": "watchGlance",
              "title": "On your wrist, too",
              "body": "The iPhone app now comes with an Apple Watch app and watch face complications, so one look at your wrist tells you what this month has cost so far. You can put one on the Lock Screen as well."
            },
            {
              "id": "androidFirstRelease",
              "title": "TollCat on Android",
              "body": "The same calculations and the same setup guides as on iPhone, with the dashboard rebuilt in Material 3. Your credentials stay in this phone’s Android Keystore."
            },
            {
              "id": "foreignCurrencyLines",
              "title": "Itemized lines in other currencies are converted too",
              "body": "For services billed in euros, yen or other currencies, the itemized lines used to show the original amount labelled as dollars. They now use the same exchange rate as the total."
            },
            {
              "id": "failedNotZero",
              "title": "A failed update no longer shows $0",
              "body": "A few services reported $0 for the month when a credential had expired or their API returned an error. They now tell you the update failed and keep the last number."
            },
            {
              "id": "securityPass",
              "title": "A security review",
              "body": "This release went through a security review. Removing a service now revokes its inbox ingest key before clearing local records, and if you’re offline you’ll be told, instead of a working key being left behind."
            }
          ]
        },
        "ja": {
          "title": "TollCat 1.3：Android と Apple Watch に",
          "items": [
            {
              "id": "watchGlance",
              "title": "手首でも見られます",
              "body": "iPhone 版に Apple Watch アプリと文字盤のコンプリケーションが加わりました。手首を見るだけで、今月ここまでの金額がわかります。ロック画面にも置けます。"
            },
            {
              "id": "androidFirstRelease",
              "title": "Android 版ができました",
              "body": "iPhone と同じ計算、同じ接続ガイドで、ダッシュボードは Material 3 に合わせて作り直しました。認証情報はこのスマートフォンの Android Keystore にだけ保存されます。"
            },
            {
              "id": "foreignCurrencyLines",
              "title": "外貨の明細も換算するように",
              "body": "ユーロや円などで請求されるサービスでは、明細の行が元の通貨の金額のままドルとして表示されていました。明細も合計と同じレートで換算するようにしました。"
            },
            {
              "id": "failedNotZero",
              "title": "取得に失敗したときに $0 と表示しないように",
              "body": "認証情報の期限切れや API のエラーのときに、今月を $0 と表示してしまうサービスがありました。今は取得に失敗したことをお知らせし、前回の数字をそのまま残します。"
            },
            {
              "id": "securityPass",
              "title": "セキュリティを見直しました",
              "body": "今回のリリースではセキュリティを点検しました。サービスを削除するときは、検針ポストの投函キーを取り消してからローカルの記録を消します。オフラインで取り消せないときはお知らせし、使えるキーを残したままにはしません。"
            }
          ]
        }
      }
    },
    {
      "version": "1.2.0",
      "platforms": [
        "mac"
      ],
      "copy": {
        "zh": {
          "title": "TollCat 上 Mac 了",
          "items": [
            {
              "id": "macFirstRelease",
              "title": "Mac 版来了",
              "body": "和 iPhone 上是同一个 App，同一份接入说明，同一套数字。凭据仍然只待在你输入它的那台机器上。"
            },
            {
              "id": "macMenuBar",
              "title": "菜单栏上就能看见",
              "body": "猫蹲在菜单栏里，点开就是这个月到现在花了多少。想让金额一直露在外面也行，设置里三种样式随便挑。"
            },
            {
              "id": "macStaysAround",
              "title": "关掉窗口它还在",
              "body": "窗口关了只是收进菜单栏，不退出。也可以设成开机就启动，早上打开电脑，数字已经在那儿了。"
            },
            {
              "id": "macAutoUpdate",
              "title": "自己更新",
              "body": "从官网直接下载的这一版会自己留意有没有新版本，装的时候不用再跑一趟网站。"
            }
          ]
        },
        "en": {
          "title": "TollCat comes to the Mac",
          "items": [
            {
              "id": "macFirstRelease",
              "title": "The Mac app is here",
              "body": "The same app as on iPhone, with the same setup guides and the same numbers. Your credentials still never leave the machine you typed them into."
            },
            {
              "id": "macMenuBar",
              "title": "Right there in the menu bar",
              "body": "The cat sits in the menu bar, and clicking it shows what this month has cost so far. Prefer the amount always on show? Settings has three styles to choose from."
            },
            {
              "id": "macStaysAround",
              "title": "Closing the window does not quit it",
              "body": "Close the window and it tucks itself into the menu bar instead of quitting. You can also have it start with the Mac, so the number is already waiting for you in the morning."
            },
            {
              "id": "macAutoUpdate",
              "title": "It updates itself",
              "body": "The copy you download from the site keeps an eye out for new versions on its own, so you never have to come back just to install one."
            }
          ]
        },
        "ja": {
          "title": "TollCat が Mac にやってきました",
          "items": [
            {
              "id": "macFirstRelease",
              "title": "Mac 版ができました",
              "body": "iPhone と同じアプリで、接続ガイドも数字も同じです。認証情報は入力したその Mac から出ません。"
            },
            {
              "id": "macMenuBar",
              "title": "メニューバーからすぐ",
              "body": "猫がメニューバーに座っていて、クリックすると今月ここまでの金額が出ます。金額を出しっぱなしにもできます。設定にスタイルが三つあります。"
            },
            {
              "id": "macStaysAround",
              "title": "ウィンドウを閉じても残ります",
              "body": "ウィンドウを閉じるとメニューバーに収まり、終了はしません。ログイン時に起動する設定にもできるので、朝には数字がもう出ています。"
            },
            {
              "id": "macAutoUpdate",
              "title": "自分で更新します",
              "body": "サイトから直接ダウンロードした版は、新しいバージョンを自分で見つけます。入れ直すためにサイトへ戻る必要はありません。"
            }
          ]
        }
      }
    },
    {
      "version": "1.1.0",
      "platforms": [
        "ios"
      ],
      "copy": {
        "zh": {
          "title": "TollCat 1.1：看哪个月，就说哪个月",
          "items": [
            {
              "id": "periodAwareCopy",
              "title": "换了月份，页面上的字也跟着换",
              "body": "选了七月或者近 3 个月，仪表盘上原来写「本月」的地方都会改成那段时间。「之最」那一节也一样。固定订阅卡在跨月区间里列的是那几个月实际扣过的每一笔，中途退掉的也算在里面。"
            },
            {
              "id": "subscriptionLine",
              "title": "订阅金额搬到日期上面",
              "body": "算进固定订阅的时候，大数字底下多一行「（订阅 $X）」，告诉你总数里有多少是订阅。关掉订阅这一行就不出现，不再写「已计入」「未计入」。"
            },
            {
              "id": "guidesRewritten",
              "title": "155 家的接入说明重写了",
              "body": "每一步都指到真正创建密钥的那一页，顺手写清要哪些权限、密钥只显示一次这类容易踩的坑。连接失败时的提示也按每家的实际情况改准了。"
            },
            {
              "id": "fourVerified",
              "title": "DigitalOcean、Stripe、Botpress、Neo4j Aura 用真实账单核对过了",
              "body": "这四家从「待验证」升为「完全支持」。接上去，数字就是你账单上的数字。"
            },
            {
              "id": "exchangeRedaction",
              "title": "反馈里附带的响应，打码更严了",
              "body": "发反馈时选择附带测试连接的响应，所有以 token 结尾的字段一律打掉，之前有几家的写法漏了。用量统计里的 tokens 数字不受影响。"
            }
          ]
        },
        "en": {
          "title": "TollCat 1.1: says the month you’re looking at",
          "items": [
            {
              "id": "periodAwareCopy",
              "title": "Pick a month, and the page talks about that month",
              "body": "Choose July or the last 3 months and every spot that used to say “this month” now names that period, the superlatives section included. Over a multi-month range the subscriptions card lists what was actually charged in those months, cancelled ones too."
            },
            {
              "id": "subscriptionLine",
              "title": "The subscription amount now sits above the date",
              "body": "With subscriptions included, a line like “(Subscriptions $20)” appears under the big number so you can see how much of the total is subscriptions. Turn them off and the line goes away. No more “included” or “not included”."
            },
            {
              "id": "guidesRewritten",
              "title": "Setup guides for 155 services, rewritten",
              "body": "Each step now points at the exact page where the key gets created, and calls out the traps along the way: which permission to tick, keys that are shown only once. The messages you see when a connection fails were made specific to each service too."
            },
            {
              "id": "fourVerified",
              "title": "DigitalOcean, Stripe, Botpress and Neo4j Aura checked against real bills",
              "body": "These four move from “pending verification” to fully supported. Connect one and the number you see is the number on your bill."
            },
            {
              "id": "exchangeRedaction",
              "title": "Stricter redaction in feedback attachments",
              "body": "If you attach the test-connection response to a feedback report, every field ending in “token” is now blanked out. A few services spelled theirs in a way that slipped through before. Usage counts like total_tokens are untouched."
            }
          ]
        },
        "ja": {
          "title": "TollCat 1.1：見ている月の言葉で話す",
          "items": [
            {
              "id": "periodAwareCopy",
              "title": "月を選べば、画面の言葉もその月に",
              "body": "7月や直近3か月を選ぶと、これまで「今月」と書いていた場所がすべてその期間の名前になります。「トップ」のセクションも同じです。複数月の範囲では、サブスクリプションのカードにその期間に実際に引き落とされた分が並びます。途中で解約したものも含みます。"
            },
            {
              "id": "subscriptionLine",
              "title": "サブスクの金額は日付の上に",
              "body": "サブスクリプションを含める設定にすると、大きな数字の下に「（サブスク $20）」のような一行が出て、合計のうちいくらがサブスクかがわかります。含めない設定ではこの行は出ません。「計上済み」「未計上」という表記はなくしました。"
            },
            {
              "id": "guidesRewritten",
              "title": "155 サービスの接続ガイドを書き直しました",
              "body": "どの手順も、実際にキーを作るページを指すようにしました。必要な権限や、キーが一度しか表示されないことなど、つまずきやすい点も添えています。接続に失敗したときの案内も、サービスごとの実情に合わせました。"
            },
            {
              "id": "fourVerified",
              "title": "DigitalOcean、Stripe、Botpress、Neo4j Aura を実際の請求で確認",
              "body": "この4社は「検証待ち」から「完全対応」になりました。接続すれば、表示される数字はそのまま請求書の数字です。"
            },
            {
              "id": "exchangeRedaction",
              "title": "フィードバックに添える応答のマスクを厳しくしました",
              "body": "フィードバックに接続テストの応答を添えるとき、「token」で終わる項目はすべて伏せ字にします。以前は一部のサービスの書き方がすり抜けていました。利用量の tokens の数字はそのまま残ります。"
            }
          ]
        }
      }
    },
    {
      "version": "1.0.0",
      "date": "2026-09-12",
      "platforms": [
        "ios"
      ],
      "copy": {
        "zh": {
          "title": "TollCat 1.0：云账单，装进口袋",
          "items": [
            {
              "id": "firstRelease",
              "title": "第一版上架了",
              "body": "先从 iPhone 和 iPad 开始。把各家云和 AI 服务的花费加在一起，打开就能看到这个月到现在一共花了多少。"
            }
          ]
        },
        "en": {
          "title": "TollCat 1.0: your cloud bills, in your pocket",
          "items": [
            {
              "id": "firstRelease",
              "title": "The first release",
              "body": "iPhone and iPad first. TollCat adds up what you spend across your cloud and AI services, so one glance tells you how much this month has cost so far."
            }
          ]
        },
        "ja": {
          "title": "TollCat 1.0：クラウドの請求を、ポケットに",
          "items": [
            {
              "id": "firstRelease",
              "title": "はじめてのリリース",
              "body": "まずは iPhone と iPad から。クラウドや AI サービスの利用料をまとめて、今月ここまでいくら使ったかがひと目でわかります。"
            }
          ]
        }
      }
    }
];

export function latestChangelog(): ChangelogEntry | undefined {
  return changelog[0];
}

export function changelogAnchor(version: string): string {
  return `v${version}`;
}

export function formatChangelogDate(locale: Locale, iso: string): string {
  const [year, month, day] = iso.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return new Intl.DateTimeFormat(siteConfig.localeBcp47[locale], {
    dateStyle: 'long',
    timeZone: 'UTC',
  }).format(date);
}

export function formatChangelogPlatforms(
  platforms: readonly ChangelogPlatform[]
): string {
  return PLATFORM_ORDER.filter((item) => platforms.includes(item))
    .map((item) => platformNames[item])
    .join(' · ');
}
