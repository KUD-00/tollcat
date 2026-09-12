# 发布手册

一个人维护五个端加一个 API 和一个落地页。节奏由**事件**触发，不由日历触发：有东西才发，没东西就什么都不用做。
决策的来龙去脉见发布节奏方案（Claude artifact「TollCat 发布节奏」）；这里只放要照着做的东西。

## 决定（不再议）

| 问题 | 决定 |
|---|---|
| staging 分支 | 不要。只有 `main`。预发由各端通道提供：TestFlight、Sparkle beta、Play 内测轨道、appinstaller beta 源 |
| main 保护 | required status checks（ci.yml 全部 job）+ 线性历史 + 禁强推。不设 required reviewers，PR 可选 |
| 发布单位 | 一个 tag `vX.Y.Z`，打在 `main` 上。release.yml 从 tag 构建**勾了的端**，产出 **draft** Release |
| iOS 与 Mac | **不是同一班车。** 通道、审核、风险都不同；同一个 tag 上各自决定跟不跟。Sparkle 清单挂在滚动 Release `mac-appcast` 上，不挂 latest |
| 人工关卡 | 只有一个：Environment 的 required reviewers。跑到要上传 App Store Connect 那步停下来等你点 |
| iOS / Mac | 各自：有它关心的路径改过就算有可发内容；值得写更新日志就发；做好的东西不能躺超过 30 天 |
| Android / Windows | 落后两班车（v* 比它多两个），或共用核心（MeterCore / MeterProviders / MeterFormat / Catalog / shared）改过，就搭当次 tag |
| 热修复 | main 上修，升补丁号，打 tag。只在 main 堆着不能发的东西时才切 `release/X.Y`，修完合回删掉 |
| API / 落地页 | 合进 main 就部署，不跟 App 的 tag。API 只加不改，先于 App 到位 |
| 版本号 | `shared/version.json` 唯一权威，生成器铺到六处。build 号由 CI run number 填 |

## 仓库里有什么

| 文件 | 干什么 | 触发 | secret |
|---|---|---|---|
| `.github/workflows/ci.yml` | 六道静态闸、iOS 单测、Worker typecheck、Windows 单测、站点构建、Maestro UI 冒烟 | push main / PR（私有期：手动） | 无 |
| `.github/workflows/beta.yml` | 从 main 头部归档上传 TestFlight，build 号 = run number | push main（私有期：手动） | `app-store` environment |
| `.github/workflows/release.yml` | tag → 勾了的端：iOS 上 ASC、Mac 公证 + Sparkle、Android AAB、Windows 占位 → draft Release + 溯源证明；跟车的端打 `ios-v*` `mac-v*` `android-v*` 记账。ios / mac / windows 挂 Environment，审批在这里停 | tag `v*`（默认 iOS + Mac；私有期：在 tag 上手动 dispatch 勾端） | `app-store` `mac-direct` `windows` `google-play` |
| `.github/workflows/mac-appcast.yml` | Release 被 Publish 时，把它的 appcast.xml 和 zip 副本覆盖到滚动 Release `mac-appcast`。没有 Mac 资产的 Release（iOS-only）不动清单 | release published（私有期：手动填 tag） | 无 |
| `.github/workflows/deploy-edge.yml` | D1 迁移 → 部署 toll-api；构建 → 部署 tollcat.app | push main 且 worker/ site/ 契约 目录有改动（私有期：手动） | `api` environment |
| `.github/workflows/release-status.yml` | 跑 `release-status.sh`，有该发的端就开 issue，没有就关 | 每周一（私有期：手动） | 无 |
| `scripts/release-status.sh` | 该不该发、发哪些端，一分钟读数。另打一行「未点头」（`scripts/follow-up.json`），不改变原来的 `due` | 想发版时跑 | — |
| `scripts/check-follow-up.py` / `docs/FOLLOW-UP.md` | Android / Windows / CLI 按 Apple 目录点头。过期不挡提交 | 跟进某一摊时 | — |
| `shared/version.json` | 版本号权威 | `generate-shared.py` 铺 | — |
| `shared/changelog.json` | 更新说明权威。铺到 App 抽屉、落地页 `/changelog`、Sparkle 更新弹窗、ASC 与 Play 的「此版本新增」、Release body | `generate-shared.py` 铺 | — |

