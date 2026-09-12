# 怎么确认 App Store 上那个 App 就是这份源码

[English](VERIFY.md) · 中文

iOS 做不到把你手机上的二进制和这份源码编成逐字节相同的副本。
Apple 会重新签名，对可执行文件套 FairPlay 加密，再按设备瘦身；
Xcode 自己的构建也不是 bit-for-bit 确定的。所以这里不承诺、也不假装
能做那种复现。能接上的是一条更短的信任链。

**首次发版前需要人工验证一次。** 下面的 release workflow 写了，
但本仓库的作者还没有用真实 App Store Connect 凭据跑通过。
在那次人工验证完成之前，请把它当成「尚未启用的发布管道」，
不要把它当成已经发生过的事实。

## 1. 信任链怎么接

两段，各自解决一个问题。

### 源码 → 构建产物

正式包只在公开的 GitHub Actions 里、从 tag 构建。
workflow 是 [`.github/workflows/release.yml`](.github/workflows/release.yml)。
它会：

1. 用那个 tag 的提交生成工程并 `xcodebuild archive`
2. 导出 IPA，再上传 App Store Connect
3. 用 `actions/attest-build-provenance` 给 **IPA** 和 **dSYM 压缩包**
   签一份溯源证明（谁、在哪次 run、从哪个 commit 编出来的）
4. 把 IPA 的 sha256、`dwarfdump --uuid` 的完整输出、dSYM、
   以及当时的 Xcode / macOS / commit 挂到 GitHub Release

上传走 `xcrun altool --upload-app`，只用 App Store Connect API key。
不选 `notarytool`：那是给 Developer ID 公证 Mac 软件的，不是给
iOS 上架的。不选 fastlane：多一个第三方依赖，这个项目不需要。

PR 和普通 push 走 [`.github/workflows/ci.yml`](.github/workflows/ci.yml)，
**不读任何 secret**，fork 也能跑。

### 构建产物 → 你手机上那个 App

Apple 重签名、FairPlay、按设备瘦身都会改文件字节，所以 IPA 的 sha256
对不上 App Store 下到手机里的那份，这是正常的。

Mach-O 的 `LC_UUID` 会在重签名之后留下来——Apple 自己的崩溃符号化
就靠这个。把手机上那个可执行文件的 UUID，和这次 release 公布的
`uuids.txt` 比对。对得上，就是同一次链接的产物。

## 2. 怎么验证溯源证明

先从 GitHub Release 下载这次构建的 IPA（CI 刚编出来的那份，
还没被 App Store 加密），然后：

```bash
gh attestation verify TollCat.ipa --repo <owner>/<repo>
```

把 `<owner>/<repo>` 换成你正在看的这个仓库，例如 `someone/cost`。

预期：命令退出码 0，并打印这份证明的摘要：subject 对得上 IPA 的
digest，predicate 是 SLSA provenance，signer 是这个仓库的
`release.yml` 那次 run。对不上、或这份文件从未被这个仓库证明过，
`gh` 会非零退出。

dSYM 同样可以验：

```bash
gh attestation verify TollCat.dSYMs.zip --repo <owner>/<repo>
```

仓库如果还没做过一次成功的 tag 发版，上面两条都会失败。
这就是「首次发版前需要人工验证」的一部分。

## 3. 怎么比对 UUID

Release 资产里的 `uuids.txt` 是 `dwarfdump --uuid` 的完整输出，
每个架构切片一行。App 和 Widget 各有自己的 UUID。

### 从已经装上的 App 取出 `LC_UUID`

非越狱设备上，把 App Store 那份 IPA 完整拷出来非常麻烦：
系统不让你读其他 App 的包，加密后的可执行文件也不能当普通文件打开。
可行的路大概只有这几条：

