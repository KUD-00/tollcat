import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

/// 取景框的**作用范围**。
///
/// 筛选是仪表盘上的一种看法，不是数据。它绝不能漏到这三个地方：
///
/// - **Widget**：锁屏上那个数字必须是真的账单。用户排掉 AWS 只想在
///   App 里比较从量部分，锁屏跟着少一块钱是纯粹的谎。**唯一的例外是
///   订阅口径**（SPEC 12.5）：它是整页的一等公民切换，Widget 得和首屏
///   说同一个数——但 Widget 只能通过 `SharedStoreContents.widgetFilter`
///   拿到它，源码仍然一个字不提取景框类型，别的维度想跟先过那条注释。
/// - **提醒通知**：它本来就不许出现金额（SPEC 12.5），这里只是确认没人
///   顺手加上。
/// - **服务页 / 详情页**：那两页是「这家到底多少钱」，和你在首屏筛什么无关。
///
/// 扫文件的那几条同时跑在 `scripts/check-source-invariants.py`。名单改了两边一起改。
struct DashboardFilterScopeTests {
    @Test("Widget 一个字都不提取景框——订阅口径只能从 widgetFilter 拿")
    func widgetNeverMentionsTheFilter() throws {
        let files = try GuardrailSourceScan.swiftFiles(under: ["Widget"])
        #expect(!files.isEmpty, "找不到 Widget 源文件")
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(
                !text.contains("DashboardFilter"),
                "\(file.lastPathComponent) 提到了 DashboardFilter"
            )
            #expect(
                !text.contains("dashboardFilter"),
                "\(file.lastPathComponent) 读了 dashboardFilter 偏好"
            )
        }
    }

    /// `filter:` 是带默认值的参数，所以「没写」就等于 `.unfiltered`。
    /// 这条断言把那个默认值本身钉住——有人把默认改掉，Widget 会静默跟着变。
    @Test("计算器不传 filter 时就是不筛")
    func omittingTheFilterMeansUnfiltered() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
        let result = MonthToDateCalculator.compute(
            snapshots: [],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(result.filter == .unfiltered)
    }

    @Test("提醒通知文案连金额都不碰，更不可能被取景框影响")
    func reminderCopyCarriesNoAmount() throws {
        let text = try GuardrailSourceScan.sourceText(named: "ReminderNotificationCopy.swift")
        #expect(!text.contains("DashboardFilter"))
        #expect(!text.contains("totalUSD"))
        #expect(!text.contains("monthToDate"))
        #expect(!text.contains("Money"))
        #expect(!text.contains("$"))
        #expect(!text.contains("%"))
    }

    @Test("服务页和详情页不看取景框——那两页问的是「这家多少钱」")
    func serviceScreensIgnoreTheFilter() throws {
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterFeatures/Services"]
        )
        #expect(!files.isEmpty)
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(
                !text.contains("DashboardFilter"),
                "\(file.lastPathComponent) 提到了 DashboardFilter"
            )
        }
    }

    /// 取景框只在这几处出现。清单本身就是范围说明书：
    /// 有人在下一个文件里用到它，这条会红，然后必须先解释为什么。
    ///
    /// 这是纯文本扫描，**注释里出现类型名也算违规**。看着粗糙，但正是这一点
    /// 让它拦得住「先在注释里提一句，下一次顺手就用上」——名单要能挡住的
    /// 是渐变，不只是明目张胆的调用。
    @Test("用到取景框的文件就这几处")
    func onlyDeclaredFilesUseTheFilter() throws {
        // 名单按文件名记：文件在模块内搬目录不该弄断闸，改名/新增使用者才该。
        let allowedFileNames: Set<String> = [
            // 领域
            "DashboardFilter.swift",
            "PeriodTotalCalculator.swift",
            // 物化账本：折叠 / 投影 / 对账，取景框在投影那一步降级成 filter+sum。
            "LedgerFolder.swift",
            "LedgerProjection.swift",
            "LedgerView.swift",
            "LedgerSelfCheck.swift",
            "MonthProjection.swift",
            "MonthToDate.swift",
            "MonthToDateCalculator.swift",
            "MonthSpendHistoryCalculator.swift",
            // 落盘
            "AppPreferences.swift",
            "AppPreferencesRecord.swift",
            "DeviceTransfer.swift",
            // 仪表盘
            "DashboardModel.swift",
            "DashboardContents.swift",
            "DashboardView.swift",
            "DashboardFilterModel.swift",
            "DashboardFilterSheet.swift",
            "DashboardFilterSummary.swift",
            // 折算住在 MeterFeatures：模块视图那一层（MeterModules）看不到取景框。
            "MonthToDateContentBuilder.swift",
            // 分享卡从 `MonthToDate.filter` 读限定语。这一处**必须**在名单里：
            // 它是唯一会把数字送到别人手机上的地方。
            "ShareCardBuilder.swift",
            "ShareCardModel.swift",
            // 猫的台词：回看已过完的月份时不能说「按这个速度月底大概」。
            "CatSpeechFacts.swift",
            // 近几个月方卡：每个月用同一份取景框重算从量。
            "TrendBuilder.swift",
            // Widget 只跟订阅口径：取景框构造收在 widgetFilter，Widget 源码不提。
            "SharedStoreContents.swift",
            "LedgerCache.swift",
            // 开场预览按新用户默认口径（仅从量）摆数字。
            "OnboardingDemoContent.swift",
            // 组件画廊里的月格拖选样品：只读期间标题，不构造也不应用取景框。
            // DEBUG-only，不进正式包。
            "GalleryMonthRangeView.swift",
        ]
        var offenders: [String] = []
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Mac", "Widget", "Packages/MeterKit/Sources"]
        ) {
            let text = try String(contentsOf: file, encoding: .utf8)
            guard text.contains("DashboardFilter") else { continue }
            if !allowedFileNames.contains(file.lastPathComponent) {
                offenders.append(file.path)
            }
        }
        #expect(offenders.isEmpty, "取景框漏到了别处: \(offenders)")
    }

}


