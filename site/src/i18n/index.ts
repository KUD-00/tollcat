import { localePath, siteConfig, type Locale } from '../config';

export type Faq = { q: string; a: string; href?: string; link?: string };

/** 法务页的一段：普通段落，或一组「平台：一句话」的条目。 */
export type LegalBlock = string | { list: { term: string; text: string }[] };

export type LegalSection = { h: string; p: LegalBlock[] };

export type TrustSlide = {
  title: string;
  paragraphs: string[];
  to?: 'github' | 'privacy' | 'verify';
  link?: string;
};

export type PlatformShot = 'dashboard' | 'portrait' | 'window' | 'menubar';

export type PlatformSlide = {
  title: string;
  paragraphs: string[];
  /** 没有截图的 slide（如安卓 / Windows 预告页）不声明 shot。 */
  shot?: PlatformShot;
  to?: 'github';
  link?: string;
};

export type PlatformDialogCopy = {
  title: string;
  lede: string;
  slides: PlatformSlide[];
  /**
   * 直接下载那一颗。只有 Mac 有：iOS 走 App Store，安卓和 Windows 还没发。
   * `note` 必须说清「拖进应用程序」——zip 解开就在「下载」里，在那儿直接双击
   * 运行的话 macOS 会把它挪到一个随机只读路径（app translocation），
   * Sparkle 之后就没法原地更新了。
   */
  download?: {
    label: string;
    note: string;
  };
};

export function faqPlain(item: Faq, origin = siteConfig.url): string {
  if (!item.href) return item.a;
  const href = item.href.startsWith('http') ? item.href : new URL(item.href, origin).toString();
  return `${item.a} ${href}`;
}

export function faqVisible(item: Faq): string {
  if (!item.href) return item.a;
  return `${item.a} ${item.link ?? item.href}`;
}

export type Copy = {
  meta: {
    title: string;
    description: string;
    ogTitle: string;
    ogDescription: string;
  };
  a11y: {
    skip: string;
    nav: string;
    lang: string;
    langMenu: string;
    meter: string;
    gallery: string;
    providers: string;
    github: string;
    theme: string;
    themeMenu: string;
  };
  theme: {
    system: string;
    light: string;
    dark: string;
  };
  nav: {
    setup: string;
    providers: string;
    faq: string;
    support: string;
  };
  langName: Record<Locale, string>;
  langShort: Record<Locale, string>;
  hero: {
    h1: string[];
    /** 轮换的备选标题，每条与 h1 同为两行；无 JS / reduce-motion 时只显示 h1 */
    h1Alts: string[][];
    lede: string;
    ctaSoon: string;
    ctaStore: string;
  };
  meter: {
    value: string;
    forecast: string;
  };
  gallery: {
    dashboard: string;
    services: string;
    wizard: string;
  };
  setup: {
    title: string[];
    lede: string;
  };
  providers: {
    title: string[];
    note: string;
    listLink: string;
  };
  credentials: {
    title: string[];
    starLabel: string;
    lede: string;
    link: string;
    phoneLabel: string;
    dialog: {
      title: string;
      close: string;
      prev: string;
      next: string;
      page: string;
      pageA11y: string;
      slides: TrustSlide[];
    };
  };
  platforms: {
    title: string[];
    ipad: string;
    mac: string;
    android: string;
    windows: string;
    clusterLabel: string;
    dialog: {
      close: string;
      prev: string;
      next: string;
      page: string;
      pageA11y: string;
      ipad: PlatformDialogCopy;
      mac: PlatformDialogCopy;
      android: PlatformDialogCopy;
      windows: PlatformDialogCopy;
    };
  };
  facts: {
    title: string;
    lede: string;
    items: string[];
    not: string;
  };
  faq: {
    title: string;
    items: Faq[];
  };
  footer: {
    blurb: string;
    privacy: string;
    changelog: string;
    support: string;
    providers: string;
    sponsors: string;
    copyright: string;
  };
  supportListPage: {
    title: string;
    description: string;
    close: string;
    back: string;
    search: string;
    empty: string;
    footnote: string;
    footnoteLink: string;
    sections: {
      tested: { title: string; lede: string };
      theoretical: { title: string; lede: string };
      inbox: { title: string; lede: string };
      unsupported: { title: string; lede: string };
    };
    market: {
      1: { label: string; lede: string };
      2: { label: string; lede: string };
      3: { label: string; lede: string };
      4: { label: string; lede: string };
    };
    detail: {
      open: string;
      kinds: {
        usage: string;
        prepaid: string;
        subscription: string;
        freeTier: string;
        planAndUsage: string;
      };
      status: {
        tested: string;
        theoretical: string;
        inbox: string;
        unsupported: string;
      };
      chipDaily: string;
      chipHistory: string;
      chipRefresh: string;
      credentials: string;
      secret: string;
      steps: string;
      plans: string;
      perMonth: string;
      perYear: string;
      billing: string;
      setup: string;
      docs: string;
      actions: string;
      troubleshooting: string;
    };
  };
  privacyPage: {
    title: string;
    description: string;
    updated: string;
    sections: LegalSection[];
  };
  supportPage: {
    title: string;
    description: string;
    lede: string;
    form: {
      category: string;
      categories: { value: string; label: string }[];
      message: string;
      contact: string;
      contactHint: string;
      submit: string;
      sending: string;
      sent: string;
      rateLimited: string;
      failed: string;
    };
  };
  sponsorsPage: {
    title: string;
    description: string;
    lede: string;
    offer: { title: string; p: string[] };
    refuse: { title: string; items: string[] };
    who: { title: string; p: string[] };
    form: {
      title: string;
      lede: string;
      prefix: string;
      company: string;
      provider: string;
      providerHint: string;
      message: string;
      messageHint: string;
      contact: string;
      contactHint: string;
      submit: string;
      sending: string;
      sent: string;
      rateLimited: string;
      failed: string;
    };
  };
  changelogPage: {
    title: string;
    description: string;
    lede: string;
    empty: string;
  };
};