1. **崩溃报告（最现实）**
   设置 → 隐私与安全性 → 分析与改进 → 分析数据，
   打开一条这个 App 的崩溃（或 Xcode Organizer 里同步下来的）。
   Binary Images 里会有一行类似：

   ```
   TollCat arm64  <XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX> /var/containers/Bundle/Application/…/TollCat.app/TollCat
   ```

   尖括号里就是 `LC_UUID`。和 `uuids.txt` 里 App 可执行文件那一行比对。

2. **你自己用 Xcode 装上去的 Debug / 开发版**
   那是另一份二进制，UUID 本来就和 App Store 那份不同。
   它只能证明「这份源码能编、能跑」，不能用来核对商店里的那一颗。

3. **越狱或解密后的 IPA**
   `dwarfdump --uuid Payload/TollCat.app/TollCat`。
   没有越狱就不要指望走这条。

对不上：不是同一次链接。对得上：就是 CI 在那个 tag 上编出来的那一份，
再被 Apple 签过、加密过、瘦身过。

## 4. 不信就自己构建

这是对真正怀疑的人最硬的答案。用免费 Apple ID 也能装到自己的设备上，
有效期大约 7 天，到期再编一次。

你编出来的包 **UUID 不会、也不该** 和 App Store 那份一样。
这一节的目的是让你亲眼看见源码在自己机器上做什么，
不是去复现商店里的字节。

1. 安装 Xcode 26+，登录你的 Apple ID。
2. 克隆本仓库，不要改依赖方向，也不要引入第三方库。

   ```bash
   git clone <this-repo>
   cd cost
   nix shell nixpkgs#xcodegen -c xcodegen generate                          # iOS
   nix shell nixpkgs#xcodegen -c xcodegen generate --spec project-mac.yml   # Mac
   ```

   没有 nix 就 `brew install xcodegen`，再跑上面那两条 `xcodegen generate`。
   iOS 那份工程里没有任何远程包，只有 Mac 那份会解析 Sparkle。

3. 用 Xcode 打开 `TollCat.xcodeproj`。Signing & Capabilities 里：
   - Team 换成你自己的个人团队
   - 若 bundle id `com.zhechengqi.tollcat` 被占用，改成你自己的
     （`project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER` 和 App Group
     `group.com.zhechengqi.tollcat` 要一起改，然后重新 `xcodegen generate`）
4. 把 iPhone 连上，信任这台电脑，选真机，Run。
5. 免费账号第一次会提示注册 bundle id 和 App Group，按 Xcode 提示走。
6. 打开 设置 → 关于，核对接线的域名清单。那一份和
   `OutboundHosts.swift` 是同一份数据。

当前阶段取数仍走 mock。你要核对的是：没有未知出站、凭据只进本机
Keychain、打赏 Worker 碰不到账单。

## 5. 出站域名

比二进制等不等价更要紧的，是「我的 AWS key 会不会被传走」。

- 编译期清单：`Packages/MeterKit/Sources/MeterProviders/OutboundHosts.swift`
- 设置 → 关于直接渲染这份清单
- `scripts/check-outbound-hosts.sh` 扫描源码里的 `https://` 字面量，
  host 不在清单里就让 CI 失败

账单凭据和账单数据只打向各家自己的 API。打赏留言只打向清单里那一条
Worker。内购走系统，不经过我们的服务器。

## 6. 首次发版前，人要亲手确认的事

workflow 语法用 `actionlint` 查过。下面这些在没有真实凭据之前
**没有跑过**，发第一个 tag 之前必须有人做完：

