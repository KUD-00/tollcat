# Show HN 帖子

标题（HN 会截 80 字符，连字符用 `–`）：

> Show HN: TollCat – One number for what your cloud services cost this month

备选：

> Show HN: TollCat – iOS app that reads 80+ cloud billing APIs, keys stay on-device

## 正文

I pay for more cloud and AI services than I can comfortably keep track of — Cloudflare, OpenAI, a couple of database hosts, a few things I signed up for at 2am. Each one has its own dashboard and its own bill, so "what did this month actually cost" meant logging into all of them. I built TollCat to make that a glance: an iOS app that asks each vendor's official billing API what I've spent so far this month and adds it up into one number. There's a Lock Screen widget, so most days I don't open the app at all.

The design constraint I cared most about: credentials never leave the phone. API keys live only in the device Keychain — not iCloud, not backups — and the phone talks directly to each vendor's API, with no server of mine in between. The project does run one small worker (tips, in-app feedback, a public catalog of setup guides, and an email inbox for services that have no billing API), but none of those paths can touch a provider credential, and the module graph enforces it: the widget doesn't link the networking module at all, and the billing module and the tips module can't link each other.

Most of the work turned out to be reading 80+ billing APIs, each with its own idea of what "a month" is: some bill on calendar months, some on rolling windows anchored to your signup date, some only tell you yesterday's usage, and a few have no billing API at all — for those there's a "reading inbox" where you forward the invoice email and the number comes in anyway.

It's free on the App Store (iOS 26+, iPhone and iPad; there's a native Mac shell in the repo that hasn't gone through App Store submission yet), MIT licensed, full source on GitHub. Since the whole pitch is "trust this app with your API keys", the repo also documents how to verify what you install: Apple re-signs and encrypts App Store binaries so byte-for-byte reproduction is impossible, but public CI builds the IPA from a tag with signed provenance, and the Mach-O UUID ties that build to the app on your phone. The honest limits of that are written down too.

App Store: <APP_STORE_URL>
Site: https://tollcat.app
Source: https://github.com/KUD-00/tollcat

## 评论区预答

发帖当天守在评论区。下面是必然会被问的问题，答案先行，别护短。

**"Why should I trust an app with my API keys?"**
You shouldn't have to trust me — that's why the keys stay in the device Keychain, the phone talks to vendors directly, and the source is on GitHub so you can check both claims. If that's still not enough, every setup guide walks you through creating a *read-only* key scoped to billing, so the blast radius of a leak is "someone can see my bill", not "someone can delete my database". And you can build from source yourself.

**"iOS 26 only? That's aggressive."**
Yes. It's a one-person-scale project and supporting old OS versions is exactly the kind of cost I can't pay yet. The floor will move down the priority list, not up.

**"Android?"**
Not done yet. There's an Android version in the repo under active development — credentials live in the on-device Keystore the same way — but there's nothing you can install today.

**"How is this different from a FinOps tool / CloudZero / Vantage?"**
It isn't a FinOps suite and doesn't want to be. Those are for teams allocating cloud spend across an org. TollCat is for one developer who wants to know what this month costs, on their phone, without giving a third party their keys.

**"What's the business model?"**
There isn't one. It's free, MIT, and I use it every day for my own bills. There's a tip jar in Settings. If tips buy the cat a tin, great.

**"The App Store build can't be verified byte-for-byte, so the open source claim is weak."**
Correct, and VERIFY.md says exactly that. Apple re-signs and encrypts every binary, so the strongest available guarantee is: CI builds from a public tag, attaches signed provenance, and the Mach-O UUID on your phone matches that build. If your threat model doesn't accept Apple in the loop, build from source.

**"Provider X isn't supported."**
The supported list is at https://tollcat.app/providers/. If yours is missing, open an issue — adding a provider is mostly writing one adapter against their billing endpoint, and PRs are welcome.
