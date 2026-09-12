# Newsletter 投稿

一封一封发，按对方的口味微调，别群发。目标（按命中率排）：

| 去处 | 入口 | 口味 |
| --- | --- | --- |
| Console.dev | https://console.dev（提交表单） | 开发者工具，重视隐私架构和开源 |
| iOS Dev Weekly | 邮件 Dave Verwer(dave@iosdevweekly.com) | iOS 圈，重视 SwiftUI/widget 的工程点 |
| TLDR | https://tldr.tech（submit 页） | 一句话要够硬 |
| Indie Dev Monday | https://indiedevmonday.com | 独立开发者故事 |

## 通用短 pitch（Console.dev / TLDR 用）

> **TollCat** — a free, MIT-licensed iOS app that reads your billing APIs across 80+ cloud and AI services (Cloudflare, OpenAI, Anthropic, Vercel, …) and puts this month's total in one number, on a widget. API keys stay in the device Keychain and the phone talks directly to each vendor's API — no server in between, so nobody can see your bills, including the developer. https://tollcat.app

## iOS Dev Weekly 邮件

Subject: TollCat — cloud bills in one number, keys never leave the Keychain

Hi Dave,

I just shipped TollCat, a free and MIT-licensed iOS app for people paying for too many cloud services: it reads each vendor's official billing API and puts this month's total in one number, with Lock Screen and Home Screen widgets.

Two things that might interest your readers beyond the app itself:

1. Credential isolation is enforced by the module graph, not by discipline — the widget target doesn't link the networking module at all, so it can't make requests of its own, and the billing and tips modules can't link each other.
2. Since the pitch is "paste in your API keys", the repo documents how far build verification can actually go on the App Store (CI provenance from a public tag, matched by Mach-O UUID) and where it honestly stops.

Site: https://tollcat.app · Source: https://github.com/KUD-00/tollcat · App Store: <APP_STORE_URL>

No worries at all if it's not a fit. Thanks for the newsletter — long-time reader.

<签名>

## 备忘

- 发之前把 `<APP_STORE_URL>` 和签名换掉。
- 命中后别催第二次；没命中隔一个大版本可以再试一次，带上新东西。