const zh: Copy = {
  meta: {
    title: 'TollCat · 云账单，装进口袋',
    description:
      '账单 App，管你自己在付的那些云和 AI。这个月一共花了多少，打开就能看到总数。凭据只写本机 Keychain。没有账号，没有后端。',
    ogTitle: 'TollCat · 云账单，装进口袋',
    ogDescription: '把各家云账单，装进口袋。凭据不出这台设备。',
  },
  a11y: {
    skip: '跳到正文',
    nav: '主导航',
    lang: '语言',
    langMenu: '选择语言',
    meter: '本月合计示例 43.20 美元，预计月底 51.51 美元。iPhone 模拟器演示数据。',
    gallery: 'App 截图',
    providers: '目前能接的服务',
    github: 'GitHub 上的源码',
    theme: '外观',
    themeMenu: '选择外观',
  },
  theme: {
    system: '跟随系统',
    light: '浅色',
    dark: '深色',
  },
  nav: {
    setup: '接入',
    providers: '能接哪些',
    faq: '常见问题',
    support: '联系我们',
  },
  langName: { zh: '中文', en: 'English', ja: '日本語' },
  langShort: { zh: '中', en: 'EN', ja: '日' },
  hero: {
    h1: ['一眼看出', '这个月花了多少。'],
    h1Alts: [
      ['云上花的钱，', '可能比你想的多。'],
      ['锁屏一瞥，', '账单都在。'],
      ['给云服务，', '装一块电表。'],
    ],
    lede: '账单 App，管你自己在付的那些云和 AI。把各家花费加在一起，给你一个总数。凭据不出这台设备。',
    ctaSoon: 'App Store 即将上架',
    ctaStore: '在 App Store 获取',
  },
  meter: {
    value: '$43.20',
    forecast: '预计月底 $51.51',
  },
  gallery: {
    dashboard: '仪表盘',
    services: '已接入的服务',
    wizard: '接入说明',
  },
  setup: {
    title: ['接入各家服务，', '照着做就行。'],
    lede: '向导一步步带你开出只读凭据，要给哪个权限、叫什么名字，都写在步骤里。真正取到金额之后，凭据才存进这台设备。',
  },
  providers: {
    title: ['你在用的 SaaS，', '大都能接上。'],
    note: '没有官方账单接口的服务，可以在自己电脑上算好数字，投进读数信箱。以 App 内名单为准。',
    listLink: '服务支持清单',
  },
  credentials: {
    title: ['凭据只在设备上，', '绝对安全'],
    starLabel: '打开这项主张的说明',
    lede: '钥匙只写进这台手机。不进 iCloud，也不经过 TollCat 的服务器。',
    link: '为什么这么说',
    phoneLabel: '演示：各家图标收入这台设备上的锁里。',
    dialog: {
      title: '这项主张指什么',
      close: '关闭',
      prev: '上一则',
      next: '下一则',
      page: '{current} / {total}',
      pageA11y: '第 {current} 则，共 {total} 则',
      slides: [
        {
          title: '开源以及验证',
          paragraphs: [
            '源码在 GitHub 上，MIT 许可。可以自己编译，装到自己的手机上看它做什么。',
            'App Store 上的包会被 Apple 重新签名并加密，做不到和这份源码编出逐字节相同的副本。能核对的是公开构建的溯源证明，以及可执行文件的 UUID。步骤写在仓库里。',
          ],
          to: 'github',
          link: 'github.com/KUD-00/tollcat',
        },
        {
          title: '钥匙串有多严',
          paragraphs: [
            'Keychain 是这台 iPhone 自带的加密钥匙串。钥匙由系统保管，不会写进这个 App 自己的文件里。',
            '我们只用最严的一档：设备解锁之后才可读，不进 iCloud，也不跟系统备份走。你删掉一家服务，对应那条钥匙一起删。',
          ],
        },
        {
          title: '请求怎么走',
          paragraphs: [
            '刷新账单时，请求从这台手机直达各家官方接口。中间没有 TollCat 的服务器代发，也看不到钥匙。',
            '这台 App 会连到哪些域名，设置 → 关于里列着。源码里有同一份清单，编的时候会核对没有漏网的地址。',
          ],
        },
        {
          title: '换手机怎么办',
          paragraphs: [
            '钥匙故意不进 iCloud，换机不能靠系统同步。旧手机导出一份加密的 .tollcat，新手机输入屏幕上的 10 位码。',
            '码离开导入页就失效。文件 24 小时后不能再导入——这只缩小误发的窗口，不是加密本身的强度。历史读数不随文件走，导入后再刷一次即可。',
          ],
        },
        {
          title: '服务器碰得到什么',
          paragraphs: [
            '这个项目有一个服务端，只处理打赏留言、反馈、公开目录、读数信箱和匿名的页面计数。以上没有一处会经手凭据或账单。',
            '有服务端，不等于可以用服务端去取账单。',
          ],
          to: 'privacy',
          link: '隐私政策',
        },
      ],
    },
  },
  platforms: {
    title: ['更多平台支持'],
    ipad: 'iPad 版',
    mac: 'Mac 版',
    android: '安卓版',
    windows: 'Windows 版',
    clusterLabel: 'iPad 横屏和 Mac 窗口。',
    dialog: {
      close: '关闭',
      prev: '上一则',
      next: '下一则',
      page: '{current} / {total}',
      pageA11y: '第 {current} 则，共 {total} 则',
      ipad: {
        title: 'iPad 版',
        lede: '和 iPhone 同一份 App，不用另装。',
        slides: [
          {
            title: '空间更大，能看更多',
            shot: 'dashboard',
            paragraphs: [],
          },
          {
            title: '竖过来，依旧精彩',
            shot: 'portrait',
            paragraphs: [],
          },
        ],
      },
      mac: {
        title: 'Mac 版',
        lede: '原生 Mac 应用。菜单栏里会多出一只账单猫猫。',
        download: {
          label: '下载 Mac 版',
          note: '下载后解压，把 TollCat 拖进「应用程序」。需要 macOS 26。',
        },
        slides: [
          {
            title: '菜单栏',
            shot: 'menubar',
            paragraphs: [],
          },
          {
            title: '原生应用，为 Mac 适配更多',
            shot: 'window',
            paragraphs: [
              '原生 Mac 应用，SwiftUI 写的，不是网页套一层 Electron。点开就在，放着不管也不怎么占内存。',
              '凭据只写这台电脑的钥匙串，和 iPhone、iPad 不共享。',
            ],
          },
        ],
      },
      android: {
        title: '安卓版',
        lede: '还没做完，敬请期待。',
        slides: [
          {
            title: '还在做',
            paragraphs: ['仓库里有一份早期的 Android 版本。'],
            to: 'github',
            link: 'GitHub',
          },
        ],
      },
      windows: {
        title: 'Windows 版',
        lede: '还没做完，敬请期待。',
        slides: [
          {
            title: '还在做',
            paragraphs: ['仓库里有一份早期的 Windows 版本。'],
            to: 'github',
            link: 'GitHub',
          },
        ],
      },
    },
  },
  facts: {
    title: '它做什么',
    lede: '账单 App，管你自己在付的那些云和 AI。把各家后台这个月的花费加在一起，给你一个总数，底下是各家的明细。这个数也能放到锁屏、主屏小组件和 Mac 菜单栏上。',
    items: [
      '凭据只写本机 Keychain，不进 iCloud，也不经过 TollCat 的服务器。',
      '只读：不关实例、不改配额、不远程推送。',
      '没有账号。可选的服务端只处理打赏留言、反馈、公开目录和读数信箱，这几样都碰不到你的凭据。',
      '免费，可选打赏，无会员。MIT 许可。iPhone、iPad 和 Mac。iOS 26 或 macOS 26。账本按美元记。',
    ],
    not: '它不是 FinOps 套件，不是费用异常告警，也不是云控制台。本页截图是模拟器里的演示数字，不是线上数据。',
  },
  faq: {
    title: '常见问题',
    items: [
      {
        q: 'API Key 会离开这台设备吗？',
        a: '不会。Key 只存在这台手机的 Keychain 里（WhenUnlockedThisDeviceOnly）：不进 iCloud，也不随系统备份走。取账单时由这台设备直连各家官方 API，中间没有任何服务器经手凭据。',
      },
      {
        q: '想用的服务似乎不支持？',
        a: '完整名单在服务支持清单里。没有官方账单接口的服务，可以在自己电脑上算好数字，投进读数信箱。想加哪一家，来联系页告诉我们。',
        href: localePath('zh', 'providers'),
        link: '服务支持清单',
      },
      {
        q: '换手机怎么办？',
        a: '凭据故意不进 iCloud，换机靠导出：旧手机导出一份加密的 .tollcat 文件，新手机输入屏幕上的 10 位码导入。码一离开导入页就失效，文件过 24 小时也作废。历史数据不在文件里，导入后刷新一次就回来了。',
      },
      {
        q: '收费吗？',
        a: '完全免费。',
      },
      {
        q: '这是 FinOps 吗？会改我的云资源吗？',
        a: '不是。TollCat 只报告花费。它不关实例、不改配额、不发远程推送，也不用云端模型算账单。本地提醒可选，通知里不放金额。',
      },
      {
        q: '支持哪些设备？货币呢？',
        a: 'iPhone、iPad 和 Mac。iOS 26 或 macOS 26。账本一律按美元记。显示货币只改变金额怎么显示，不会去查实时汇率。',
      },
      {
        q: '源码在哪？',
        a: '都在 GitHub 上，MIT 许可。可以自己编译，也可以核对 App Store 的包是不是从这份源码构建的，步骤都写在仓库里。',
        href: siteConfig.githubUrl,
        link: 'github.com/KUD-00/tollcat',
      },
      {
        q: '安卓版呢？',
        a: '还没做完，敬请期待！等不及的话，欢迎来 GitHub 搭把爪。',
        href: siteConfig.githubUrl,
        link: 'GitHub',
      },
    ],
  },
  footer: {
    blurb: '把各家云账单，装进口袋。',
    privacy: '隐私政策',
    changelog: '更新说明',
    support: '联系我们',
    providers: '服务支持清单',
    sponsors: '出现在介绍里',
    copyright: '© 2026 TollCat. MIT License.',
  },
  supportListPage: {
    title: '服务支持清单',
    description:
      'TollCat 完全支持并测试过的、理论完全支持的、只走读数信箱的、以及不接入的服务。以 App 内名单为准。',
    close: '关闭',
    back: '返回',
    search: '找一家服务',
    empty: '名单里没有这个名字。',
    footnote: '名单和 App 是同一份。想接哪一家，用联系页告诉我们。',
    footnoteLink: '联系我们',
    sections: {
      tested: {
        title: '完全支持并测试过的',
        lede: '填入只读凭据，账单自动进来。我们用真实账号对过账。',
      },
      theoretical: {
        title: '理论完全支持的',
        lede: '公开文档里有账单接口，App 里也接得上。还没拿真实账单对过。',
      },
      inbox: {
        title: '只支持读数信箱的',
        lede: '官方没有能对账的账单接口，需要你在自己电脑上算好数字，投进读数信箱；固定订阅也可以直接手填。',
      },
      unsupported: {
        title: '不支持的',
        lede: '核实过，接不上。没有一份能对账的公开账单金额。目录里留着名字，避免再核一次。',
      },
    },
    market: {
      1: {
        label: '头部',
        lede: '这一类里它是头部，或和少数几家分市场。',
      },
      2: {
        label: '挑战者',
        lede: '这一类里人们会认真考虑的替代。',
      },
      3: {
        label: '新秀',
        lede: '规模还小，但还在长。',
      },
      4: {
        label: '在退',
        lede: '规模还小，而且在往下走。',
      },
    },
    detail: {
      open: '查看接入说明',
      kinds: {
        usage: '按用量',
        prepaid: '预充值',
        subscription: '固定订阅',
        freeTier: '免费额度',
        planAndUsage: '套餐加用量',
      },
      status: {
        tested: '已测试',
        theoretical: '理论支持',
        inbox: '读数信箱',
        unsupported: '不接入',
      },
      chipDaily: '可按日看',
      chipHistory: '可回看 {n} 个月',
      chipRefresh: '刷新会花钱',
      credentials: '要填的凭据',
      secret: '密钥',
      steps: '怎么拿',
      plans: '套餐',
      perMonth: '/ 月',
      perYear: '/ 年',
      billing: '去官网账单',
      setup: '去签发凭据',
      docs: '相关文档',
      actions: '官网',
      troubleshooting: '接不上的时候',
    },
  },
  privacyPage: {
    title: '隐私政策',
    description: 'TollCat 不设账号，凭据不出设备。本页说明 App 和本站实际处理哪些数据。',
    updated: '最近更新：2026 年 9 月 5 日',
    sections: [
      {
        h: '凭据与账单',
        p: [
          '你录入的 API Key、token、账号标识只写进这台设备，每个系统用它自己的那把锁。',
          {
            list: [
              {
                term: 'iOS / iPadOS',
                text: 'iOS Keychain，访问控制为 WhenUnlockedThisDeviceOnly。不进 iCloud Keychain，也不随系统备份离开这台设备。',
              },
              { term: 'macOS', text: '这台电脑的 Keychain，同一档，和 iPhone、iPad 不共享。' },
              {
                term: 'Android',
                text: '仓库里那份开发中的版本用 Android Keystore 加密后存在本机，不进云备份。还没有上架。',
              },
              {
                term: 'Windows',
                text: '仓库里那份开发中的版本存进 Windows 凭据管理器，只这台电脑读得到。还没有上架。',
              },
            ],
          },
          '取账单的请求从这台设备直达各家官方 API。TollCat 的服务器不代理这些请求，也看不到这些凭据。',
          '账单历史、订阅、偏好存放在设备上。iOS 上它们在 App Group 容器里，供 App 和 Widget 共用。Widget 自己不会发起任何请求。',
        ],
      },
      {
        h: '本站与可选服务端',
        p: [
          '你现在阅读的 tollcat.app 是静态页面，不设账号、不写 cookie、不跑分析脚本。部署到 Cloudflare 之后，边缘网络会处理连接元数据（IP、User-Agent、时间），用于传输与防护，我们不用它识别你。',
          'api.tollcat.app 是这个项目唯一的服务端，和落地页分开。它处理打赏留言、应用内反馈、公开的接入说明目录（文字、套餐价、汇率；不含任何 URL 或凭据）、给没有官方账单接口的服务准备的读数信箱，以及匿名的页面计数。以上没有一处会经手 provider 凭据。',
          '读数信箱里的投递 key 与读取 key 只存 SHA-256。每个信箱对每个服务只保留最新一条金额。最坏情况被拖库，泄露的是和人对不上的匿名数字，不是能替谁花钱的东西。',
        ],
      },
      {
        h: '换设备',
        p: [
          '凭据故意不进 iCloud。换手机时你可以导出一份加密的 .tollcat，用屏幕上的 10 位码导入。码离开导入页就没了。文件 24 小时后不能再导入，这只缩小误发的窗口，不是加密本身的强度。历史读数不随文件走，导入后再刷一次即可。',
        ],
      },
      {
        h: '本地提醒',
        p: [
          '可以打开定时提醒，让这台设备在你选定的时间叫你去看一眼。通知里不放金额。没有基于额度的告警，也没有远程推送。',
        ],
      },
      {
        h: '反馈与打赏',
        p: [
          '应用内反馈可以匿名提交。你如果留下联系方式，我们只用它回复这一条。随反馈送出的环境信息（系统版本、App 版本等）会在提交前逐项列在同一屏上。',
          '打赏走 Apple 的 App 内购买。Apple 会按自己的政策处理支付。我们能看到的是一笔已完成的购买和你愿意留下的留言，看不到完整卡号。',
        ],
      },
      {
        h: '匿名页面计数',
        p: [
          'App 会把你打开过哪些页面报给 api.tollcat.app，用来看每天有多少次打开、各页进了多少次。报的是：平台（iOS、Android、macOS 或 Windows）、App 版本、允许名单里的页面名、以及「这个 UTC 日是不是第一次打开」。',
          '这份数字还有一个用途：TollCat 以后可能会放一点不打扰人的广告来养活自己。要不要放、放在哪一页，得先知道哪些页面真的有人看。真做这件事之前，本页会先写清楚。',
          '没有账号，没有广告标识，没有设备指纹，没有稳定的匿名 ID。同一页连续停着只计一次；服务端只把数字加总，不留事件流水，也不用 IP 认人。页面名不含你接入了哪家服务。',
        ],
      },
      {
        h: '我们不收集的',
        p: [
          '不做广告标识符，不做跨站跟踪，不把账单卖给任何人。Privacy Nutrition Label 里声明的项，都是功能本身需要的（例如打赏产生的购买记录、匿名的产品交互计数），并且关闭跟踪。',
        ],
      },
      {
        h: '儿童',
        p: ['TollCat 不是面向 13 岁以下儿童的产品。我们并不知道用户年龄，因为没有账号。'],
      },
      {
        h: '改动',
        p: [
          '政策若有实质变化，会改本页的日期。继续使用 App 即表示你看到的是这一版。',
          '关于本政策：打开 App → 设置 → 反馈，或用本站的联系页。两条路都打到 api.tollcat.app，都不带凭据。',
        ],
      },
    ],
  },
  supportPage: {
    title: '联系我们',
    description: '和 App 里的反馈是同一条路，打到 api.tollcat.app，不带凭据。',
    lede: '这条路和 App 里「设置 → 反馈」是同一条，都打到 api.tollcat.app，不带凭据。没有账号，想收到回复就留下联系方式。',
    form: {
      category: '类型',
      categories: [
        { value: 'bug', label: '哪里坏了' },
        { value: 'idea', label: '想要什么' },
        { value: 'provider', label: '想接哪家服务' },
        { value: 'other', label: '其他' },
      ],
      message: '说什么都行',
      contact: '邮箱或任意联系方式',
      contactHint: '可留空',
      submit: '发送',
      sending: '正在发送',
      sent: '收到了，谢谢。',
      rateLimited: '刚才提得有点密，过十分钟再来。',
      failed: '没发出去。内容还在，检查一下网络再试。',
    },
  },
  sponsorsPage: {
    title: '出现在介绍里',
    description: '出现在付你们钱的人查看这笔账的地方。不卖用户，也不卖名单怎么排。',
    lede: '打开 TollCat 的人，是来看这个月付给各家云和 AI 的钱。想出现在你们自己那一页的介绍里，在这里谈。',
    offer: {
      title: '卖什么',
      p: [
        '卖的是你们自己那一页、介绍下面的一块地方。一句话、一段说明、一个按钮，内容你们自己写。',
        '这一块会标明是你们写的。没买的那一页保持原样，只写能不能接、要什么凭据。',
      ],
    },
    refuse: {
      title: '不卖什么',
      items: [
        'App 里的广告、横幅、推荐卡。',
        '服务支持清单的排序和状态。',
        '接入向导的步骤、权限名、跳转地址。',
        '用户、账单、广告标识符，或任何跟踪像素。',
        '首页第一屏。',
      ],
    },
    who: {
      title: '谁适合',
      p: [
        '已经在目录里的云和 AI 服务。来这里的人，多半已经在付给你们钱，或正要把你们加进账单。',
        '价格按家谈。我们不拿编出来的浏览量凑数。',
      ],
    },
    form: {
      title: '开始谈',
      lede: '写下公司名、想出现在哪一家、以及怎么联系。预算和希望出现的时间，可以写在说明里。',
      prefix: '出现在介绍里',
      company: '公司',
      provider: '想出现在哪一家',
      providerHint: '目录里的名字。空着也行。',
      message: '想说的',
      messageHint: '预算、希望什么时候出现，都可以写在这里。',
      contact: '邮箱',
      contactHint: '我们用这个地址回你。',
      submit: '发送',
      sending: '正在发送',
      sent: '收到了，我们会从这条联系方式回。',
      rateLimited: '刚才提得有点密，过十分钟再来。',
      failed: '没发出去。内容还在，检查一下网络再试。',
    },
  },
  changelogPage: {
    title: '更新说明',
    description: 'TollCat 每个正式版都会写在这里。',
    lede: '每个正式版都会写在这里。',
    empty: '还没有正式版写在这里。发了就会按版本记下来。',
  },
};