1. GitHub 的 Environments 里备齐这些 encrypted secrets（不放仓库级，不写进仓库；
   哪个 secret 进哪个 environment、哪些 environment 开 required reviewers，见 `docs/RELEASE.md`）：
   - `APP_STORE_CONNECT_KEY_ID`
   - `ISSUER_ID`
   - `PRIVATE_KEY`（`.p8` 的 base64）
   - `BUILD_CERTIFICATE_BASE64`（Apple Distribution `.p12` 的 base64）
   - `P12_PASSWORD`
   - `DEVELOPER_ID_CERTIFICATE_BASE64`（Developer ID Application `.p12` 的 base64，Mac 直发版用；
     这张证书只有账号持有人能在开发者网站建，Xcode 不会替 CI 生成）
   - `DEVELOPER_ID_P12_PASSWORD`
   - `SPARKLE_PRIVATE_KEY`（Sparkle `generate_keys -x` 导出的 EdDSA 私钥，
     和 `Mac/Supporting-Info.plist` 里的 `SUPublicEDKey` 是一对；**永远不要换**，
     换了所有已装机的 Mac 版都会拒装后续更新）
2. API key 在 App Store Connect 的权限够上传构建（Admin 或 App Manager）。
3. bundle id `com.zhechengqi.tollcat` 已在这个团队下建好，
   `scripts/ExportOptions.plist` 的 `teamID` 对得上。
4. 打一个测试 tag，看 archive、export、`altool --upload-app`、
   attest、GitHub Release（draft）五步是否都成功。Release 是 draft，Mac 的 Sparkle 在你点 Publish 之前看不到它。
5. 用 `gh attestation verify` 对刚挂上去的 IPA / dSYM 跑一遍。
6. 打开 Release 里的 `uuids.txt`，确认 App 和 Widget 的每个切片都在，
   并和 archive 里 `dwarfdump --uuid` 的现场输出一致。
7. 等 TestFlight / App Store 处理完，从一台真机的崩溃报告里抄 UUID，
   和 `uuids.txt` 对一次——这是整条链唯一一次碰到「用户手机上那个 App」。

## 7. Mac 直发版：怎么确认下到的 zip 和自动更新

Mac 版不走 App Store，走 Developer ID 签名 + 公证，装好之后由 Sparkle 自己更新。
这条链比 iOS 短：你下到的 zip 就是 CI 编出来的那份，没有 Apple 重签名那一步。

同一个 tag 的 Release 里，Mac 这边挂着：`TollCat-<版本>-mac.zip`、它的 `.sha256`、
`TollCat-mac.dSYMs.zip`、`uuids-mac.txt`、`build-info-mac.txt`，以及 `appcast.xml`。
生成它们的是 [`scripts/package-mac-release.sh`](scripts/package-mac-release.sh)。

### 下到的 zip

```bash
gh attestation verify TollCat-1.0.0-mac.zip --repo <owner>/<repo>
shasum -a 256 -c TollCat-1.0.0-mac.zip.sha256
ditto -x -k TollCat-1.0.0-mac.zip .
spctl -a -vv -t exec TollCat.app          # 期望：accepted, source=Notarized Developer ID
xcrun stapler validate TollCat.app        # 期望：The validate action worked!
codesign -dv --entitlements :- TollCat.app
```

entitlements 里应当只有 `project-mac.yml` 里 `TollCatMac` 声明的那几项：沙盒、网络 client、
用户选择的文件、App Group、Keychain 组，以及给 Sparkle 安装服务的两条
`temporary-exception.mach-lookup.global-name`（`…-spks` / `…-spki`）。多一条都不对。

`dwarfdump --uuid TollCat.app/Contents/MacOS/TollCat` 和 `uuids-mac.txt` 应逐字相同。

### 自动更新的清单

App 从 `SUFeedURL`（`Mac/Supporting-Info.plist`）读清单，也就是
`releases/download/mac-appcast/appcast.xml`——一个 tag 固定叫 `mac-appcast` 的滚动 Release，
**不是** `releases/latest`。iOS 和 Mac 不是同一班车，只发 iOS 的 Release 成为 latest 时不能弄坏 Mac 的更新。
每次带 Mac 资产的 `vX.Y.Z` Release 被 **Publish**，`mac-appcast.yml` 把它的 `appcast.xml` 和 zip 副本
覆盖到 `mac-appcast` 上；清单里 `enclosure` 的下载地址仍指向 `releases/download/vX.Y.Z/…`，
所以老版本的 zip 跟着老 Release 走，不会丢。Release 还是 draft 的时候清单不会动，Mac 用户看不到半成品。