/// 账本这一层的边界。和 `scripts/check-source-invariants.py` 的 `LEDGER_ALLOWED` 同一套表。
///
/// 快照日志是**事件流**，不是读模型：一次刷新每家写一条，刷 200 次就有 200 行描述
/// 同一个月。直接扫它的展示代码会同时犯三件事——成本跟着刷新次数涨、绕过取景框的
/// 作用域约定、自己决定"哪条快照代表这个月"，而那条规则只能有一份实现。
///
/// **名单只减不增。** 剩几行就是这次搬迁还剩多少；想加一行之前先问自己，
/// 是不是该给账本加一种投影。
@MainActor
struct LedgerBoundaryTests {
    @Test("拿得到快照集合的文件就这几处")
    func onlyDeclaredFilesTouchTheSnapshotLog() throws {
        // 单条快照流过刷新管线是正常的，这里只拦「集合」——扫日志才是那件错事。
        // 同义写法一并拦住；`Snapshot]` 覆盖 `[Foo: Snapshot]` 这类容器。
        // 这仍然是字面量匹配，真正的边界是类型：展示路径拿到的是 `LedgerView`。
        let leaks = ["[Snapshot]", ".snapshots", "Array<Snapshot>", "[MeterCore.Snapshot]", "Snapshot]"]
        let allowedFileNames: Set<String> = [
            "DashboardModel.swift",
            "DashboardStore.swift",
            // 同一个门搬了位置：账本编排抽出 DashboardModel 时，`readings(...)`
            // 和 DEBUG dump 的转调跟着到了 LedgerSync。
            "LedgerSync.swift",
            // **同一个门的内存那一半，不是第四个消费方。** 它拿到的是
            // `readings(for:since:)` **已经限定过范围**的那一段，自己一次日志都不扫；
            // 存在的理由是不让同一段读数为了一条新快照被整份重解一遍。
            // 「哪条读数算数」仍然只有门那一个出处。
            "ReadingCache.swift",
        ]
        var offenders: [String] = []
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Mac", "Widget", "Packages/MeterKit/Sources"]
        ) {
            let path = file.path
            // 领域层和持久化层本来就在处理快照，这道闸只管展示路径。
            if path.contains("/Sources/MeterCore/")
                || path.contains("/Sources/MeterPersistence/")
                || path.contains("/Sources/MeterProviders/")
                || path.contains("/Sources/MeterInbox/") {
                continue
            }
            let text = try String(contentsOf: file, encoding: .utf8)
            guard leaks.contains(where: { text.contains($0) }) else { continue }
            if !allowedFileNames.contains(file.lastPathComponent) {
                offenders.append(path)
            }
        }
        #expect(offenders.isEmpty, "快照日志漏到了别处: \(offenders)")
    }

    /// 账本读失败不许被吞成一份空的读模型。
    /// 和 `scripts/check-source-invariants.py` 的 `check_ledger_read_not_swallowed` 同一套表。
    ///
    /// 一份空的 `LedgerView` 在屏幕上和「这个月花了 $0」长得一模一样，而且紧接着
    /// 那次同步会拿这份空的去重折，把磁盘上的账本一并抹掉——一次临时的读失败
    /// 于是变成一次不可逆的数据损失。
    @Test("账本这一层没有把读失败吞成空账本的写法")
    func ledgerReadFailuresAreNotSwallowed() throws {
        let swallows = ["?? LedgerView(", "try? MonthlyLedgerStore."]
        var offenders: [String] = []
        for file in try GuardrailSourceScan.swiftFiles(under: ["Packages/MeterKit/Sources"]) {
            let path = file.path
            let isLedgerPersistence = path.contains("/Sources/MeterPersistence/")
                && file.lastPathComponent.hasPrefix("Ledger")
            let isSync = file.lastPathComponent == "LedgerSync.swift"
            guard isLedgerPersistence || isSync else { continue }
            let text = try String(contentsOf: file, encoding: .utf8)
            let masked = GuardrailSourceScan.maskCommentsAndStrings(text)
            for token in swallows where masked.contains(token) {
                offenders.append("\(path): \(token)")
            }
        }
        #expect(offenders.isEmpty, "账本读失败被吞掉了: \(offenders)")
    }
}
