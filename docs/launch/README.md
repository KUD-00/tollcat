# 发布宣传材料

这里是各宣传渠道的文案事实源：发之前改这里，发完把状态表勾掉。
商店页文案在 `../appstore/`，这里只管商店以外的渠道。

所有稿子过 `BRAND.md` 验收：正文四测试、禁营销词、隐私主张字面为真、
不承诺 roadmap（现状可以说，「即将」不行）。带截图的帖子一律用
`../appstore/marketing/` 的宣传图或带手机框的完整截图，金额不当排版元素，
「演示数据」小注不能丢。

## 发布顺序

大渠道的机会各只有一次，别带着首发 bug 去。

1. **软启动（上架后第 1–2 周）**：V2EX、即刻、X 上小声发。目的是收集崩溃
   和真实反馈，顺便攒几条真用户评价。
2. **主发布（确认稳定后，挑一周）**：Show HN 和 Product Hunt 错开 2–3 天，
   HN 在前（PH 的流量会往 HN 帖子里灌人，反过来不会）。同周发 Zenn 开发记。
3. **长尾（主发布后随时）**：newsletter 投稿、App Store featuring 申请、
   持续在 X 晒自己的分享卡片。

## 渠道与稿子

| 渠道 | 稿子 | 语言 | 状态 |
| --- | --- | --- | --- |
| Hacker News (Show HN) | [show-hn.md](show-hn.md) | 英 | 草稿 |
| Product Hunt | [product-hunt.md](product-hunt.md) | 英 | 草稿 |
| X / Twitter | [x-posts.md](x-posts.md) | 中英同号 | 帖子库（约 35 条，含排期） |
| Zenn 开发记 | [zenn-article.md](zenn-article.md) | 日 | 草稿（战斗故事待填） |
| V2EX 分享创造 | [v2ex-post.md](v2ex-post.md) | 中 | 草稿 |
| Newsletter 投稿 | [newsletter-pitches.md](newsletter-pitches.md) | 英 | 草稿 |

## 各渠道的操作备忘

- **X / Twitter**：不是「发一条发布帖」，是一条排期上的帖子流，见 [x-posts.md](x-posts.md)。
  一个账号中英混发，同一件事的两种语言隔开至少一天，发布日除外。一天最多两条，
  发完守回复区两小时——X 上回复比发帖本身值钱。日常帖的链接放第一条回复，
  发布帖和里程碑帖的链接放正文。
- **Show HN**：工作日美西早上 8–10 点发。标题用 `Show HN: 名字 – 一句话`，
  连字符是 `–` 不是 `-`。发完守在评论区一整天，答疑的质量决定帖子走多远；
  预答见稿子第二节。不要自己顶帖、不要拉票，HN 反感这个且有检测。
- **Product Hunt**：太平洋时间 00:01 上线才有完整 24 小时。提前把 gallery
  图传好（顺序：dashboard → detail → services → wizard，与商店叙事一致），
  maker comment 在上线后第一时间贴。
- **Zenn**：文末带 App Store 链接和仓库链接即可，别写成广告——文章本体
  必须是有干货的开发记，产品是顺带的。
- **Newsletter**：一封一封发，别群发抄送。Console.dev 走它的提交表单，
  iOS Dev Weekly 直接邮件给 Dave Verwer，TLDR 有 submit 页。
- **App Store featuring**：App Store Connect 里的「Promote Your App」表单，
  卖点写三语本地化、锁屏/桌面小组件、开源可验证。上架后就能填，常态化重复申请。