清单里 `enclosure` 的 `sparkle:edSignature` 是用 `SPARKLE_PRIVATE_KEY` 对 zip 做的 EdDSA
签名。App 里带着公钥 `SUPublicEDKey`，签名不对就拒装，所以哪怕 GitHub 上的附件被换掉，
已装机的 App 也不会装上去。自己核一遍：

```bash
curl -sSL https://github.com/<owner>/<repo>/releases/download/mac-appcast/appcast.xml
# 公钥抄 Mac/Supporting-Info.plist 的 SUPublicEDKey，签名抄 appcast 里 enclosure 的 sparkle:edSignature。
# 只用系统自带的 CryptoKit，不需要 Sparkle 工具链，也不需要私钥。
swift scripts/verify-sparkle-signature.swift TollCat-1.0.0-mac.zip '<sparkle:edSignature>' '<SUPublicEDKey>'
```

`sparkle:version` 是 `CFBundleVersion`，CI 用 `GITHUB_RUN_NUMBER` 填，比大小靠它；
用户看到的版本号是 `sparkle:shortVersionString`，和 tag 去掉 `v` 之后相同
（`preflight` job 卡这一条）。

### 这条链此刻还没跑过的部分

- 仓库若仍是 private，`releases/download/…` 需要登录，Sparkle 匿名拉不到，
  查更新会静默失败。发第一个 Mac 版之前仓库要公开，或者把 `SUFeedURL` 和
  `package-mac-release.sh` 的下载前缀换到别处。
- `mac-appcast.yml` 在 Release Publish 时把清单切过去，这一步也没跑过：第一次 Publish 后
  到 `releases/download/mac-appcast/appcast.xml` 看一眼版本号对不对。
- 首个 tag 要人盯着 `mac` job 走完 archive → export（Developer ID）→ notarytool →
  staple → sign_update → appcast 六步，再从一台没装过的 Mac 下 zip 走一遍上面的核对。
- 装上 1.0.0 之后再发一个 1.0.1，看「检查更新…」能不能真的把它装进 /Applications 并重启。

## 8. Windows（MSIX + appinstaller）

对照 Mac 直发版：正式包只在公开的 GitHub Actions 里、从 tag 构建。
workflow 是同一个 [`release.yml`](.github/workflows/release.yml) 的 `windows` job。

**P0 还没在 Windows 11 真机上跑过。** 在 `Windows/README.md` 给出 go 之前，
这个 job 只挂 `.appinstaller` 占位，不签、不编 MSIX。下面是首发时要人工勾的。

### 首发人工检查单

- [ ] Windows 11 上官方 Swift 工具链把 `MeterCoreCLR.dll` 编出来（x64；arm64 记结论）
- [ ] WinUI 壳 P/Invoke `tollcat_catalog` / `tollcat_fetch`，真实凭据拉通 ≥3 家，本月数和 iOS 一致
- [ ] 凭据只进凭据管理器，任务管理器 / 磁盘上没有明文 key
- [ ] 托盘 16/24px 数字，亮暗两套；点开面板只读主窗落的数
- [ ] 开机启动以系统设置为准，关掉之后 App 里的开关跟着变
- [ ] 代码签名后的 MSIX 能装；`.appinstaller` 指向 GitHub Releases 的 latest
- [ ] 装上 1.0.0 再发 1.0.1，appinstaller 自动更新真的换包
- [ ] `gh attestation verify TollCat.msix --repo <owner>/<repo>` 通过
- [ ] winget 清单能搜到、能装
- [ ] 三语全屏走查（zh / en / ja）
- [ ] C# 源码里没有 `HttpClient`（提交闸已经扫）

