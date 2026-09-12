# 第三方素材与商标

本项目不引入任何第三方代码依赖。以下是素材与商标方面需要说明的部分。

Windows 壳用 Windows App SDK / WinUI 3（微软平台 SDK，经 NuGet 引用 `Microsoft.WindowsAppSDK` 2.4.0）。
这不是第三方库，对应主仓「Sparkle 是唯一例外」在 Windows 上的平台等价物。
CommunityToolkit 未引入。账本用 JSON 文件而不是 SQLite，避免再多一个 native 包。

## 图标形状：Simple Icons（CC0 1.0）

各家服务的单色 glyph 取自 [Simple Icons](https://simpleicons.org)，
以 [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
释出（等同公共领域，不要求署名——这里写明是出于礼节）。

路径数据内联在 `Packages/MeterKit/Sources/MeterDesign/ProviderGlyphArtwork.swift`。

Exa 的 logomark 取自 [官方品牌包](https://exa.ai/brand)，缩放到 24×24 单色 path。
Polar 的 logomark 取自官方文档图标，转成同一套 24×24 even-odd path。
Simple Icons 目录里没有的家，若官网提供了 SVG logomark / favicon，同样只做等比缩放居中到 24×24，不临摹、不描图。都不是手绘仿制。
拿不到可用矢量、或商标条款不许改 path 的，界面用品牌色方块里的首字母。

## 字体（Android 端内置）

- **Material Symbols Rounded**（可变字体，Google，[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)）：
  按 App 用到的图标裁剪后打包在 `Android/app/src/main/res/font/material_symbols_rounded.ttf`，
  保留 FILL / wght / GRAD / opsz 四轴。来源：[google/material-design-icons](https://github.com/google/material-design-icons)。
- **Roboto Flex**（可变字体，Google Fonts，[SIL Open Font License 1.1](https://openfontlicense.org)）：
  裁剪为数字与基本拉丁字符集，保留 wght / opsz / GRAD 三轴，打包在
  `Android/app/src/main/res/font/roboto_flex.ttf`，用于 hero 金额排版。
  来源：[googlefonts/roboto-flex](https://github.com/googlefonts/roboto-flex)。

## 商标

**CC0 只覆盖 SVG 路径数据，不覆盖商标本身。**

Amazon Web Services、Cloudflare、OpenAI、Anthropic、Vercel、GitHub、Neon、
Fly.io、OpenRouter、DeepSeek、Moonshot / 月之暗面 / Kimi、xAI、Cursor、DigitalOcean、Twilio、
PlanetScale、Upstash、ElevenLabs、Railway、Stripe、Resend、PostHog、Clerk、Sentry、
Heroku、Exa、Polar
及其各自的名称与标志，是各自所有者的商标。
Heroku 用 Simple Icons 15.22.0 的官方 path（之后因 Salesforce 商标政策从目录移除）。
xAI、Azure 条款禁止改色改 path，界面用品牌色方块里的首字母，不手绘仿制 logo。

本项目对它们的使用属于**指示性使用**（nominative use）——用于指明本 App 能读取
哪家服务的账单，不表示这些公司对本项目的赞助、背书或关联。

如果任何商标所有者认为此处的使用方式不当，
请提 issue，会尽快调整或改回字母回落。

## 本项目自身

代码以 MIT 许可（见 `LICENSE`）。**MIT 不及于各家服务的名称与标志**：Simple Icons 的 path 仍是 CC0；官网 SVG 缩放过的 logomark 仍归各商标所有者。仓库公开这些 path，是为了让人能核对该显示的是谁，不是把商标重新授权成 MIT。

App 图标是本项目原创，不属于上述任何一方。