const en: Copy = {
  meta: {
    title: 'TollCat · Your cloud bills, in your pocket',
    description:
      'A billing app for the cloud and AI services you pay for. Open it and see this month’s total. Credentials stay in on-device Keychain. No account, no backend.',
    ogTitle: 'TollCat · Your cloud bills, in your pocket',
    ogDescription: 'Your cloud bills, in your pocket. Credentials never leave this device.',
  },
  a11y: {
    skip: 'Skip to content',
    nav: 'Primary',
    lang: 'Language',
    langMenu: 'Choose language',
    meter: 'Sample month-to-date $43.20, forecast $51.51. iPhone simulator demo data.',
    gallery: 'App screenshots',
    providers: 'Supported services',
    github: 'Source on GitHub',
    theme: 'Appearance',
    themeMenu: 'Choose appearance',
  },
  theme: {
    system: 'System',
    light: 'Light',
    dark: 'Dark',
  },
  nav: {
    setup: 'Setup',
    providers: 'Providers',
    faq: 'FAQ',
    support: 'Contact',
  },
  langName: { zh: '中文', en: 'English', ja: '日本語' },
  langShort: { zh: '中', en: 'EN', ja: '日' },
  hero: {
    h1: ['See it at a glance.', 'What you spent this month.'],
    h1Alts: [
      ['You’re probably spending', 'more than you think.'],
      ['One glance at the Lock Screen.', 'Every bill is there.'],
      ['A utility meter', 'for your cloud.'],
    ],
    lede: 'A billing app for the cloud and AI services you pay for. It adds up what they cost into one total. Credentials stay on this device.',
    ctaSoon: 'Coming to the App Store',
    ctaStore: 'Get it on the App Store',
  },
  meter: {
    value: '$43.20',
    forecast: 'Forecast $51.51 by month end',
  },
  gallery: {
    dashboard: 'Dashboard',
    services: 'Connected services',
    wizard: 'Setup guide',
  },
  setup: {
    title: ['Connect each service.', 'Follow the steps.'],
    lede: 'The walkthrough takes you to a read-only credential, and each step names the exact permission you are granting. Nothing is saved until a real amount comes back.',
  },
  providers: {
    title: ['The SaaS you already use.', 'Most of it connects.'],
    note: 'If a vendor has no billing API, you can post a reading from your own machine. The in-app list is the source of truth.',
    listLink: 'Support list',
  },
  credentials: {
    title: ['The keys stay on this phone.', 'Nowhere else'],
    starLabel: 'What this claim actually means',
    lede: 'Credentials are written only to this iPhone. Not iCloud. Not any TollCat server.',
    link: 'What that actually means',
    phoneLabel: 'Animation: service icons gather into a lock on this device.',
    dialog: {
      title: 'What that actually means',
      close: 'Close',
      prev: 'Previous',
      next: 'Next',
      page: '{current} / {total}',
      pageA11y: 'Item {current} of {total}',
      slides: [
        {
          title: 'Open source, and how to check',
          paragraphs: [
            'The source is on GitHub, MIT licensed. You can build it and run it on your own phone.',
            'The App Store binary is re-signed and encrypted by Apple, so it will not match this source byte for byte. What you can check is the public build’s provenance, and the executable’s UUID. The steps are in the repo.',
          ],
          to: 'github',
          link: 'github.com/KUD-00/tollcat',
        },
        {
          title: 'The phone’s own keychain',
          paragraphs: [
            'Keychain is the encrypted keystore that ships with the iPhone. The system holds the keys; this app does not write them into its own files.',
            'We use the strictest class: readable only after you unlock this device, not copied to iCloud, not included in backups. Delete a service and that key is deleted with it.',
          ],
        },
        {
          title: 'Where a refresh goes',
          paragraphs: [
            'A refresh leaves this phone for each vendor’s official API. No TollCat server sits in the middle, and none of them see a key.',
            'The domains this app talks to are listed under Settings → About. The same list lives in the source; the build fails if a host goes missing.',
          ],
        },
        {
          title: 'A new phone',
          paragraphs: [
            'Keys stay out of iCloud on purpose, so a new phone is an export you start. Save an encrypted .tollcat on the old phone, then type the 10-character code on the new one.',
            'Leave the import page and the code is gone. The file cannot be imported after 24 hours — that only shrinks the window if you sent it by mistake, and is not the strength of the encryption. History does not travel with the file; refresh once after import.',
          ],
        },
        {
          title: 'What the server never sees',
          paragraphs: [
            'There is one server. It handles tip notes, feedback, a public catalog, a reading inbox, and anonymous page counts. None of those paths see a credential or a bill.',
            'Having a server does not mean it can fetch your bill.',
          ],
          to: 'privacy',
          link: 'Privacy',
        },
      ],
    },
  },
  platforms: {
    title: ['More platforms'],
    ipad: 'iPad',
    mac: 'Mac',
    android: 'Android',
    windows: 'Windows',
    clusterLabel: 'An iPad in landscape and a Mac window.',
    dialog: {
      close: 'Close',
      prev: 'Previous',
      next: 'Next',
      page: '{current} / {total}',
      pageA11y: 'Item {current} of {total}',
      ipad: {
        title: 'iPad',
        lede: 'The same app as iPhone. You don’t install a second one.',
        slides: [
          {
            title: 'More room, more to see',
            shot: 'dashboard',
            paragraphs: [],
          },
          {
            title: 'Turn it upright, still good',
            shot: 'portrait',
            paragraphs: [],
          },
        ],
      },
      mac: {
        title: 'Mac',
        lede: 'A native Mac app. A billing cat shows up in your menu bar.',
        download: {
          label: 'Download for Mac',
          note: 'Unzip it, then drag TollCat into Applications. Needs macOS 26.',
        },
        slides: [
          {
            title: 'Menu bar',
            shot: 'menubar',
            paragraphs: [],
          },
          {
            title: 'A native app, at home on the Mac',
            shot: 'window',
            paragraphs: [
              'A real Mac app written in SwiftUI, not a web page wrapped in Electron. It opens right away, and it sits in the background without eating your memory.',
              'Credentials stay in this Mac’s keychain. They are not shared with iPhone or iPad.',
            ],
          },
        ],
      },
      android: {
        title: 'Android',
        lede: 'Not done yet — stay tuned!',
        slides: [
          {
            title: 'Still in the shop',
            paragraphs: ['The repo has an early Android build.'],
            to: 'github',
            link: 'GitHub',
          },
        ],
      },
      windows: {
        title: 'Windows',
        lede: 'Not done yet — stay tuned!',
        slides: [
          {
            title: 'Still in the shop',
            paragraphs: ['The repo has an early Windows build.'],
            to: 'github',
            link: 'GitHub',
          },
        ],
      },
    },
  },
  facts: {
    title: 'What it is',
    lede: 'A billing app for the cloud and AI services you pay for. It adds up what your backends have spent this month into one total, with the per-vendor breakdown underneath. That total can also sit on the Lock Screen, in a Home Screen widget, or in the Mac menu bar.',
    items: [
      'Credentials stay in on-device Keychain. Not iCloud. Not any TollCat server.',
      'Read-only: it does not shut down instances, change quotas, or send remote push.',
      'No accounts. The optional server handles tip notes, feedback, a public catalog, and a reading inbox — none of those paths see a provider key.',
      'Free; optional in-app tips; no membership. MIT licensed. iPhone, iPad, and Mac. iOS 26 or macOS 26. The ledger is USD.',
    ],
    not: 'It is not a FinOps suite, not a cost-anomaly pager, and not a cloud console. Screenshots on this page are demo numbers from simulators, not live data.',
  },
  faq: {
    title: 'FAQ',
    items: [
      {
        q: 'Do API keys leave this device?',
        a: 'No. They are written only to on-device Keychain with WhenUnlockedThisDeviceOnly: not iCloud, not system backups. Fetch requests go from this device to each vendor’s official API. No server ever handles a provider credential.',
      },
      {
        q: 'Missing a service you use?',
        a: 'The full roster is on the support list. If a vendor has no billing API, you can post a reading from your own machine to the reading inbox. To request a service, use the contact page.',
        href: localePath('en', 'providers'),
        link: 'Support list',
      },
      {
        q: 'What about a new phone?',
        a: 'Credentials deliberately stay out of iCloud, so moving is an export: save an encrypted .tollcat file on the old phone, then type the 10-character code shown on screen into the new one. The code dies when you leave the import page, and the file expires after 24 hours. History does not travel with the file — refresh once after import.',
      },
      {
        q: 'Does it cost money?',
        a: 'Completely free.',
      },
      {
        q: 'Is this FinOps? Will it change my cloud resources?',
        a: 'No. TollCat reports spend. It does not shut down instances, change quotas, send remote push, or compute the bill with a cloud model. A local reminder is optional and never includes an amount.',
      },
      {
        q: 'Which devices? What about currency?',
        a: 'iPhone, iPad, and Mac. iOS 26 or macOS 26. The ledger is kept in US dollars. Display currency only changes how amounts are written; it does not call a live FX API.',
      },
      {
        q: 'Where is the source?',
        a: 'It’s all on GitHub, MIT licensed. Build it yourself, or check that the App Store binary really comes from this source — the steps are in the repo.',
        href: siteConfig.githubUrl,
        link: 'github.com/KUD-00/tollcat',
      },
      {
        q: 'What about Android?',
        a: 'Not done yet — stay tuned! Too impatient to wait? Come lend a paw on GitHub.',
        href: siteConfig.githubUrl,
        link: 'GitHub',
      },
    ],
  },
  footer: {
    blurb: 'Your cloud bills, in your pocket.',
    privacy: 'Privacy',
    changelog: 'Changelog',
    support: 'Contact',
    providers: 'Support list',
    sponsors: 'In the intro',
    copyright: '© 2026 TollCat. MIT License.',
  },
  supportListPage: {
    title: 'Support list',
    description:
      'Services TollCat fully supports and has tested, those that should work from public APIs, those that only take a reading inbox, and those it does not support. The in-app list is the source of truth.',
    close: 'Close',
    back: 'Back',
    search: 'Find a service',
    empty: 'That name is not on the list.',
    footnote: 'This list matches the app. To request a service, use the contact page.',
    footnoteLink: 'Contact',
    sections: {
      tested: {
        title: 'Fully supported and tested',
        lede: 'Enter a read-only credential and the bill comes in. We have reconciled these against real accounts.',
      },
      theoretical: {
        title: 'Theoretically fully supported',
        lede: 'A public billing API exists and the app can connect. We have not yet reconciled a live bill.',
      },
      inbox: {
        title: 'Reading inbox only',
        lede: 'There is no official bill-amount API. Post a reading from your own machine. A fixed subscription can also be entered by hand.',
      },
      unsupported: {
        title: 'Not supported',
        lede: 'Checked and declined. There is no public bill-amount API we can reconcile against. The names stay in the catalog so we do not check again.',
      },
    },
    market: {
      1: {
        label: 'Lead',
        lede: 'A lead in its category, or one of the few that split it.',
      },
      2: {
        label: 'Challenger',
        lede: 'A serious alternative people actually pick.',
      },
      3: {
        label: 'Emerging',
        lede: 'Still small, and still growing.',
      },
      4: {
        label: 'Fading',
        lede: 'Still small, and shrinking.',
      },
    },
    detail: {
      open: 'Open details',
      kinds: {
        usage: 'Usage',
        prepaid: 'Prepaid',
        subscription: 'Subscription',
        freeTier: 'Free tier',
        planAndUsage: 'Plan plus usage',
      },
      status: {
        tested: 'Tested',
        theoretical: 'Should work',
        inbox: 'Inbox only',
        unsupported: 'Not supported',
      },
      chipDaily: 'Daily breakdown',
      chipHistory: '{n}-month history',
      chipRefresh: 'Refresh costs money',
      credentials: 'What to enter',
      secret: 'Secret',
      steps: 'How to get it',
      plans: 'Plans',
      perMonth: '/ month',
      perYear: '/ year',
      billing: 'Official billing',
      setup: 'Create a credential',
      docs: 'More docs',
      actions: 'Official pages',
      troubleshooting: 'If it fails',
    },
  },
  privacyPage: {
    title: 'Privacy Policy',
    description: 'TollCat has no accounts. Credentials never leave the device. This page is what the app and this site actually do.',
    updated: 'Last updated 5 September 2026',
    sections: [
      {
        h: 'Credentials and bills',
        p: [
          'API keys, tokens, and account identifiers you enter stay on this device, each system using its own lock.',
          {
            list: [
              {
                term: 'iOS / iPadOS',
                text: 'iOS Keychain, with WhenUnlockedThisDeviceOnly. Not iCloud Keychain, and not system backups.',
              },
              { term: 'macOS', text: 'This Mac’s Keychain, same class. Not shared with iPhone or iPad.' },
              {
                term: 'Android',
                text: 'The in-development build in the repo encrypts them with Android Keystore and keeps them on the phone, out of cloud backups. It has not shipped.',
              },
              {
                term: 'Windows',
                text: 'The in-development build in the repo puts them in Windows Credential Manager, readable only on that PC. It has not shipped.',
              },
            ],
          },
          'Fetch requests leave this device for each vendor’s official API. TollCat’s servers do not proxy them and never see those credentials.',
          'History, subscriptions, and preferences live on the device. On iOS they sit in the App Group container shared by the app and the widget. The widget cannot fetch on its own.',
        ],
      },
      {
        h: 'This site and the optional server',
        p: [
          'tollcat.app is a static site: no accounts, no cookies, no analytics scripts. After a Cloudflare deploy, the edge will see connection metadata (IP, user-agent, time) for delivery and abuse prevention. We do not use it to identify you.',
          'api.tollcat.app is the project’s only server, separate from this site. It handles tip messages, in-app feedback, a public setup catalog (copy, plan prices, FX rates; no URLs or credentials), a reading inbox for vendors without an official billing API, and anonymous page counts. None of those paths receive provider credentials.',
          'Inbox keys are stored as SHA-256. Each inbox keeps only the latest amount per service. A dump would leak anonymous numbers that do not attach to a person — not keys that can spend money.',
        ],
      },
      {
        h: 'Moving devices',
        p: [
          'Credentials are kept out of iCloud on purpose. To change phones, export an encrypted .tollcat file and type the 10-character code on screen. Leave the import page and the code is gone. The file cannot be imported after 24 hours; that only shrinks the window if you sent it by mistake, and is not the strength of the encryption. History does not travel with the file — refresh after import.',
        ],
      },
      {
        h: 'Local reminders',
        p: [
          'You can schedule a local reminder to look at the number. The notification never includes an amount. There are no threshold alerts and no remote push.',
        ],
      },
      {
        h: 'Feedback and tips',
        p: [
          'In-app feedback may be anonymous. If you leave a contact, it is used only to reply to that message. Environment details sent with feedback are listed on the same screen before you submit.',
          'Tips go through Apple In-App Purchase. Apple processes payment under its own policy. We see a completed purchase and any note you leave, not a full card number.',
        ],
      },
      {
        h: 'Anonymous page counts',
        p: [
          'The app reports which screens you opened to api.tollcat.app so we can see daily opens and per-screen enters. The payload is: platform (iOS, Android, macOS, or Windows), app version, an allowlisted screen name, and whether this is the first open of the UTC day.',
          'These counts have one more use: TollCat may one day carry a small amount of unobtrusive advertising to pay for itself. Whether to do that, and on which screens, depends on knowing which screens people actually read. If it happens, this page will say so first.',
          'There is no account, advertising identifier, device fingerprint, or stable anonymous ID. Staying on the same screen counts once. The server only increments totals — no event log, and IP is not used to recognise you. Screen names do not include which vendors you connected.',
        ],
      },
      {
        h: 'What we do not collect',
        p: [
          'No advertising identifier, no cross-site tracking, no selling of bills. Items on the Privacy Nutrition Label exist because a feature needs them (for example a tip purchase, or anonymous product interaction counts) and tracking is off.',
        ],
      },
      {
        h: 'Children',
        p: ['TollCat is not directed at children under 13. We do not know a user’s age because there are no accounts.'],
      },
      {
        h: 'Changes',
        p: [
          'Material changes update the date on this page. Keep using the app and you are looking at this version.',
          'Questions: open the app → Settings → Feedback, or use the contact page on this site. Both hit api.tollcat.app. Neither carries credentials.',
        ],
      },
    ],
  },
  supportPage: {
    title: 'Contact',
    description: 'Same path as in-app feedback. It hits api.tollcat.app and never carries credentials.',
    lede: 'This is the same path as Settings → Feedback in the app. Both hit api.tollcat.app. Neither carries credentials. There are no accounts — leave a contact if you want a reply.',
    form: {
      category: 'Type',
      categories: [
        { value: 'bug', label: 'Something is broken' },
        { value: 'idea', label: 'A request' },
        { value: 'provider', label: 'A service to add' },
        { value: 'other', label: 'Other' },
      ],
      message: 'Write whatever you need',
      contact: 'Email or any contact',
      contactHint: 'Optional',
      submit: 'Send',
      sending: 'Sending',
      sent: 'Received. Thank you.',
      rateLimited: 'That was a bit frequent. Try again in ten minutes.',
      failed: 'It did not send. Your text is still here — check the network and retry.',
    },
  },
  sponsorsPage: {
    title: 'In the intro',
    description:
      'Show up where the people already paying you look at that bill. We don’t sell users, and we don’t sell how the list is ranked.',
    lede: 'People open TollCat to see what they paid each cloud and AI vendor this month. If you want a spot on the page for your own service, this is the conversation.',
    offer: {
      title: 'What you can buy',
      p: [
        'You can buy a spot under the intro on your own service’s page. You write a line, a short note, and one button.',
        'It’s labeled as yours. If that page hasn’t been bought, it still only says whether it connects and which credential it needs.',
      ],
    },
    refuse: {
      title: 'What you cannot buy',
      items: [
        'Ads, banners, or recommendation cards inside the app.',
        'Rank or status in the support list.',
        'Setup-wizard steps, permission names, or destination URLs.',
        'Users, bills, advertising identifiers, or tracking pixels.',
        'The first screen of the home page.',
      ],
    },
    who: {
      title: 'Who this is for',
      p: [
        'Cloud and AI services already in the catalog. People who get this far are often already paying you, or about to add you to the bill.',
        'Price is per vendor. We don’t invent traffic numbers.',
      ],
    },
    form: {
      title: 'Start the conversation',
      lede: 'Tell us the company name, which service, and how to reach you. Budget and timing can go in the note.',
      prefix: 'In the intro',
      company: 'Company',
      provider: 'Which service',
      providerHint: 'A name from the catalog. You can leave this blank.',
      message: 'Note',
      messageHint: 'Budget and when you want to appear can go here.',
      contact: 'Email',
      contactHint: 'We’ll reply to this address.',
      submit: 'Send',
      sending: 'Sending',
      sent: 'Received. We’ll reply on this contact.',
      rateLimited: 'That was a bit frequent. Try again in ten minutes.',
      failed: 'It did not send. Your text is still here — check the network and retry.',
    },
  },
  changelogPage: {
    title: 'Changelog',
    description: 'Every shipping version of TollCat is written down here.',
    lede: 'Every shipping version is written down here.',
    empty: 'Nothing published yet. Each release will land here.',
  },
};