哪个端跟了哪班车，由 release.yml 的 publish 打 `ios-vX.Y.Z` / `mac-vX.Y.Z` / `android-vX.Y.Z` 记账，`release-status.sh` 靠它们各自算。iOS 和 Mac 的「有可发内容」按路径启发式判：`Mac/` 和 `*Mac*` 只算 Mac，`App/` `Widget/` `*Pad*` `*Phone*` 只算 iOS，其余 Packages 两边都算。
Windows 还是占位包，MSIX 真出来之前不打 `windows-v*`，所以 release-status 会一直说 Windows 该发——这是对的，它确实一次都没发过。

## 按触发条件做事

### 合并了一个改动到 main

什么都不用做。CI 跑闸，TestFlight 自动出包，toll-api 和 tollcat.app 自动部署（转 public 之后）。
想看就装 TestFlight 那一版，不想看就算。

### 觉得 main 上的东西值得一条更新日志了（或上次发版已过 30 天）

```bash
bash scripts/release-status.sh              # 看这次哪些端要上车：iOS？Mac？Android？
# 改 shared/version.json 的 version → X.Y.0
# 在 shared/changelog.json 的 entries 顶上加一条，三语一起写（那是唯一手写处）：
#   version 必须等于刚改的 version.json，闸上核对。
#   platforms 按这班车上的端：ios（iPhone+iPad）/ mac / android / windows。
#   date 用上架当天的 YYYY-MM-DD；还没上架就先不写，Publish 那天补（只改站点，不用重出包）。
#   drawer 缺省 = (patch == 0)：X.Y.0 弹抽屉，X.Y.Z 不弹。值得打断就写 true，反之 false。
python3 scripts/generate-shared.py          # 版本号 + 更新说明一起铺开：project.yml / gradle /
                                            # csproj / appxmanifest / winget、落地页 changelog.ts、
                                            # 三端三语表、Sparkle 说明、两个商店文案、Release body
xcodegen generate                           # project.yml 变了，pbxproj 要重生成（CI 会核对）
bash scripts/capture-appstore-screenshots.sh   # 截图 + 小组件那几格
python3 scripts/render-appstore-devices.py    # 嵌进 Apple 官方 Product Bezel
node scripts/render-appstore-marketing.mjs    # 加标题出宣传图（docs/appstore/README.md）
git commit -am "X.Y.0：<一句话>" && git push
git tag vX.Y.0 && git push origin vX.Y.0    # 私有期：再到 Actions → Release → Run workflow，ref 选这个 tag，勾要上车的端
```

只改了菜单栏就只勾 Mac，只改了 iPhone 壳就只勾 iOS；两边都动了两个都勾。然后：

1. release.yml 跑到 ios / mac job 会停在 Environment 审批，去 Actions 页点 Approve。
2. 勾了 iOS：App Store Connect 提交审核，开 7 天分阶段发布。
3. 勾了 Mac：TestFlight 装不到 Mac 直发版，在自己机器上装 Release 里那个 zip 跑一天。
4. 都没问题：GitHub → Releases → 那个 draft → **Publish**。
   这一下同时生效：`mac-appcast.yml` 把清单切到这版（带 Mac 资产才切）、落地页下载链接换新、更新日志公开。

### release-status 说 Android / Windows 该跟了

同一个 tag 上 dispatch release.yml 时勾 `android`。跑完 Release 里多一个签好名的 `TollCat.aab`，
手工上传 Play Console 内测轨道；内测跑一天，晋级生产并开分阶段。Windows 等 P0（Swift-on-Windows）落地。

### 出了 bug

```bash
# 在 main 上修，version → X.Y.Z，生成器，提交，打 tag，同上
```

- iOS 提交审核时勾加急。
- Mac 直发靠 Publish Release 那一下，先把 draft 里的 zip 装到自己机器上确认再按。只有 Mac 出 bug 就只勾 Mac，不必送 iOS 审核。
- 共用核心的 bug：Android / Windows 一起跟，不看落后几班。
- main 上有还不想发的东西：`git switch -c release/X.Y vX.Y.(Z-1)`，cherry-pick 修复，在分支上走同样流程，合回 main 后删分支。

### API 要加字段

1. 改 `shared/api-contract.json`，跑生成器，Worker 和四个客户端同源。
2. **先合并部署 API**（deploy-edge），再让 App 用新字段进下一班车。
3. 老字段等最老的在线 App 版本掉出窗口（约两个小版本）再删。D1 迁移只前进，回滚等于再写一个前进迁移。

## 你要亲手做的事（一次性）

### 转 public 那天，按顺序

