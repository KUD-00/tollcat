# 回复稿：Guideline 5 - Legal（中国区 深度合成/生成式 AI）

Submission ID: 205f3dd4-1aa3-41eb-b4c9-0e587e158ae7 · 2026-09-09

`---` 以下是要发的正文，贴进 App Store Connect 的 Resolution Center。

## 发之前必须做的

### 1. en-US 和 ja 的元数据也要贴进 ASC

**审核点名的小写 `openai` 精确命中的是 en-US 的 keywords 那一栏**
（`…,api,widget,openai,anthropic,cloudflare,…`）。zh-Hans 的 keywords 里从来没有
这个词，只有「人工智能」。所以只清简体中文等于**没碰被扫到的那一栏**。

而 ASC 的 Primary Language 是 **en-US**（已确认），中国大陆能显示的语言是简中 +
English (U.K.)，我们没配 en-GB——英文设备的中国用户回落到 primary，看到的就是
en-US 那份。

`metadata/` 里三语的干净文案都备好了，三份都要贴：

| 本地化 | 要改的 |
|---|---|
| en-US | `keywords.txt`（去掉 `openai,anthropic`，补 `subscription,tracker`）、`description.txt` 两处举例 |
| ja | `description.txt` 两处举例 |
| zh-Hans | `description.txt` 两处举例（你已经改过） |

**正文第 1 段声称的是三语全部字段。三份没都贴之前不要发**——审核员点开 en-US 的
keywords 就能看到没改，那是向审核提供不实信息，比不回信严重。

真要在美区保住 OpenAI 这个词，正规做法是补一份干净的 **en-GB**（中国区支持的
英文就是它，补了之后英文设备的中国用户不再回落到 en-US），截图用现成的
`-demo-fixtures=cn` 跑一趟。代价是英国 / 澳洲 / 新西兰 / 爱尔兰 / 印度等地跟着
失去这个词，而且 en-US 的 keywords 仍建议清掉——扫描大概率不分区。

### 2. 正文里不放 GitHub 链接

仓库还是私有的（`gh repo view` 确认 PRIVATE），链接过去只会是 404。给一封讲
「我们只读账单接口」的信附一个打不开的证据链接，比不给链接糟得多。

同一个问题原来还在两处，**都已经改掉了**：`metadata/review-notes.md` 不再给链接，
改成「仓库暂为私有，需要哪部分源码可在此贴出」；三语 description 的最后一节从
「免费，开源」改成「免费」，不再声称源码在 GitHub 上（那句对普通用户也不成立，
属 Guideline 2.3 accurate metadata）。

转 public 之后想把这些话加回去，记得三语 description、review-notes、以及正文里
这一段一起改。

### 2.5 如果最后还是决定只改 zh-Hans

那第 1 段必须换成下面这版，别用正文那版——它声称的是三语。**这条路不推荐**：
它没有回应审核点名的那个字段，大概率原地再驳一次。

> The reference you found is in our English keywords and app description. We have
> removed every mention of OpenAI, ChatGPT, Anthropic and Claude from the
> Simplified Chinese metadata and re-taken the Simplified Chinese screenshots, so
> that nothing of the kind appears in the localization served on the China
> mainland storefront. Please let us know if you would like us to remove these
> references from the English and Japanese localizations as well, and we will do so.

### 3. 截图只有 zh-Hans 换了演示数据

en-US / ja 的截图仍然带 OpenAI 和 ChatGPT Plus（有意保留，见 `README.md` 的
`-demo-fixtures=cn` 一节）。所以正文那句只声称简中截图，**别改成无条件的
"and screenshots"**。

---

Hello,

Thank you for the review.

The references you found were in our keywords and app description. We have removed every mention of OpenAI, ChatGPT, Anthropic and Claude from all metadata fields in all three localizations (English, Japanese, Simplified Chinese), and we have re-taken the Simplified Chinese screenshots so that no such name appears in them either. The Review Notes have been updated accordingly.

We would also like to explain what the app actually does, because we do not believe it provides a deep synthesis or generative AI service within the meaning of the Administrative Provisions on Deep Synthesis of Internet-based Information Services.

TollCat is a spending tracker for cloud infrastructure bills. The user pastes a read-only API key for a service they already pay for, and the app displays how much that account has been charged this month. Specifically:

- The app never calls a model inference, chat, completion, image, audio, or embedding endpoint of any vendor. For each vendor it calls only that vendor's billing or usage endpoint. For OpenAI, the single endpoint the app calls is `GET https://api.openai.com/v1/organization/costs`, which returns amounts of money for the user's own organization.
- Nothing is generated, synthesized, or produced by a model at any point. The only thing shown to the user is their own billing figures. The app has no chat interface, no prompt input, and no model output of any kind.
- No user content of any kind is sent to an AI vendor. Such a request carries only the user's own API key, for authentication, and the date range being queried.
- API keys are stored in the device Keychain, and billing requests go from the device straight to the vendor's official API. No server of ours ever sees a provider credential or a billing request. (As described in the Review Notes, we do operate api.tollcat.app for the public setup catalog, optional feedback and tips, and an opt-in email-forwarding inbox for services that publish no billing API. Provider credentials are never sent to it.)

In this app, OpenAI is one billing source among many, alongside AWS, Cloudflare, Vercel, Stripe, GitHub, and Twilio. It is present for the same reason AWS is present: it sends the user an invoice. Reading the amount of an invoice is not, as we understand the regulation, a deep synthesis service, and it does not require an MIIT filing.

We have therefore made the metadata changes you asked for. If App Review nonetheless considers the ability to display an OpenAI invoice amount to be ChatGPT functionality that must be deactivated on the China mainland storefront, please let us know and we will gate it behind a storefront check in the next build. We are also happy to provide the source of our OpenAI billing client, or a walkthrough of it, if that would help confirm the above.

Thank you for your time.