const ja: Copy = {
  meta: {
    title: 'TollCat · クラウドの請求を、ポケットに',
    description:
      '自分で払っているクラウドと AI サービスの請求アプリ。今月いくら使ったか、開けば合計が見える。認証情報は端末の Keychain だけ。アカウントもバックエンドもない。',
    ogTitle: 'TollCat · クラウドの請求を、ポケットに',
    ogDescription: 'クラウドの請求を、ポケットに。認証情報はこの端末から出ない。',
  },
  a11y: {
    skip: '本文へ',
    nav: 'メイン',
    lang: '言語',
    langMenu: '言語を選ぶ',
    meter: '今月の合計の例 43.20 ドル、月末予測 51.51 ドル。iPhone シミュレータのデモデータ。',
    gallery: 'アプリの画面',
    providers: 'つなげるサービス',
    github: 'GitHub のソース',
    theme: '外観',
    themeMenu: '外観を選ぶ',
  },
  theme: {
    system: '自動',
    light: 'ライト',
    dark: 'ダーク',
  },
  nav: {
    setup: '接続',
    providers: '対応サービス',
    faq: 'よくある質問',
    support: '連絡',
  },
  langName: { zh: '中文', en: 'English', ja: '日本語' },
  langShort: { zh: '中', en: 'EN', ja: '日' },
  hero: {
    h1: ['一目でわかる、', '今月いくら使った。'],
    h1Alts: [
      ['思っているより、', '使っているかも。'],
      ['ロック画面をちらり。', '請求は全部そこに。'],
      ['クラウドにも、', '検針を。'],
    ],
    lede: '自分で払っているクラウドと AI サービスの請求アプリ。支出を足し合わせて、ひとつの合計に。認証情報はこの端末から出ない。',
    ctaSoon: 'App Store 近日公開',
    ctaStore: 'App Store で入手',
  },
  meter: {
    value: '$43.20',
    forecast: '月末予測 $51.51',
  },
  gallery: {
    dashboard: 'ダッシュボード',
    services: '接続済み',
    wizard: '接続手順',
  },
  setup: {
    title: ['各サービスを接続。', '手順どおりでいい。'],
    lede: '案内が読み取り専用の認証情報まで連れていく。どの権限を渡すのか、名前まで手順に書いてある。実際の金額が取れてから、この端末に残す。',
  },
  providers: {
    title: ['使っている SaaS、', 'だいたい繋がる。'],
    note: '公式の請求 API がない社は、自分のマシンで取った数値を投函できる。正はアプリ内の一覧。',
    listLink: '対応一覧',
  },
  credentials: {
    title: ['認証情報は、この端末だけ。', 'ここから出さない'],
    starLabel: 'この主張の説明を開く',
    lede: '認証情報はこの iPhone にだけ書きます。iCloud にも、TollCat のサーバーにも入りません。',
    link: 'それが指すもの',
    phoneLabel: '各サービスのアイコンが、この端末の錠に収まるデモ。',
    dialog: {
      title: 'それが指すもの',
      close: '閉じる',
      prev: '前へ',
      next: '次へ',
      page: '{current} / {total}',
      pageA11y: '{total} 件中 {current} 件目',
      slides: [
        {
          title: 'オープンソースと検証',
          paragraphs: [
            'ソースは GitHub にあり、MIT ライセンスです。自分でビルドして、自分の端末で動かせます。',
            'App Store のバイナリは Apple が再署名し、暗号化するので、このソースとバイト単位では一致しません。確かめられるのは、公開ビルドの来歴と、実行ファイルの UUID です。手順はリポジトリにあります。',
          ],
          to: 'github',
          link: 'github.com/KUD-00/tollcat',
        },
        {
          title: '端末のキーチェーン',
          paragraphs: [
            'Keychain は iPhone に入っている暗号化されたキー保管です。鍵はシステムが持ち、このアプリのファイルには書きません。',
            'いちばん厳しい区分を使います。この端末のロックを外したあとだけ読め、iCloud にもバックアップにも入りません。サービスを消すと、その鍵も消えます。',
          ],
        },
        {
          title: '通信の経路',
          paragraphs: [
            '更新のリクエストは、この端末から各社の公式 API へ直接出ます。間に TollCat のサーバーはなく、鍵も見えません。',
            'このアプリが接続するドメインは、設定 → 情報に並びます。同じ一覧がソースにあり、欠けているとビルドが落ちます。',
          ],
        },
        {
          title: '機種変更',
          paragraphs: [
            '鍵は意図して iCloud に入れないので、移行は自分で始める書き出しです。旧端末で暗号化した .tollcat を出し、新端末で画面の 10 桁コードを入力します。',
            '取り込み画面を離れるとコードは消えます。ファイルは 24 時間後に取り込めません。誤送信の窓を狭めるだけであり、暗号の強さそのものではありません。履歴はファイルに入らないので、取り込み後に一度更新してください。',
          ],
        },
        {
          title: 'サーバーが扱わないもの',
          paragraphs: [
            'サーバーはひとつです。扱うのはチップのメッセージ、フィードバック、公開カタログ、検針ポスト、匿名の画面カウントだけです。認証情報も請求も通りません。',
            'サーバーがあることは、請求を取りに行ってよいことではありません。',
          ],
          to: 'privacy',
          link: 'プライバシー',
        },
      ],
    },
  },
  platforms: {
    title: ['ほかのプラットフォーム'],
    ipad: 'iPad 版',
    mac: 'Mac 版',
    android: 'Android 版',
    windows: 'Windows 版',
    clusterLabel: '横向きの iPad と Mac のウィンドウ。',
    dialog: {
      close: '閉じる',
      prev: '前へ',
      next: '次へ',
      page: '{current} / {total}',
      pageA11y: '{total} 件中 {current} 件目',
      ipad: {
        title: 'iPad 版',
        lede: 'iPhone と同じアプリです。別に入れる必要はありません。',
        slides: [
          {
            title: '広い画面で、もっと見える',
            shot: 'dashboard',
            paragraphs: [],
          },
          {
            title: '縦にしても、そのまま',
            shot: 'portrait',
            paragraphs: [],
          },
        ],
      },
      mac: {
        title: 'Mac 版',
        lede: 'ネイティブの Mac アプリです。メニューバーに請求猫が一匹増えます。',
        download: {
          label: 'Mac 版をダウンロード',
          note: '展開したら TollCat を「アプリケーション」に入れてください。macOS 26 が必要です。',
        },
        slides: [
          {
            title: 'メニューバー',
            shot: 'menubar',
            paragraphs: [],
          },
          {
            title: 'ネイティブアプリ、Mac に合わせて',
            shot: 'window',
            paragraphs: [
              'SwiftUI で書いたネイティブの Mac アプリで、ウェブページを Electron で包んだものではありません。開けばすぐ出て、裏に置いてもメモリをあまり食いません。',
              '認証情報はこの Mac のキーチェーンだけに残ります。iPhone とも iPad とも共有しません。',
            ],
          },
        ],
      },
      android: {
        title: 'Android 版',
        lede: 'まだ開発中です。お楽しみに！',
        slides: [
          {
            title: 'まだ途中',
            paragraphs: ['リポジトリに初期の Android 版があります。'],
            to: 'github',
            link: 'GitHub',
          },
        ],
      },
      windows: {
        title: 'Windows 版',
        lede: 'まだ開発中です。お楽しみに！',
        slides: [
          {
            title: 'まだ途中',
            paragraphs: ['リポジトリに初期の Windows 版があります。'],
            to: 'github',
            link: 'GitHub',
          },
        ],
      },
    },
  },
  facts: {
    title: '何をするか',
    lede: '自分で払っているクラウドと AI サービスの請求アプリ。各社バックエンドの今月の支出を足し合わせて、ひとつの合計に。その下に各社の内訳が並ぶ。合計はロック画面やホーム画面のウィジェット、Mac のメニューバーにも置ける。',
    items: [
      '認証情報は端末の Keychain だけ。iCloud にも TollCat のサーバーにも入らない。',
      '読み取り専用。インスタンスを止めず、クォータを変えず、遠隔プッシュもしない。',
      'アカウントはない。任意のサーバーが扱うのは、チップに添えるメッセージ、フィードバック、公開カタログ、検針ポストだけ。どれもプロバイダの鍵には触れない。',
      '無料。任意のチップ。会員制なし。MIT ライセンス。iPhone、iPad、Mac。iOS 26 または macOS 26。台帳は米ドル。',
    ],
    not: 'FinOps スイートでも、異常課金の警報でも、クラウドコンソールでもない。本ページの画面はシミュレータのデモ数字であり、本番データではない。',
  },
  faq: {
    title: 'よくある質問',
    items: [
      {
        q: 'API キーはこの端末から出ますか？',
        a: '出ません。端末の Keychain に WhenUnlockedThisDeviceOnly で書きます。iCloud にもシステムバックアップにも入りません。取得リクエストはこの端末から各社の公式 API へ出ます。プロバイダの認証情報を扱うサーバーはありません。',
      },
      {
        q: '使っているサービスがない？',
        a: '一覧は対応一覧にあります。公式の請求 API がないサービスは、自分のマシンで取った数値を検針ポストに投函できます。追加したいサービスは連絡ページから。',
        href: localePath('ja', 'providers'),
        link: '対応一覧',
      },
      {
        q: '機種変更のときは？',
        a: '認証情報はあえて iCloud に入れていないので、移行はエクスポートで行います。旧端末で暗号化した .tollcat を書き出し、新端末で画面の 10 桁コードを入力して取り込みます。コードは取り込み画面を離れると消え、ファイルも 24 時間で無効になります。履歴はファイルに入らないので、取り込み後に一度更新してください。',
      },
      {
        q: '有料ですか？',
        a: '完全無料です。',
      },
      {
        q: 'FinOps ですか？クラウド資源を変えますか？',
        a: '違います。TollCat は支出を報告するだけです。インスタンスを止めず、クォータを変えず、遠隔プッシュもせず、クラウドのモデルで請求を計算しません。端末内のリマインダーは任意で、通知に金額は出しません。',
      },
      {
        q: '対応端末は？通貨は？',
        a: 'iPhone、iPad、Mac。iOS 26 または macOS 26 が必要です。台帳は米ドルです。表示通貨は金額の書き方だけを変え、リアルタイム為替は取りに行きません。',
      },
      {
        q: 'ソースはどこ？',
        a: 'すべて GitHub にあります。MIT ライセンスです。自分でビルドすることも、App Store のバイナリがこのソースから作られたことを確かめることもできます。手順はリポジトリに。',
        href: siteConfig.githubUrl,
        link: 'github.com/KUD-00/tollcat',
      },
      {
        q: 'Android は？',
        a: 'まだ開発中です。お楽しみに！猫の手も借りたいので、待ちきれない方は GitHub へどうぞ。',
        href: siteConfig.githubUrl,
        link: 'GitHub',
      },
    ],
  },
  footer: {
    blurb: 'クラウドの請求を、ポケットに。',
    privacy: 'プライバシー',
    changelog: '更新履歴',
    support: '連絡',
    providers: '対応一覧',
    sponsors: '紹介に出す',
    copyright: '© 2026 TollCat. MIT License.',
  },
  supportListPage: {
    title: '対応一覧',
    description:
      'TollCat が検証済みで完全対応するサービス、理論上は完全対応するもの、検針ポストだけのもの、非対応のもの。正はアプリ内の一覧。',
    close: '閉じる',
    back: '戻る',
    search: 'サービスを探す',
    empty: 'その名前はありません。',
    footnote: '一覧はアプリと同じです。つなぎたい社は連絡ページから。',
    footnoteLink: '連絡する',
    sections: {
      tested: {
        title: '検証済みの完全対応',
        lede: '読み取り専用の認証情報を入れると、請求が入ります。実アカウントで突き合わせ済みです。',
      },
      theoretical: {
        title: '理論上は完全対応',
        lede: '公開の請求 API があり、アプリからも繋がります。実請求との突き合わせがまだです。',
      },
      inbox: {
        title: '検針ポストのみ',
        lede: '公式に突き合わせできる請求金額 API がありません。自分のマシンで取った数値を検針ポストに投函します。固定サブスクは手入力もできます。',
      },
      unsupported: {
        title: '非対応',
        lede: '確認のうえ見送り。突き合わせできる公開の請求金額 API がありません。名前はカタログに残し、再確認しません。',
      },
    },
    market: {
      1: {
        label: '首位',
        lede: 'その分野の首位か、数社で分け合う側。',
      },
      2: {
        label: '挑戦者',
        lede: '実際に選ばれる代替。',
      },
      3: {
        label: '新興',
        lede: 'まだ小さいが、伸びている。',
      },
      4: {
        label: '縮小中',
        lede: 'まだ小さく、縮小している。',
      },
    },
    detail: {
      open: '詳細を見る',
      kinds: {
        usage: '従量',
        prepaid: '前払い',
        subscription: '固定サブスク',
        freeTier: '無料枠',
        planAndUsage: 'プランと従量',
      },
      status: {
        tested: '検証済み',
        theoretical: '理論対応',
        inbox: '検針ポスト',
        unsupported: '非対応',
      },
      chipDaily: '日次あり',
      chipHistory: '{n} か月の履歴',
      chipRefresh: '更新に費用がかかる',
      credentials: '入れるもの',
      secret: 'シークレット',
      steps: '取り方',
      plans: 'プラン',
      perMonth: '/ 月',
      perYear: '/ 年',
      billing: '公式の請求へ',
      setup: '認証情報を作る',
      docs: '関連ドキュメント',
      actions: '公式ページ',
      troubleshooting: 'うまくいかないとき',
    },
  },
  privacyPage: {
    title: 'プライバシーポリシー',
    description: 'TollCat にアカウントはありません。認証情報は端末から出ません。本ページはアプリと本サイトが実際に扱うデータです。',
    updated: '最終更新：2026 年 9 月 5 日',
    sections: [
      {
        h: '認証情報と請求',
        p: [
          '入力した API キー、トークン、アカウント識別子はこの端末だけに残ります。保管はそれぞれの OS の仕組みです。',
          {
            list: [
              {
                term: 'iOS / iPadOS',
                text: 'iOS Keychain に WhenUnlockedThisDeviceOnly で保存します。iCloud Keychain にもシステムバックアップにも入りません。',
              },
              { term: 'macOS', text: 'この Mac の Keychain に同じ強度で保存し、iPhone とも iPad とも共有しません。' },
              {
                term: 'Android',
                text: 'リポジトリにある開発中の版は Android Keystore で暗号化して端末に置き、クラウドバックアップに入れません。まだ出していません。',
              },
              {
                term: 'Windows',
                text: 'リポジトリにある開発中の版は Windows の Credential Manager に置き、その PC でしか読めません。まだ出していません。',
              },
            ],
          },
          '取得リクエストはこの端末から各社公式 API へ直接出ます。TollCat のサーバーは代理せず、認証情報も見ません。',
          '履歴、サブスク、設定は端末上にあります。iOS では App Group にあり、アプリとウィジェットが共有します。ウィジェット単独では取得できません。',
        ],
      },
      {
        h: '本サイトと任意のサーバー',
        p: [
          'tollcat.app は静的サイトです。アカウント、cookie、解析スクリプトはありません。Cloudflare へ載せたあとは、配信と防御のために接続メタデータ（IP、User-Agent、時刻）がエッジを通ります。識別には使いません。',
          'api.tollcat.app が唯一のサーバーで、本サイトとは別です。扱うのは、チップに添えるメッセージ、アプリ内フィードバック、公開セットアップカタログ（文言、料金、為替。URL も認証情報もなし）、公式請求 API がないサービス向けの検針ポスト、そして匿名の画面カウントです。いずれもプロバイダ認証情報は扱いません。',
          'ポストのキーは SHA-256 だけを保存します。各ポストはサービスごとに最新一件だけ残します。流出しても、人に紐づかない匿名の数字であり、課金できる鍵ではありません。',
        ],
      },
      {
        h: '機種変更',
        p: [
          '認証情報は意図して iCloud に入れません。機種変更では、暗号化した .tollcat を書き出し、画面の 10 桁コードで取り込みます。取り込み画面を離れるとコードは消えます。ファイルは 24 時間後に取り込めません。これは誤送信の窓を狭めるだけであり、暗号の強度そのものではありません。履歴はファイルに入りません。取り込み後に更新してください。',
        ],
      },
      {
        h: '端末内のリマインダー',
        p: [
          '決めた時刻に、数字を見に来るよう端末へ知らせられます。通知に金額は出しません。しきい値アラートも、遠隔プッシュもありません。',
        ],
      },
      {
        h: 'フィードバックとチップ',
        p: [
          'アプリ内フィードバックは匿名にできます。連絡先を残した場合、その一件の返信にだけ使います。一緒に送る環境情報は、送信前に同じ画面で項目ごとに見られます。',
          'チップは Apple のアプリ内課金です。支払いは Apple の方針に従います。こちらが見るのは完了した購入と、任意で添えられたメッセージだけです。カード番号は見えません。',
        ],
      },
      {
        h: '匿名の画面カウント',
        p: [
          'アプリは、開いた画面を api.tollcat.app に送り、日ごとの起動回数と画面ごとの入場回数を見ます。送るのはプラットフォーム（iOS、Android、macOS、または Windows）、アプリの版、許可リスト上の画面名、そして「この UTC 日の初回か」だけです。',
          'この数字にはもうひとつ用途があります。TollCat はいずれ、運営費のために邪魔にならない広告を少し置くかもしれません。置くかどうか、どの画面に置くかを考えるには、実際に読まれている画面を知る必要があります。実施する場合は、先に本ページへ書きます。',
          'アカウント、広告識別子、端末指紋、安定した匿名 ID はありません。同じ画面に居続ける場合は 1 回だけ数えます。サーバーは合計を足すだけで、イベントの流水は残さず、IP で人を認識しません。画面名に、どのサービスを繋いだかは入りません。',
        ],
      },
      {
        h: '収集しないもの',
        p: [
          '広告識別子、クロスサイト追跡、請求の売却はありません。Privacy Nutrition Label の項目は機能に必要なもの（チップの購入記録、匿名の操作カウントなど）に限り、トラッキングはオフです。',
        ],
      },
      {
        h: '子ども',
        p: ['TollCat は 13 歳未満向けではありません。アカウントがないため、年齢も分かりません。'],
      },
      {
        h: '変更',
        p: [
          '実質的な変更があれば、本ページの日付を更新します。アプリを使い続ける場合、見ているのはこの版です。',
          '本方針について：アプリ → 設定 → フィードバック、または本サイトの連絡ページ。どちらも api.tollcat.app へ届き、認証情報は付きません。',
        ],
      },
    ],
  },
  supportPage: {
    title: '連絡',
    description: 'アプリ内フィードバックと同じ道です。api.tollcat.app へ届き、認証情報は付きません。',
    lede: 'アプリの「設定 → フィードバック」と同じ道です。どちらも api.tollcat.app へ届き、認証情報は付きません。アカウントはないので、返信が必要なら連絡先を残してください。',
    form: {
      category: '種類',
      categories: [
        { value: 'bug', label: '不具合' },
        { value: 'idea', label: 'ほしいもの' },
        { value: 'provider', label: 'つなぎたいサービス' },
        { value: 'other', label: 'その他' },
      ],
      message: 'なんでも書いてください',
      contact: 'メールなどの連絡先',
      contactHint: '空でも構いません',
      submit: '送信',
      sending: '送信中',
      sent: '受け取りました。ありがとうございます。',
      rateLimited: '少し間隔が短いです。十分後にどうぞ。',
      failed: '送れませんでした。文面は残っています。通信を確認してもう一度。',
    },
  },
  sponsorsPage: {
    title: '紹介に出す',
    description:
      '払っている人がその支払いを見る場所に出ます。ユーザーも売りませんし、対応一覧の並べ方も売りません。',
    lede: 'TollCat を開くのは、今月クラウドと AI の各サービスにいくら払ったかを見るためです。自分のサービスの紹介に出たい場合は、このページで話します。',
    offer: {
      title: '売っているもの',
      p: [
        '売っているのは、そのサービスの紹介の下にある枠です。一文、短い説明、ボタンひとつ。文面は御社が書きます。',
        '御社が書いたと分かるようにします。買っていないページは、つながるかと、必要な認証情報だけです。',
      ],
    },
    refuse: {
      title: '売らないもの',
      items: [
        'アプリ内の広告、バナー、おすすめカード。',
        '対応一覧の順位と状態。',
        '接続ウィザードの手順、権限名、飛び先 URL。',
        'ユーザー、請求、広告識別子、トラッキングピクセル。',
        'ホームの最初の画面。',
      ],
    },
    who: {
      title: '向いている相手',
      p: [
        'カタログにあるクラウドと AI のサービス向けです。ここに来る人は、すでに支払っているか、これから追加しようとしていることが多いです。',
        '価格はサービスごとに決めます。作りものの閲覧数は出しません。',
      ],
    },
    form: {
      title: '話を始める',
      lede: '会社名、出たいサービス、連絡先を書いてください。予算や時期はメモにどうぞ。',
      prefix: '紹介に出す',
      company: '会社',
      provider: '出たいサービス',
      providerHint: 'カタログ上の名前です。空でも構いません。',
      message: 'メモ',
      messageHint: '予算や、いつ出したいかはここに書いてください。',
      contact: 'メール',
      contactHint: 'この件の返信に使います。',
      submit: '送る',
      sending: '送信中',
      sent: '受け取りました。この連絡先に返信します。',
      rateLimited: '少し間隔が短いです。十分後にどうぞ。',
      failed: '送れませんでした。文面は残っています。通信を確認してもう一度。',
    },
  },
  changelogPage: {
    title: '更新履歴',
    description: 'TollCat が公開した各版は、ここに残します。',
    lede: '公開した版は、ここに残します。',
    empty: 'まだ公開した版はありません。出したら、ここに残します。',
  },
};

const all: Record<Locale, Copy> = { zh, en, ja };

export function t(locale: Locale): Copy {
  return all[locale];
}