1. **仓库转 public。** 再打第一个正式 tag——Sparkle appcast 和 `gh attestation verify` 都要公开仓库。
2. 六份 workflow 把注释里的触发条件换回去：ci.yml（push + PR）、beta.yml（push main）、release.yml（tags v*）、
   deploy-edge.yml（push main + paths）、release-status.yml（schedule）、mac-appcast.yml（release published）。
3. **Branch protection** `main`：required status checks 选 ci.yml 全部 job（Static gates、Test、Worker typecheck、
   Windows unit tests、Site build、UI smoke）；Require linear history；禁 force push、禁删除。不勾 required reviewers。
4. **Environments** 建五个，secret 从仓库级搬进去（仓库级的删掉）：

   | Environment | Required reviewers | secret |
   |---|---|---|
   | `app-store` | 你 | `APPLE_TEAM_ID`（Team ID，见 Config/Signing.xcconfig） `APP_STORE_CONNECT_KEY_ID` `ISSUER_ID` `PRIVATE_KEY`（.p8 base64） `BUILD_CERTIFICATE_BASE64`（Apple Distribution .p12 base64） `P12_PASSWORD` |
   | `mac-direct` | 你 | `APPLE_TEAM_ID` `APP_STORE_CONNECT_KEY_ID` `ISSUER_ID` `PRIVATE_KEY` `DEVELOPER_ID_CERTIFICATE_BASE64` `DEVELOPER_ID_P12_PASSWORD` `SPARKLE_PRIVATE_KEY`（**永远不换**） |
   | `google-play` | 你 | `ANDROID_UPLOAD_KEYSTORE_BASE64` `ANDROID_UPLOAD_KEYSTORE_PASSWORD` `ANDROID_UPLOAD_KEY_ALIAS` |
   | `windows` | 你 | （P0 之后：MSIX 签名证书） |
   | `api` | 不设 | `CLOUDFLARE_API_TOKEN`（Workers Scripts:Edit + D1:Edit + Workers Routes:Edit） `CLOUDFLARE_ACCOUNT_ID` |

   beta.yml 也用 `app-store`，但它不该每次都等审批：给 `app-store` 的 required reviewers 加上
   「Prevent self-review」关掉、并在 beta.yml 里换用一个不设 reviewers 的 `testflight` environment 复制同一组 secret——
   二选一，看你想不想每次 TestFlight 都点一下。
5. **Labels**：建 `release` label，release-status.yml 开 issue 要用。
6. 用真凭据在 tag 上跑一次 release.yml，走完 VERIFY.md 第 6 节。

### 各平台后台

- **App Store Connect**：API key 权限 App Manager 以上；bundle id 已建；App 记录、隐私标签、截图三语；TestFlight 内部测试组加上自己。
- **Play Console**：建 App、上传密钥（生成 upload keystore，base64 进 secret）、内测轨道加自己、数据安全表单。首几次 AAB 手工上传，Play 上传自动化等真跑通再加。
- **Cloudflare**：建一个 API token 只给 toll-api 和 tollcat-site 两个 Worker 加 D1；本机以后不再 `wrangler deploy`，改 dispatch deploy-edge。
- **winget**：`Windows/winget/com.zhechengqi.tollcat.yaml` 和 `TollCat.appinstaller` 的 URL 现在指 Release latest。Windows 真发之前照 Mac 的做法改成滚动 Release `windows-appinstaller`，否则只发 iOS 的一班车会让 Windows 用户下到 404。MSIX 出来后向 winget-pkgs 提 PR。

### 没验证过、第一次跑要盯着的

- release.yml 的 iOS / Mac 上传（VERIFY.md 已写明）。
- release.yml 的 Android job：ubuntu runner 上装 swiftly + Swift 6.3.3 + Android SDK bundle 再交叉编译，
  步骤照 `scripts/android-run.sh` 抄的，但没在 CI 上跑过。`swift sdk install` 的 URL 和 `swiftly init` 的参数如果变了在这里红。
- beta.yml：和 release.yml 的 iOS job 同一套步骤，只是不导 IPA 到 Release。
- deploy-edge.yml：`wrangler d1 migrations apply --remote` 在 CI 里需要 token 有 D1 权限。

## 永不

- 不建 staging / develop 分支
- 不让 ci.yml 读 secret
- 不在 API 上改字段语义，只加不改；不写回退迁移
- 不手改六个版本号落点中的任何一个，只改 `shared/version.json`
- 不为了凑日子发版，也不让做好的东西躺超过 30 天
- 不换 `SPARKLE_PRIVATE_KEY`
- 不把任何用户会去下载的 URL 指向 `releases/latest`：四个端不同班车，latest 属于谁都不确定
