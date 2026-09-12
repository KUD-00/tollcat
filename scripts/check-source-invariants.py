#!/usr/bin/env python3
"""架构隔离的静态扫描。

对应这些会读源文件的测试，不跑模拟器：

- TipModuleIsolationTests
- DashboardFilterScopeTests 里扫文件的那几条
- PersistenceContainerTests 的 import / SwiftData 禁令
- ReminderSchedulerTests 的 UserNotifications 禁令
**版式规范那六条（列表行热区、主操作栏、键盘收起、sheet 关闭、抽屉 chrome、
下拉刷新）搬去了 `check-design-lint.py`。** 它们是「这里应该更好看」，
不是「越界即红」；混在一个文件里会让这个文件变成它自己想防的那种东西——
一个只有作者敢改的巨块。CI 两个都跑。
- DeviceTransferCoverageTests：落盘字段必须进迁移包，或写进「不装」名单
- LocalizationCoverageTests 的用词闸：禁止「凭证」，教程按钮必须写「我拿到凭据了，下一步」
- ArchitectureGuardrailTests：Keychain 档位、迁移码熵、MeterCore Date()/import、
  Widget 不链 Providers、App 不链 StoreKitTest、Package.swift 零第三方、
  URLSession.shared、手搓玻璃、≈、运行时 stub、JNI schema、ActivityKit

运行时行为（SwiftData 容器、计算器默认值）仍只在 xcodebuild test 里。
判据改了两边一起改。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 手写的 Swift 小词法器（抹注释和字符串）两个闸脚本共用一份：抹错一处，
# 两个脚本会对同一份源码给出不同的答案，而它们本该是同一条判断。
from _swift_scan import (  # noqa: E402
    gate_text,
    mask_comments_and_strings,
    rel,
    repo_root,
    scan_app_widget_sources,
    swift_files,
)

GENERATED_MARK = "GENERATED"

LEAF_MODULES = ("MeterTips", "MeterInbox", "MeterFeedback", "MeterUsage")

LEAF_FORBIDDEN = (
    "import MeterProviders",
    "import MeterFeatures",
    "import MeterPersistence",
    "import MeterTips",
    "import MeterInbox",
    "import MeterFeedback",
    "import MeterUsage",
    "import SwiftUI",
    "import SwiftData",
)

URLSESSION_ALLOWED = (
    "/Sources/MeterTips/TipWorkerClient.swift",
    "/Sources/MeterInbox/URLSessionInboxTransport.swift",
    "/Sources/MeterFeedback/URLSessionFeedbackSubmitter.swift",
    "/Sources/MeterUsage/URLSessionUsageSubmitter.swift",
    "/Sources/MeterProviders/URLSessionHTTPClient.swift",
    "/Sources/MeterPersistence/LiveCatalogTransport.swift",
)

WORKER_HOST_ALLOWED = (
    "/Sources/MeterTips/TipWorkerEndpoint.swift",
    "/Sources/MeterInbox/InboxEndpoint.swift",
    "/Sources/MeterFeedback/FeedbackEndpoint.swift",
    "/Sources/MeterUsage/UsageEndpoint.swift",
    "/Sources/MeterPersistence/CatalogEndpoint.swift",
    "/Sources/MeterProviders/OutboundHosts.swift",
)

ENDPOINT_FILES = (
    "Packages/MeterKit/Sources/MeterTips/TipWorkerEndpoint.swift",
    "Packages/MeterKit/Sources/MeterInbox/InboxEndpoint.swift",
    "Packages/MeterKit/Sources/MeterFeedback/FeedbackEndpoint.swift",
    "Packages/MeterKit/Sources/MeterUsage/UsageEndpoint.swift",
    "Packages/MeterKit/Sources/MeterPersistence/CatalogEndpoint.swift",
)

FILTER_ALLOWED = (
    "/Sources/MeterCore/DashboardFilter.swift",
    "/Sources/MeterCore/MonthToDate.swift",
    "/Sources/MeterCore/MonthToDateCalculator.swift",
    # 多月区间的折算：逐月调 MonthToDateCalculator 再求和，和它是一对。
    "/Sources/MeterCore/PeriodTotalCalculator.swift",
    # 物化账本三件套：折叠、投影、对账。取景框在投影那一步降级成 filter/group/sum，
    # 这三处正是它该出现的地方。
    "/Sources/MeterCore/LedgerFolder.swift",
    "/Sources/MeterCore/LedgerProjection.swift",
    # 读模型整份。取景框在 `scoped(to:)` 那一步降级成对行的筛选。
    "/Sources/MeterCore/LedgerView.swift",
    "/Sources/MeterCore/LedgerSelfCheck.swift",
    # 「预计月底」的外推：两条读路径共用同一份实现，注释里要提取景框的锚点。
    "/Sources/MeterCore/MonthProjection.swift",
    "/Sources/MeterCore/MonthSpendHistoryCalculator.swift",
    "/Sources/MeterPersistence/AppPreferences.swift",
    "/Sources/MeterPersistence/AppPreferencesRecord.swift",
    "/Sources/MeterPersistence/DeviceTransfer.swift",
    # Widget 只跟订阅口径：取景框构造收在 widgetFilter，Widget 源码仍然不提。
    "/Sources/MeterPersistence/SharedStoreContents.swift",
    # 账本缓存的开发页对账：几种取景框各算一遍，拿账本和重算比。
    "/Sources/MeterPersistence/LedgerCache.swift",
    # 开场预览按新用户默认口径（仅从量）摆数字。
    "/Sources/MeterFeatures/Setup/OnboardingDemoContent.swift",
    "/Sources/MeterFeatures/Dashboard/DashboardModel.swift",
    "/Sources/MeterModules/DashboardContents.swift",
    "/Sources/MeterFeatures/Dashboard/DashboardView.swift",
    "/Sources/MeterFeatures/Dashboard/DashboardFilterModel.swift",
    "/Sources/MeterFeatures/Dashboard/DashboardFilterSheet.swift",
    "/Sources/MeterModules/DashboardFilterSummary.swift",
    "/Sources/MeterModules/MonthToDateContentBuilder.swift",
    "/Sources/MeterFeatures/Share/ShareCardBuilder.swift",
    "/Sources/MeterFeatures/Share/ShareCardModel.swift",
    "/Sources/MeterFeatures/Dashboard/CatSpeechFacts.swift",
    "/Sources/MeterModules/TrendBuilder.swift",
    # 组件画廊里的月格拖选样品：只读 DashboardFilterSummary 的期间标题，
    # 不构造也不应用取景框。DEBUG-only，不进正式包。
    "/Sources/MeterFeatures/Developer/Gallery/GalleryMonthRangeView.swift",
)

ORIGIN_RE = re.compile(
    r"static let origin = URL\(string: \"(https://[^\"]+)\"\)"
)

# 产品用词。左边禁止出现，右边才是该写的。
# 闸文件自己会提到禁止项，除外。和 LocalizationCoverageTests 同步。
COPY_TERMS = (
    ("凭证", "凭据"),
    ("我拿到了，下一步", "我拿到凭据了，下一步"),
)
COPY_TERM_SKIP_NAMES = {
    "check-source-invariants.py",
    "LocalizationCoverageTests.swift",
}
COPY_TERM_FOLDERS = (
    "App",
    "Widget",
    "Packages/MeterKit/Sources",
    "Packages/MeterKit/Tests",
    "docs",
    "scripts",
)
COPY_TERM_SUFFIXES = {".swift", ".xcstrings", ".md", ".py", ".sh"}


def check_leaf_imports(root: Path, errors: list[str]) -> None:
    sources = root / "Packages" / "MeterKit" / "Sources"
    for path in swift_files(sources / "MeterProviders"):
        text = path.read_text(encoding="utf-8")
        for leaf in LEAF_MODULES:
            token = f"import {leaf}"
            if token in text:
                errors.append(f"MeterProviders/{path.name} {token}")

    for module in LEAF_MODULES:
        tokens = [token for token in LEAF_FORBIDDEN if not token.endswith(module)]
        if module in ("MeterFeedback", "MeterUsage"):
            tokens.append("import MeterCore")
        files = swift_files(sources / module)
        if not files:
            errors.append(f"{module} 没有源文件")
            continue
        for path in files:
            text = path.read_text(encoding="utf-8")
            for token in tokens:
                if token in text:
                    errors.append(f"{module}/{path.name} {token}")


def check_network_surface(root: Path, errors: list[str]) -> None:
    origins: list[tuple[str, str]] = []
    for relative in ENDPOINT_FILES:
        path = root / relative
        if not path.exists():
            errors.append(f"找不到 {relative}")
            continue
        match = ORIGIN_RE.search(path.read_text(encoding="utf-8"))
        if not match:
            errors.append(f"{relative} 读不出 origin")
            continue
        origins.append((relative, match.group(1)))

    if origins:
        expected = origins[0][1]
        for relative, url in origins[1:]:
            if url != expected:
                errors.append(f"{relative} origin 是 {url}，和 {origins[0][0]} 的 {expected} 不一致")
        host = expected.removeprefix("https://").split("/", 1)[0]
    else:
        host = ""

    session_offenders: list[str] = []
    host_offenders: list[str] = []
    for path in scan_app_widget_sources(root):
        text = path.read_text(encoding="utf-8")
        posix = path.as_posix()
        if "URLSession" in text and not any(posix.endswith(suffix) for suffix in URLSESSION_ALLOWED):
            session_offenders.append(rel(root, path))
        if host and host in text and not any(posix.endswith(suffix) for suffix in WORKER_HOST_ALLOWED):
            host_offenders.append(rel(root, path))
    for path in session_offenders:
        errors.append(f"URLSession 漏到 {path}")
    for path in host_offenders:
        errors.append(f"Worker host 漏到 {path}")


def check_filter_scope(root: Path, errors: list[str]) -> None:
    for path in swift_files(root / "Widget"):
        text = path.read_text(encoding="utf-8")
        if "DashboardFilter" in text:
            errors.append(f"Widget/{path.name} 提到了 DashboardFilter")
        if "dashboardFilter" in text:
            errors.append(f"Widget/{path.name} 读了 dashboardFilter 偏好")

    reminder = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Settings"
        / "ReminderNotificationCopy.swift"
    )
    if reminder.exists():
        text = reminder.read_text(encoding="utf-8")
        for token in ("DashboardFilter", "totalUSD", "monthToDate", "Money", "formatted"):
            if token in text:
                errors.append(f"ReminderNotificationCopy.swift 含 {token}")
        if "$" in text or "%" in text:
            errors.append("ReminderNotificationCopy.swift 含 $ 或 %：通知里不许出现金额")
    else:
        errors.append("找不到 ReminderNotificationCopy.swift")

    services = (
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures" / "Services"
    )
    for path in swift_files(services):
        if "DashboardFilter" in path.read_text(encoding="utf-8"):
            errors.append(f"Services/{path.name} 提到了 DashboardFilter")

    for path in scan_app_widget_sources(root):
        if "DashboardFilter" not in path.read_text(encoding="utf-8"):
            continue
        posix = path.as_posix()
        if not any(posix.endswith(suffix) for suffix in FILTER_ALLOWED):
            errors.append(f"取景框漏到了 {rel(root, path)}")


# ─────────────────────────────────────────────────────────────
# 账本这一层的边界。
#
# 快照日志是**事件流**，不是读模型：一次刷新每家写一条，刷 200 次就有 200 行
# 描述同一个月。任何直接扫它的展示代码都会同时犯三件事——成本跟着刷新次数涨、
# 绕过取景框的作用域约定、自己决定"哪条快照代表这个月"（那条规则只能有一份实现）。
#
# 所以展示路径**不许拿到快照的集合**。要数字就问物化账本
# （`MonthlyRollup` / `AccountLatest`），要原始读数就走明确开的那个口。
# 单条快照流过刷新管线是正常的，这里只拦 `[Snapshot]` 和 `.snapshots`。
#
# 名单**只减不增**。剩几行就是这次搬迁还剩多少——加一行之前先问自己，
# 是不是该给账本加一种投影。和 `LedgerBoundaryTests` 同一套表，改了两边一起改。
# `[Snapshot]` 只是最常见的写法。同义写法一并拦住：`Array<Snapshot>`、模块限定的
# `[MeterCore.Snapshot]`、以及 `[Foo: Snapshot]` 这种以 `Snapshot]` 收尾的容器。
LEDGER_LEAK_TOKENS = (
    "[Snapshot]",
    ".snapshots",
    "Array<Snapshot>",
    "[MeterCore.Snapshot]",
    "Snapshot]",
)
LEDGER_ALLOWED = (
    # 门自己：`readings(for:since:)` 那个口、DEBUG 的 dump 出口，和写入侧的
    # `applyConnection(snapshots:)`。快照日志的读口在 MeterPersistence（`SnapshotLog` /
    # `LedgerCache`），Features 里没有任何一处再持有整份日志——连 DashboardModel 也没有。
    "/Sources/MeterFeatures/Dashboard/DashboardModel.swift",
    "/Sources/MeterFeatures/Dashboard/DashboardStore.swift",
    # LedgerSync 不是新开的口，是**同一个门搬了个位置**：账本编排从 DashboardModel
    # 抽出来时，`readings(...)` / DEBUG dump 的转调跟着走。名单条数没变多的意思是
    # 「没有新的地方拿得到集合」，不是「文件名不许换」。
    "/Sources/MeterFeatures/Dashboard/LedgerSync.swift",
    # 同一个门的内存那一半：拿到的是 `readings(for:since:)` 已经限定过范围的那一段，
    # 自己一次日志都不扫。存在的理由是不让同一段读数为了一条新快照被整份重解一遍
    # （实测详情页 46ms 的读盘解 blob 就在这条路上）。见 `ReadingCache`。
    "/Sources/MeterFeatures/Dashboard/ReadingCache.swift",
    # 18 → 5 → 3 → 4。开发页三处改走 `debugAllReadings()`，不再自己碰快照集合。
    # 展示路径已经全部搬完：要数字问账本，要原始读数走 `readings(for:since:)`
    # 那个明确开的口——它有名字、有范围、有理由，不是漏洞。
    #
    # 这仍然是一道**字面量**闸：`Array<Snapshot>` / `[MeterCore.Snapshot]` 也在
    # 名单里（见 `LEDGER_LEAK_TOKENS`），但真正的边界是类型——展示路径拿到的是
    # `LedgerView`，那才是让这件事不可能发生的东西。
)


def check_ledger_boundary(root: Path, errors: list[str]) -> None:
    allowed_hits: set[str] = set()
    for path in scan_app_widget_sources(root):
        posix = path.as_posix()
        # 领域层和持久化层本来就在处理快照，这道闸只管展示路径。
        if "/Sources/MeterCore/" in posix or "/Sources/MeterPersistence/" in posix:
            continue
        if "/Sources/MeterProviders/" in posix or "/Sources/MeterInbox/" in posix:
            continue
        text = path.read_text(encoding="utf-8")
        if not any(token in text for token in LEDGER_LEAK_TOKENS):
            continue
        match = next((s for s in LEDGER_ALLOWED if posix.endswith(s)), None)
        if match is None:
            errors.append(
                f"快照日志漏到了 {rel(root, path)}"
                "——展示路径要数字请问账本，要原始读数请走明确开的口"
            )
        else:
            allowed_hits.add(match)
    for stale in sorted(set(LEDGER_ALLOWED) - allowed_hits):
        errors.append(f"账本名单里的 {stale} 已经不碰快照了，把这一行删掉")


# ─────────────────────────────────────────────────────────────
# 账本读失败不许被吞成一份空的读模型。
#
# 一份空的 `LedgerView` 在屏幕上和「这个月花了 $0」长得一模一样，而且紧接着那次
# 同步会拿这份空的去重折，把磁盘上的账本一并抹掉——一次临时的读失败于是变成
# 一次不可逆的数据损失。规则本来就写在 ARCHITECTURE 里（「读一律 throws，下面一层
# 不许把它吞成空数组」），只是没写到账本这一层上。
#
# 和 `LedgerBoundaryTests.ledgerReadFailuresAreNotSwallowed` 同一套表，改了两边一起改。
LEDGER_SWALLOW_FILES = (
    "Packages/MeterKit/Sources/MeterPersistence",
    "Packages/MeterKit/Sources/MeterFeatures/Dashboard/LedgerSync.swift",
)
LEDGER_SWALLOW_TOKENS = ("?? LedgerView(", "try? MonthlyLedgerStore.")


# MeterCore 里允许出现 `Locale.autoupdatingCurrent` 的文件。**只有一个。**
#
# `MeterClock` 的 locale 不产出任何话：它是格式化缓存钥匙的一部分
# （历法 + 时区 + locale），时钟少一样，两个 locale 下会共用同一份格式化器。
# 和 `ArchitectureGuardrailTests.meterCoreStaysPure` 同一份名单。
LOCALE_EXEMPT_CORE_FILES = {"MeterClock.swift"}


def check_ledger_read_not_swallowed(root: Path, errors: list[str]) -> None:
    targets: list[Path] = []
    persistence = root / "Packages" / "MeterKit" / "Sources" / "MeterPersistence"
    targets += [p for p in swift_files(persistence) if p.name.startswith("Ledger")]
    sync = root / "Packages/MeterKit/Sources/MeterFeatures/Dashboard/LedgerSync.swift"
    if sync.is_file():
        targets.append(sync)
    else:
        errors.append("找不到 LedgerSync.swift")
    for path in targets:
        masked = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        for token in LEDGER_SWALLOW_TOKENS:
            if token in masked:
                errors.append(
                    f"{rel(root, path)} 里出现 {token}"
                    "——账本读失败要抛出去，不能吞成一份空账本（屏幕会当场报 $0）"
                )


def check_persistence_contract(root: Path, errors: list[str]) -> None:
    sources = root / "Packages" / "MeterKit" / "Sources"
    persistence = swift_files(sources / "MeterPersistence")
    if not persistence:
        errors.append("MeterPersistence 没有源文件")
    for path in persistence:
        text = path.read_text(encoding="utf-8")
        for token in ("import SwiftUI", "import MeterDesign", "import MeterProviders"):
            if token in text:
                errors.append(f"MeterPersistence/{path.name} {token}")

    core = swift_files(sources / "MeterCore")
    if not core:
        errors.append("MeterCore 没有源文件")
    for path in core:
        text = path.read_text(encoding="utf-8")
        for token in ("SwiftData", "@Model", "ModelContainer", "ModelContext"):
            if token in text:
                errors.append(f"MeterCore/{path.name} 含 {token}")
        if "import UserNotifications" in text:
            errors.append(f"MeterCore/{path.name} import UserNotifications")
        for line in text.splitlines():
            stripped = line.strip()
            if stripped.startswith("import ") and stripped != "import Foundation":
                errors.append(f"MeterCore/{path.name} {stripped}（只许 Foundation）")
        masked = mask_comments_and_strings(text)
        # 墙钟进入这一层**只有一个入口**：`MeterClock`。
        #
        # 「Core 里一处 Date() 都不许有」这条规矩的目的是「时间从参数进来」，
        # 而不是「这一层不知道现在几点」。以前为了守字面上的禁令，时钟被放在
        # MeterFeatures——于是 Modules / Persistence / Widget 全都拿不到它，
        # 各自去捡 `Calendar.current` 和 `Date.formatted`（那才是真正的漏）。
        # 现在时钟在这一层，有名字、有注入口、有 `design` 那份钉死的实现，
        # 而别的文件照旧一处都不许有。
        clock_file = path.name == "MeterClock.swift"
        if not clock_file:
            if re.search(r"\bDate\(\)", masked) or re.search(r"\bDate\.now\b", masked):
                errors.append(f"MeterCore/{path.name} 出现 Date() / Date.now，时间必须从参数进来")
            if re.search(r"\bCalendar\.current\b", masked):
                errors.append(f"MeterCore/{path.name} 出现 Calendar.current，日历必须从参数进来")
        elif "autoupdatingCurrent" not in masked:
            errors.append(
                "MeterCore/MeterClock.swift 的 live 时钟必须走 autoupdatingCurrent，"
                "否则常驻进程换时区之后一直按旧时区算月份。"
            )
        # MeterCore 出**数**，不出**话**。
        #
        # 这条线以前只写在文档里，而文档写的是「不产生用户可见文案」——
        # 可 `CurrencyAmountFormat` 明明产出 `$1,234.56`，读文档的人只会以为
        # 文档错了或者代码越界了，两边都不知道该信哪个。真正的线是：
        # 数字的写法（符号、分位、小数位）是 Money 这个领域类型自己的事，
        # 而且必须**不跟系统区域**（中文 locale 会把美元写成 US$）；
        # 一切跟语言、跟系统区域有关的东西在 MeterFormat 那一层。
        for token in (
            "String(localized:",
            "NumberFormatter",
            "DateFormatter",
        ):
            if token in masked:
                errors.append(
                    f"MeterCore/{path.name} 出现 {token}：跟语言 / 系统区域有关的都归 MeterFormat，"
                    "MeterCore 只出跟区域无关的数字写法。"
                )
        # Locale 单独一条，**用正则不用 token**：`calendar.locale = .autoupdatingCurrent`
        # 这种隐式成员写法字面量匹配不到，而它就在 `MeterClock.swift` 里——
        # 这条禁令过去是靠拼写通过的，不是靠判断。
        #
        # `MeterClock` 是**明写的豁免**：它带 locale 不是为了产出话，是因为
        # 「历法 + 时区 + locale」三样合起来才是格式化缓存的钥匙（见 `FormatterCache`）；
        # 时钟少一样，两个 locale 下会共用同一份格式化器。
        if path.name not in LOCALE_EXEMPT_CORE_FILES:
            if re.search(r"\bLocale\.(current|autoupdatingCurrent)\b|\.autoupdatingCurrent\b", masked):
                errors.append(
                    f"MeterCore/{path.name} 出现 Locale.current / .autoupdatingCurrent："
                    "跟系统区域有关的都归 MeterFormat；真要豁免请写进 LOCALE_EXEMPT_CORE_FILES 并说明理由。"
                )
        if re.search(r"\bL\(", masked):
            errors.append(f"MeterCore/{path.name} 出现 L()：MeterCore 不产生任何要翻译的话")

    # MeterDesign 认得系统的 UI 框架（SwiftUI / Charts / CoreGraphics / ImageIO /
    # CoreImage / UniformTypeIdentifiers / os / UIKit / AppKit），**不认得任何领域类型**。
    # 「只 import SwiftUI」那句话从来就不成立（Charts 和位图导出一直在），
    # 而真正要守的是这一条：它不知道什么是 Provider、什么是 Snapshot。
    for path in swift_files(sources / "MeterDesign"):
        for line in path.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith("import Meter"):
                errors.append(
                    f"MeterDesign/{path.name} {stripped}：设计系统不认识领域类型，"
                    "组件收的是已经排好的字符串和 0...1 的比例。"
                )

    for path in swift_files(sources / "MeterProviders"):
        text = path.read_text(encoding="utf-8")
        for token in ("import SwiftUI", "import SwiftData"):
            if token in text:
                errors.append(f"MeterProviders/{path.name} {token}")


def check_catalog_copyables(root: Path, errors: list[str]) -> None:
    """`copyable` 是给「要整段粘进控制台的原文」（AWS 的 IAM 策略 JSON）用的重型 UI。

    几个字的表单值（名称、网址）直接写在步骤文字里就够，配复制按钮和三语标签
    只是加重界面。`CatalogTests` 里同一份允许名单，改了两边一起改。
    2026-09 Stripe 指南把 copyable 当成「表单填什么」的提示用，单元测试抓到了，
    但那条测试当时只在 CI 上跑、CI 又是手动触发，于是内容漂了一周没人发现——
    所以规则也进提交闸。
    """
    allowed = {"IAM 策略"}
    catalog_json = (
        root / "Packages" / "MeterKit" / "Sources" / "MeterPersistence" / "Catalog" / "catalog.json"
    )
    try:
        data = json.loads(catalog_json.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"读不了 {catalog_json.relative_to(root)}：{exc}")
        return
    for guide_id, guide in (data.get("guides") or {}).items():
        for part in guide.get("parts") or []:
            for step in part.get("steps") or []:
                copyable = step.get("copyable")
                if not isinstance(copyable, dict):
                    continue
                label = copyable.get("label")
                if label not in allowed:
                    errors.append(
                        f"catalog.json guides.{guide_id}: copyable「{label}」不在允许名单 {sorted(allowed)}。"
                        "copyable 只给要整段粘贴的原文；几个字的值写进步骤文字即可。"
                    )


def check_declined_providers(root: Path, errors: list[str]) -> None:
    """providers.json `offered: false` 必须和 ProviderCatalog 的 declined 对上。"""
    import json as _json
    import re as _re

    providers_doc = _json.loads((root / "shared" / "providers.json").read_text(encoding="utf-8"))
    json_declined = [
        item["key"]
        for item in providers_doc["providers"]
        if item.get("offered") is False
    ]
    providers_dir = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterProviders"
    )
    catalog = (providers_dir / "ProviderCatalog.swift").read_text(encoding="utf-8")
    for batch in sorted(providers_dir.glob("ProviderCatalog+Batch*.swift")):
        catalog += "\n" + batch.read_text(encoding="utf-8")
    ids = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterCore"
        / "ProviderID.swift"
    ).read_text(encoding="utf-8")
    swift_declined_count = catalog.count("accessStatus: .declined")
    if swift_declined_count != len(json_declined):
        errors.append(
            "不接入家数对不上：providers.json offered:false="
            f"{len(json_declined)}，ProviderCatalog accessStatus: .declined="
            f"{swift_declined_count}"
        )
    for key in json_declined:
        if f'ProviderID(rawValue: "{key}")' not in ids:
            errors.append(f"不接入 {key}：ProviderID.swift 没有 rawValue")
        if f'colorKey: "{key}"' not in catalog:
            errors.append(f"不接入 {key}：ProviderCatalog 没有 colorKey")
        if not _re.search(
            rf'colorKey: "{_re.escape(key)}".*?accessStatus: \.declined',
            catalog,
            _re.S,
        ):
            errors.append(f"不接入 {key}：ProviderCatalog 没有标 declined")


def check_catalog_sync(root: Path, errors: list[str]) -> None:
    bundled = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterPersistence"
        / "Catalog"
        / "catalog.json"
    )
    replicas = (
        (
            root / "worker" / "src" / "catalog.json",
            "Worker 没有 catalog.json：部署后 App 拉不到目录",
        ),
        (
            root
            / "Android"
            / "native"
            / "Sources"
            / "MeterBridge"
            / "Resources"
            / "catalog.json",
            "Android / Windows 桥没有 catalog.json：汇率和教程会和 iOS 分叉",
        ),
        (
            root
            / "Windows"
            / "app"
            / "Assets"
            / "swiftpm"
            / "catalog.json",
            "Windows 壳没有 catalog.json：汇率和教程会和 iOS 分叉",
        ),
    )
    if not bundled.is_file():
        errors.append("找不到打包目录 catalog.json")
        return
    bundled_resolved = bundled.resolve()
    text = bundled.read_text(encoding="utf-8")
    if "http://" in text or "https://" in text:
        errors.append("catalog.json 含 URL。SPEC 第 07 节：目录只能带文字和数字")
    for replica, missing in replicas:
        if not replica.exists():
            errors.append(missing)
            continue
        if not replica.is_symlink():
            errors.append(
                f"{rel(root, replica)} 必须是指向打包目录的 symlink，"
                "现在是普通文件，改 iOS 目录 Android/Worker 会漂"
            )
            continue
        resolved = replica.resolve()
        if resolved != bundled_resolved:
            errors.append(
                f"{rel(root, replica)} 指向 {resolved}，打包是 {bundled_resolved}"
            )


# 落盘字段 → 迁移载荷字段。不装的字段在 *_OMITTED 里。
# 与 DeviceTransferCoverageTests 同一套表，改了两边一起改。
TRANSFER_OMITTED_MODELS = {
    "SnapshotRecord": "SPEC 12：历史读数不进包，刷新重拉",
    "TipRecord": "打赏收据留在买过的那台设备上",
    "MonthlyRollupRecord": "缓存不是数据：换设备时从对方自己的快照重折一遍，不该跟着搬",
    "AccountLatestRecord": "缓存不是数据：换设备时从对方自己的快照重折一遍，不该跟着搬",
    "LedgerStampRecord": "缓存不是数据：账本从对方自己的快照重折，戳记的是本机那一份输入",
}
TRANSFER_CARRIED_MODELS = (
    "SubscriptionRecord",
    "ManualUsageRecord",
    "ProviderConfigRecord",
    "ProviderMembershipRecord",
    "AppPreferencesRecord",
)
MANUAL_USAGE_CARRIED = {
    "accountIDRaw": "accountID",
    "providerIDRaw": "providerID",
    "periodYear": "periodYear",
    "periodMonth": "periodMonth",
    "amountUSD": "amountUSD",
    "enteredAt": "enteredAt",
    # 这笔手填折成快照时用哪一种 kind。以前导入写死 `.usage`，
    # `.planAndUsage` 那几家换台设备就变一个数。
    "kindRaw": "kindRaw",
}
MEMBERSHIP_CARRIED = {
    "providerIDRaw": "providerID",
    "sortIndex": "sortIndex",
}
SUBSCRIPTION_CARRIED = {
    "name": "name",
    "amountUSD": "amountUSD",
    "periodRaw": "period",
    "anchorYear": "anchorYear",
    "anchorMonth": "anchorMonth",
    "anchorDay": "anchorDay",
    "endYear": "endYear",
    "endMonth": "endMonth",
    "endDay": "endDay",
    "accountIDRaw": "accountID",
    "providerIDRaw": "providerID",
    "quantity": "quantity",
}
PROVIDER_CONFIG_CARRIED = {
    "accountIDRaw": "accountID",
    "providerIDRaw": "providerID",
    "nickname": "nickname",
    "identityHint": "identityHint",
    "remoteIdentityFingerprint": "remoteIdentityFingerprint",
    "isEnabled": "isEnabled",
    "archivedAt": "archivedAt",
    "sortIndex": "sortIndex",
    "credentialReference": "credentialReference",
    "includeInGlobalRefresh": "includeInGlobalRefresh",
    "usesInbox": "usesInbox",
    "inboxIngestKeyID": "inboxIngestKeyID",
}
# `archivedDay` 是 `archivedAt` 的分量形状，不单独进包：包里带瞬间，
# 导入时按**本机**日历重记那一天（见 `ArchivedStamp`）。带分量反而会把
# 源设备的时区钉进目的地。
PROVIDER_CONFIG_OMITTED = {"lastSuccessfulRefreshAt", "archivedDay"}
PREFERENCES_CARRIED = {
    "includeAWSInGlobalRefresh": "includeAWSInGlobalRefresh",
    "isReminderEnabled": "isReminderEnabled",
    "reminderFrequencyRaw": "reminderSchedule",
    "reminderHour": "reminderSchedule",
    "reminderMinute": "reminderSchedule",
    "reminderWeekday": "reminderSchedule",
    "reminderDayOfMonth": "reminderSchedule",
    "appearanceRaw": "appearanceRaw",
    "hasCompletedOnboarding": "hasCompletedOnboarding",
    "providerHistoryRangeRaw": "providerHistoryRangeRaw",
    "hidesCat": "hidesCat",
    "refreshesUsageOnActivate": "refreshesUsageOnActivate",
    "displayCurrencyRaw": "displayCurrency",
    "seenUsageGuideIDsJSON": "seenUsageGuideIDs",
    "dashboardLayoutJSON": "dashboardLayout",
    "lastSeenWhatsNewVersion": "lastSeenWhatsNewVersion",
}
PREFERENCES_OMITTED = {
    "id",
    "isDemoModeEnabled",
    "isDemoBannerDismissed",
    "filterMonthsBack",
    "filterIncludesSubscriptions",
    "filterExcludedAccountsJSON",
    "filterPeriodKindRaw",
    "filterPeriodMonthCount",
    # Mac 菜单栏露什么是这台机器的事，iPhone / Android 没有对应物。
    "menuBarStyleRaw",
    "hidesDockIconWhenWindowClosed",
}
MAILBOX_CARRIED = {
    "mailbox": "mailbox",
    "readKey": "readKey",
}
PAYLOAD_FIELDS = {
    "schemaVersion",
    "connections",
    "memberships",
    "subscriptions",
    "preferences",
    "mailbox",
    "manualUsages",
}

STORED_VAR_RE = re.compile(r"^\s*public var (\w+)\s*:", re.M)
# 模型名单在 `TollCatSchemaV1.models` 里（有了 VersionedSchema 之后就不再是
# 裸的 `Schema([...])`）。改了那边这条也要跟着改，不然它会读不出名单——
# 而读不出名单时这份闸是**响的**，不是静默放行。
SCHEMA_MODELS_RE = re.compile(
    r"static var models: \[any PersistentModel\.Type\] \{\s*\[(.*?)\]\s*\}", re.S
)


def type_body(text: str, type_name: str) -> str | None:
    masked = mask_comments_and_strings(text)
    pattern = re.compile(rf"\b(?:struct|class|enum)\s+{re.escape(type_name)}\b")
    match = pattern.search(masked)
    if not match:
        return None
    i = match.end()
    while i < len(masked) and masked[i] != "{":
        i += 1
    if i >= len(masked):
        return None
    depth = 0
    for j in range(i, len(masked)):
        if masked[j] == "{":
            depth += 1
        elif masked[j] == "}":
            depth -= 1
            if depth == 0:
                return text[i : j + 1]
    return None


def stored_public_vars(body: str) -> set[str]:
    names: set[str] = set()
    for match in STORED_VAR_RE.finditer(body):
        rest = body[match.end() :]
        i = 0
        while i < len(rest) and rest[i] not in "{\n=":
            i += 1
        if i < len(rest) and rest[i] == "{":
            continue
        names.add(match.group(1))
    return names


def read_type_vars(root: Path, relative: str, type_name: str, errors: list[str]) -> set[str] | None:
    path = root / relative
    if not path.is_file():
        errors.append(f"找不到 {relative}")
        return None
    body = type_body(path.read_text(encoding="utf-8"), type_name)
    if body is None:
        errors.append(f"{relative} 读不出 {type_name}")
        return None
    return stored_public_vars(body)


def field_gaps(
    label: str,
    actual: set[str],
    carried: dict[str, str],
    omitted: set[str],
    errors: list[str],
) -> None:
    expected = set(carried) | omitted
    for name in sorted(actual - expected):
        errors.append(f"{label}.{name} 既没进迁移包，也不在不装名单里")
    for name in sorted(expected - actual):
        errors.append(f"{label}.{name} 在名单里，类型上已经没了")
    for name in sorted(set(carried) & omitted):
        errors.append(f"{label}.{name} 同时出现在进包和不装名单")


def transfer_gaps(type_name: str, actual: set[str], expected: set[str], errors: list[str]) -> None:
    for name in sorted(actual - expected):
        errors.append(f"{type_name}.{name} 是新的载荷字段：接到 DeviceTransfer，或从类型上拿掉")
    for name in sorted(expected - actual):
        errors.append(f"{type_name} 没有 {name}，但名单还指着它")


def check_provider_wiring(root: Path, errors: list[str]) -> None:
    """加一家要动的那几份手工清单，必须一处不落。

    加一家现在要改三份 Swift 清单（`ProviderID` / `ProviderCatalog` /
    `ProviderAssembly` 的集合 + switch）加三份数据（`shared/providers.json`、
    `catalog.json` 的教程、`OutboundHosts`）。清单本身没法自动生成——
    `tierReason` 那种逐家写的话、URL 那种安全红线都得人写——但**漏了哪一处
    可以当场说出来**，而这正是它现在做不到的：

    - 适配器写了、`liveRESTProviderIDs` 忘了加：那家永远不会被取数，
      界面上是「暂无读数」，不报错；
    - 反过来忘了写 switch 分支：`makeProvider` 回 nil，同样安静；
    - 忘了写教程：向导第二步一片空白；
    - 忘了声明域名：出站白名单挡下来，那个错更像「这家接口坏了」。

    这四条都不是编译期能发现的。
    """
    import json as _json
    from urllib.parse import urlparse

    providers = root / "Packages" / "MeterKit" / "Sources" / "MeterProviders"
    assembly = gate_text(root, providers / "ProviderAssembly.swift", errors)
    catalog_path = providers / "ProviderCatalog.swift"
    catalog = gate_text(root, catalog_path, errors)
    if catalog is not None:
        for batch in sorted(providers.glob("ProviderCatalog+Batch*.swift")):
            extra = gate_text(root, batch, errors)
            if extra is not None:
                catalog += "\n" + extra
    hosts = gate_text(root, providers / "OutboundHosts.swift", errors)
    catalog_json = root / "Packages" / "MeterKit" / "Sources" / "MeterPersistence" / "Catalog" / "catalog.json"
    guides_text = gate_text(root, catalog_json, errors)
    ids_text = gate_text(root, root / "Packages" / "MeterKit" / "Sources" / "MeterCore" / "ProviderID.swift", errors)
    if None in (assembly, catalog, hosts, guides_text, ids_text):
        return

    # 1. `liveRESTProviderIDs` 和 switch 分支必须是同一批。
    marker = "liveRESTProviderIDs: Set<ProviderID> = ["
    if marker not in assembly:
        errors.append("ProviderAssembly 读不出 liveRESTProviderIDs")
        return
    listed = set(re.findall(r"\.([A-Za-z0-9_]+)", assembly.split(marker, 1)[1].split("]", 1)[0]))
    cases = set(re.findall(r"case\s+\.([A-Za-z0-9_]+)\s*:", assembly))
    for name in sorted(cases - listed):
        errors.append(
            f"ProviderAssembly 有 .{name} 的分支却不在 liveRESTProviderIDs："
            "适配器永远不会被调用，界面上只是「暂无读数」。"
        )
    for name in sorted(listed - cases):
        errors.append(
            f"liveRESTProviderIDs 有 .{name} 却没有 switch 分支：makeProvider 会回 nil。"
        )

    # 2. 每个能取数的家都要有接入说明，否则向导第二步空白。
    name_to_raw = dict(
        re.findall(
            r'static let ([A-Za-z0-9_]+)\s*=\s*ProviderID\(rawValue:\s*"([^"]+)"\)',
            ids_text,
        )
    )
    guides = set(_json.loads(guides_text).get("guides", {}))
    for name in sorted(listed):
        raw = name_to_raw.get(name, name)
        if raw not in guides:
            errors.append(f"catalog.json 没有 {raw} 的接入说明，而它在 liveRESTProviderIDs 里")

    # 3. 目录里的每个 URL 的域名都要在 OutboundHosts 里声明过。
    declared = set(re.findall(r'OutboundHost\(host:\s*"([^"]+)"', hosts))
    seen: set[str] = set()
    for url in re.findall(r'"(https?://[^"]+)"', catalog):
        host = urlparse(url).hostname
        if host and host not in declared and host not in seen:
            seen.add(host)
            errors.append(
                f"ProviderCatalog 用了 {host}，OutboundHosts 没声明："
                "出站白名单会挡下它，而那个错看起来像「这家接口坏了」。"
            )


_CREDENTIAL_CALL_RE = re.compile(
    r"RequiredCredential\.value\(\s*\.([A-Za-z0-9_]+),\s*in:\s*credential,"
    r"\s*providerID:\s*\.([A-Za-z0-9_]+)"
)


def canonical_required_fields(text: str) -> dict[str, list[str]]:
    """每个 if/else 凭据链只取第一把。别名回落（try? 之后的 apiKey）不当成向导要问的字段。"""
    hits = [(m.start(), m.group(1), m.group(2)) for m in _CREDENTIAL_CALL_RE.finditer(text)]
    if not hits:
        return {}
    clusters: dict[str, list[list[str]]] = {}
    current_prov = hits[0][2]
    current = [hits[0][1]]
    last = hits[0][0]
    for pos, field, prov in hits[1:]:
        between = text[last:pos]
        new_chain = (
            prov != current_prov
            or (between.count("\n") > 6 and not re.search(r"\belse\b", between))
            or bool(re.search(r"\n\s*(?:let|var)\s+\w+", between) and not re.search(r"\belse\b", between))
        )
        if new_chain:
            clusters.setdefault(current_prov, []).append(current)
            current_prov = prov
            current = [field]
        elif field not in current:
            current.append(field)
        last = pos
    clusters.setdefault(current_prov, []).append(current)
    out: dict[str, list[str]] = {}
    for prov, chains in clusters.items():
        seen: set[str] = set()
        ordered: list[str] = []
        for chain in chains:
            head = chain[0]
            if head not in seen:
                seen.add(head)
                ordered.append(head)
        out[prov] = ordered
    return out


def check_billing_provider_clock(root: Path, errors: list[str]) -> None:
    """账单适配器不许自己 Date()。时间从 now 进来，否则单测里的钟对不上。"""
    providers = root / "Packages" / "MeterKit" / "Sources" / "MeterProviders"
    for path in sorted(providers.glob("*BillingProvider.swift")):
        masked = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        for index, line in enumerate(masked.splitlines(), 1):
            if re.search(r"\bDate\(\)", line):
                errors.append(
                    f"{rel(root, path)}:{index} 账单适配器里出现了 Date()。"
                    "时间从 now 参数进来。"
                )


def check_no_tracked_node_modules(root: Path, errors: list[str]) -> None:
    """node_modules 进 git 就等于把本机路径和依赖树提交进去。"""
    import subprocess

    listed = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "-z"],
        text=True,
    )
    for path in listed.split("\0"):
        if "node_modules" in path.split("/"):
            errors.append(f"{path} 被 git 跟踪了。node_modules 只能在 gitignore 里。")


def check_billing_url_is_a_page(root: Path, errors: list[str]) -> None:
    """billingURL 是人打开的账单页，不是 API 根。"""
    from urllib.parse import urlparse

    providers = root / "Packages" / "MeterKit" / "Sources" / "MeterProviders"
    text = (providers / "ProviderCatalog.swift").read_text(encoding="utf-8")
    for batch in sorted(providers.glob("ProviderCatalog+Batch*.swift")):
        text += "\n" + batch.read_text(encoding="utf-8")
    for match in re.finditer(
        r'colorKey:\s*"([^"]+)"[\s\S]*?billingURL:\s*URL\(string:\s*"(https?://[^"]+)"\)',
        text,
    ):
        key, url = match.group(1), match.group(2)
        parsed = urlparse(url)
        host = parsed.hostname or ""
        if host.startswith("api.") and parsed.path in ("", "/"):
            errors.append(
                f"{key} 的 billingURL 是 API 根 {url}，应是人打开的账单页"
            )


def check_credential_fields_match_guides(root: Path, errors: list[str]) -> None:
    """向导问的凭据字段，必须盖住取数真正要的那几个。

    这是 `ProviderCatalog` / 适配器和 `catalog.json` 之间**唯一真的双写**：
    同一家的「要哪几把钥匙」写在两个地方——

    - 适配器里 `RequiredCredential.value(.apiToken, …)`（取数真正要什么）；
    - `catalog.json` 教程的 `fields[].key`（向导问用户要什么）。

    对不上会怎样：教程少问一样，用户一路走完向导、连接测试却报「缺凭据」，
    而那句话指不出缺的是哪一把；教程多问一样，用户交出一把从来不用的密钥，
    它还会一直躺在 Keychain 里。两种都不是编译期能发现的，而且都发生在
    **第一次接入**——用户对这个 App 最没有耐心的那一刻。

    名字对齐靠 `CredentialField` 的 rawValue 就是 JSON 里的 `key`。
    """
    import json as _json

    providers = root / "Packages" / "MeterKit" / "Sources" / "MeterProviders"
    ids_text = gate_text(
        root, root / "Packages" / "MeterKit" / "Sources" / "MeterCore" / "ProviderID.swift", errors
    )
    guides_text = gate_text(
        root,
        root / "Packages" / "MeterKit" / "Sources" / "MeterPersistence" / "Catalog" / "catalog.json",
        errors,
    )
    if ids_text is None or guides_text is None:
        return
    name_to_raw = dict(
        re.findall(
            r'static let ([A-Za-z0-9_]+)\s*=\s*ProviderID\(rawValue:\s*"([^"]+)"\)',
            ids_text,
        )
    )
    guides = _json.loads(guides_text).get("guides", {})

    required: dict[str, set[str]] = {}
    for path in swift_files(providers):
        for provider, fields in canonical_required_fields(path.read_text(encoding="utf-8")).items():
            required.setdefault(provider, set()).update(fields)

    for provider, fields in sorted(required.items()):
        raw = name_to_raw.get(provider, provider)
        guide = guides.get(raw)
        if guide is None:
            errors.append(f"catalog.json 没有 {raw} 的接入说明，但它的适配器要凭据")
            continue
        asked = {
            field.get("key")
            for part in guide.get("parts", [])
            for field in part.get("fields", [])
        }
        for missing in sorted(fields - asked):
            errors.append(
                f"{raw} 的教程没问 {missing}，取数却要它："
                "用户走完向导会在连接测试那一步撞上「缺凭据」。"
            )


def check_device_transfer_coverage(root: Path, errors: list[str]) -> None:
    """落盘字段增减必须接到迁移包上，或写进「不装」名单。

    `quantity` 漏接就是因为载荷初始化参数有默认值，编译器不抱怨。
    """
    persistence = root / "Packages" / "MeterKit" / "Sources" / "MeterPersistence"
    container = persistence / "PersistenceContainer.swift"
    if not container.is_file():
        errors.append("找不到 PersistenceContainer.swift")
        return
    schema_match = SCHEMA_MODELS_RE.search(container.read_text(encoding="utf-8"))
    if not schema_match:
        errors.append("PersistenceContainer.schema 读不出模型名单")
        return
    actual_models = set(re.findall(r"(\w+)\.self", schema_match.group(1)))
    classified = set(TRANSFER_CARRIED_MODELS) | set(TRANSFER_OMITTED_MODELS)
    for name in sorted(actual_models - classified):
        errors.append(f"{name} 未分类：进迁移包还是像 Snapshot 一样不装？")
    for name in sorted(classified - actual_models):
        errors.append(f"名单里的 {name} 已经不在 Schema 里")

    core = "Packages/MeterKit/Sources/MeterCore"
    pers = "Packages/MeterKit/Sources/MeterPersistence"

    subscription = read_type_vars(root, f"{pers}/SubscriptionRecord.swift", "SubscriptionRecord", errors)
    if subscription is not None:
        field_gaps("SubscriptionRecord", subscription, SUBSCRIPTION_CARRIED, set(), errors)

    manual_usage = read_type_vars(root, f"{pers}/ManualUsageRecord.swift", "ManualUsageRecord", errors)
    if manual_usage is not None:
        field_gaps("ManualUsageRecord", manual_usage, MANUAL_USAGE_CARRIED, set(), errors)

    provider = read_type_vars(root, f"{pers}/ProviderConfigRecord.swift", "ProviderConfigRecord", errors)
    if provider is not None:
        field_gaps("ProviderConfigRecord", provider, PROVIDER_CONFIG_CARRIED, PROVIDER_CONFIG_OMITTED, errors)

    membership = read_type_vars(
        root, f"{pers}/ProviderMembershipRecord.swift", "ProviderMembershipRecord", errors
    )
    if membership is not None:
        field_gaps("ProviderMembershipRecord", membership, MEMBERSHIP_CARRIED, set(), errors)

    preferences = read_type_vars(root, f"{pers}/AppPreferencesRecord.swift", "AppPreferencesRecord", errors)
    if preferences is not None:
        field_gaps("AppPreferencesRecord", preferences, PREFERENCES_CARRIED, PREFERENCES_OMITTED, errors)

    mailbox = read_type_vars(root, f"{pers}/InboxMailboxStore.swift", "StoredInboxMailbox", errors)
    if mailbox is not None:
        field_gaps("StoredInboxMailbox", mailbox, MAILBOX_CARRIED, set(), errors)

    transfer_subscription = read_type_vars(
        root, f"{core}/TransferSubscription.swift", "TransferSubscription", errors
    )
    if transfer_subscription is not None:
        transfer_gaps(
            "TransferSubscription",
            transfer_subscription,
            set(SUBSCRIPTION_CARRIED.values()),
            errors,
        )

    transfer_manual = read_type_vars(
        root, f"{core}/TransferManualUsage.swift", "TransferManualUsage", errors
    )
    if transfer_manual is not None:
        transfer_gaps(
            "TransferManualUsage",
            transfer_manual,
            set(MANUAL_USAGE_CARRIED.values()),
            errors,
        )

    transfer_connection = read_type_vars(
        root, f"{core}/TransferConnection.swift", "TransferConnection", errors
    )
    if transfer_connection is not None:
        transfer_gaps(
            "TransferConnection",
            transfer_connection,
            set(PROVIDER_CONFIG_CARRIED.values()) | {"credentialFields"},
            errors,
        )

    transfer_preferences = read_type_vars(
        root, f"{core}/TransferPreferences.swift", "TransferPreferences", errors
    )
    if transfer_preferences is not None:
        transfer_gaps(
            "TransferPreferences",
            transfer_preferences,
            set(PREFERENCES_CARRIED.values()),
            errors,
        )

    transfer_mailbox = read_type_vars(root, f"{core}/TransferMailbox.swift", "TransferMailbox", errors)
    if transfer_mailbox is not None:
        transfer_gaps("TransferMailbox", transfer_mailbox, set(MAILBOX_CARRIED.values()), errors)

    transfer_payload = read_type_vars(root, f"{core}/TransferPayload.swift", "TransferPayload", errors)
    if transfer_payload is not None:
        transfer_gaps("TransferPayload", transfer_payload, PAYLOAD_FIELDS, errors)

    device_transfer = persistence / "DeviceTransfer.swift"
    if not device_transfer.is_file():
        errors.append("找不到 DeviceTransfer.swift")
        return
    masked = mask_comments_and_strings(device_transfer.read_text(encoding="utf-8"))
    identifiers = (
        set(SUBSCRIPTION_CARRIED.values())
        | set(PROVIDER_CONFIG_CARRIED.values())
        | set(MEMBERSHIP_CARRIED.values())
        | set(PREFERENCES_CARRIED.values())
        | set(MAILBOX_CARRIED.values())
        | set(MANUAL_USAGE_CARRIED.values())
        | PAYLOAD_FIELDS
        | {"credentialFields"}
    )
    for name in sorted(identifiers):
        if not re.search(rf"\b{re.escape(name)}\b", masked):
            errors.append(
                f"DeviceTransfer.swift 没有提到 {name}。collect / apply 要读写这个载荷字段。"
            )


MODULE_COUNT_RE = re.compile(r"\b\d+\s*(?:块模块|个模块|dashboard modules)\b")


def check_module_count_not_hardcoded(root: Path, errors: list[str]) -> None:
    """文档 / 注释里不许写死仪表盘模块有几块。

    写死过一次「12 块」，下架「即将扣款」之后三处全成了错的——而这种错
    没有任何一步会发现：编译过、测试绿、闸也不响，只有下一个读文档的人被骗一次。
    数量的唯一出处是 `DashboardModuleID` 的 case。

    这份闸自己要提这两种写法，所以跳过自己和记录这条修复的审视文档。
    """
    targets = [
        root / "ARCHITECTURE.md",
        root / "ARCHITECTURE.zh.md",
        root / "Packages" / "MeterKit" / "Package.swift",
        root / "docs" / "SPEC.md",
        root / "AGENTS.md",
    ]
    for path in targets:
        text = gate_text(root, path, errors)
        if text is None:
            continue
        for line in text.splitlines():
            if "提交闸扫" in line or "commit gate greps" in line:
                continue
            if MODULE_COUNT_RE.search(line):
                errors.append(
                    f"{rel(root, path)} 写死了模块数量：{line.strip()[:60]}。"
                    "数量归 DashboardModuleID，文档只说「模块」。"
                )


def check_copy_terms(root: Path, errors: list[str]) -> None:
    """用户可见文案和规格用词。钥匙叫凭据，不叫凭证。"""
    files: list[Path] = []
    for folder in COPY_TERM_FOLDERS:
        base = root / folder
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix not in COPY_TERM_SUFFIXES:
                continue
            if path.name in COPY_TERM_SKIP_NAMES:
                continue
            posix = path.as_posix()
            if "/.build/" in posix:
                continue
            files.append(path)
    for path in root.glob("*.md"):
        files.append(path)

    seen: set[Path] = set()
    for path in files:
        if path in seen:
            continue
        seen.add(path)
        text = path.read_text(encoding="utf-8")
        relative = rel(root, path)
        for forbidden, replacement in COPY_TERMS:
            for index, line in enumerate(text.splitlines(), 1):
                if forbidden in line:
                    errors.append(
                        f"{relative}:{index} 写「{replacement}」，不要写「{forbidden}」。"
                    )


def check_changelog(root: Path, errors: list[str]) -> None:
    """更新说明的接线没断。

    结构本身由 `generate-shared.py` 的 `verify_changelog` 验（红灯经
    `check_generated_shared` 报出来）。这里只管**跨文件**那几条：铺出去的四个
    消费者要真的还在读它，否则改了权威却没人用，闸也不会响。
    """
    wiring = (
        ("docs/RELEASE.md", "shared/changelog.json", "发布手册要写「在 changelog.json 顶上加一条」"),
        (
            "scripts/package-mac-release.sh",
            "appcast-notes",
            "Sparkle 的 <description> 要从 docs/release/appcast-notes/ 读",
        ),
        (
            ".github/workflows/release.yml",
            "docs/release/notes.md",
            "Release body 要拼上生成的更新说明",
        ),
    )
    for relative, needle, why in wiring:
        text = gate_text(root, root / relative, errors)
        if text is None:
            continue
        if needle not in text:
            errors.append(f"{relative} 少了 {needle}：{why}。")

    # 抽屉的判据是纯函数，不许在里头拿系统时间或版本号——测不了就会漂。
    launch = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Settings"
        / "WhatsNewLaunch.swift"
    )
    source = gate_text(root, launch, errors)
    if source is not None:
        # 注释里点名这三个词是**说明**，不是用法——不遮注释的话这道闸会咬自己。
        text = mask_comments_and_strings(source)
        for forbidden in ("Date()", "Bundle.main", "UserDefaults"):
            if forbidden in text:
                errors.append(
                    f"{rel(root, launch)} 不许出现 {forbidden}："
                    "弹不弹的判据要能从参数完全决定，否则测不住。"
                )


def check_generated_shared(root: Path, errors: list[str]) -> None:
    """shared/*.json 是唯一权威，生成物必须和它一致。

    手改生成物、或改了 shared 没跑生成器，这里红。修法：
    python3 scripts/generate-shared.py 然后把生成物一起提交。
    """
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "generate_shared", root / "scripts" / "generate-shared.py"
    )
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
        for path, content in module.outputs().items():
            rel = path.relative_to(root)
            if not path.is_file():
                errors.append(f"{rel}: 生成物缺失，跑 scripts/generate-shared.py")
            elif path.read_text(encoding="utf-8") != content:
                errors.append(f"{rel}: 和 shared/ 不一致，跑 scripts/generate-shared.py")
        # 位图生成物（hero.shot）按字节比：文本那条路读不了 PNG。
        for path, blob in module.binary_outputs().items():
            rel = path.relative_to(root)
            if not path.is_file():
                errors.append(f"{rel}: 生成物缺失，跑 scripts/generate-shared.py")
            elif path.read_bytes() != blob:
                errors.append(f"{rel}: 和 shared/ 不一致，跑 scripts/generate-shared.py")
    except SystemExit as exc:
        errors.append(f"generate-shared: {exc}")


def _check_generated_strings(
    root: Path,
    errors: list[str],
    script: str,
    label: str,
    gate_file: Path | None = None,
) -> None:
    """xcstrings 生成物一致性：Android values-xx 和 Windows resw 共用一套逻辑。"""
    if gate_file is not None and not gate_file.is_file():
        return
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        label.replace("-", "_"), root / "scripts" / script
    )
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
        result, gen_errors = module.outputs()
        errors.extend(f"{label}: {line}" for line in gen_errors)
        for path, content in result.items():
            rel_path = path.relative_to(root)
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                errors.append(f"{rel_path}: 和 xcstrings 不一致，跑 scripts/{script}")
    except SystemExit as exc:
        errors.append(f"{script.removesuffix('.py')}: {exc}")


def check_windows_strings(root: Path, errors: list[str]) -> None:
    """Windows 的 en-US / ja-JP resw 是 xcstrings 的生成物，必须一致。"""
    _check_generated_strings(
        root,
        errors,
        "generate-windows-strings.py",
        "windows-strings",
        gate_file=root / "Windows" / "app" / "Strings" / "zh-Hans" / "Resources.resw",
    )


def check_windows_no_http(root: Path, errors: list[str]) -> None:
    """C# 侧零网络请求。账单、反馈、匿名计数全部走 Swift 桥。"""
    folder = root / "Windows"
    if not folder.is_dir():
        return
    # 注意别在 HttpClient 后面加 \b：那样 HttpClientHandler 会漏网。
    banned = re.compile(
        r"\b(HttpClient|HttpRequestMessage|HttpListener|HttpWebRequest|WebRequest|WebClient|"
        r"SocketsHttpHandler|WinHttpHandler|TcpClient|UdpClient|Sockets\.Socket|"
        r"Windows\.Networking|Windows\.Web\.Http|System\.Net\.Http)"
    )
    for path in folder.rglob("*.cs"):
        posix = path.as_posix()
        if "/bin/" in posix or "/obj/" in posix:
            continue
        for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if banned.search(line):
                errors.append(
                    f"{rel(root, path)}:{index} C# 禁止直接发 HTTP。"
                    "走 MeterCoreNative / 桥。"
                )


def check_android_strings(root: Path, errors: list[str]) -> None:
    """Android 的 values-en / values-ja 是 xcstrings 的生成物，必须一致。"""
    _check_generated_strings(root, errors, "generate-android-strings.py", "android-strings")


# Swift `static let name: Type = value` ↔ Kotlin `const val NAME = value(f)`。
# 猫的动效曲线两端各自实现（平台渲染归属），但调参常数必须一致。
CAT_MOTION_SWIFT = "Packages/MeterKit/Sources/MeterDesign/CatMotionFrame.swift"
CAT_MOTION_KOTLIN = "Android/app/src/main/kotlin/com/zhechengqi/tollcat/ui/cat/CatMotion.kt"
CAT_MOTION_CSHARP = "Windows/app/Rendering/CatMotion.cs"

CAT_MOTION_SWIFT_RE = re.compile(
    r"static let (\w+)(?::\s*[\w.]+)? = (-?[\d.]+)\b"
)
CAT_MOTION_KOTLIN_RE = re.compile(r"const val ([A-Z0-9_]+) = (-?[\d.]+)f?\b")
CAT_MOTION_CSHARP_RE = re.compile(
    r"internal const (?:double|float) ([A-Z0-9_]+) = (-?[\d.]+)f?\b"
)


def _camel_to_screaming(name: str) -> str:
    spaced = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name)
    spaced = re.sub(r"(?<=[A-Z])(?=[A-Z][a-z])", "_", spaced)
    return spaced.upper()


def check_cat_motion_constants(root: Path, errors: list[str]) -> None:
    swift_file = root / CAT_MOTION_SWIFT
    kotlin_file = root / CAT_MOTION_KOTLIN
    if not swift_file.is_file() or not kotlin_file.is_file():
        errors.append("猫动效常数：CatMotionFrame.swift 或 CatMotion.kt 不在原位")
        return
    swift = {
        name: float(value)
        for name, value in CAT_MOTION_SWIFT_RE.findall(swift_file.read_text(encoding="utf-8"))
    }
    kotlin = {
        name: float(value)
        for name, value in CAT_MOTION_KOTLIN_RE.findall(kotlin_file.read_text(encoding="utf-8"))
    }
    csharp_file = root / CAT_MOTION_CSHARP
    csharp = {}
    if csharp_file.is_file():
        csharp = {
            name: float(value)
            for name, value in CAT_MOTION_CSHARP_RE.findall(csharp_file.read_text(encoding="utf-8"))
        }
    else:
        # ARCHITECTURE.md 说的是"三端手写、闸强制一致"：C# 文件挪走/改名
        # 不能让闸无声哑掉。
        errors.append(f"猫动效常数：缺 {CAT_MOTION_CSHARP}，三端一致闸罩不住 Windows。")
    for name, value in swift.items():
        kt_name = _camel_to_screaming(name)
        if kt_name not in kotlin:
            errors.append(f"猫动效常数 {name}: Kotlin 缺 {kt_name}（{CAT_MOTION_KOTLIN}）")
        elif abs(kotlin[kt_name] - value) > 1e-9:
            errors.append(
                f"猫动效常数漂移 {name}: Swift={value} Kotlin {kt_name}={kotlin[kt_name]}。两边一起改。"
            )
        if csharp_file.is_file():
            if kt_name not in csharp:
                errors.append(f"猫动效常数 {name}: C# 缺 {kt_name}（{CAT_MOTION_CSHARP}）")
            elif abs(csharp[kt_name] - value) > 1e-9:
                errors.append(
                    f"猫动效常数漂移 {name}: Swift={value} C# {kt_name}={csharp[kt_name]}。两边一起改。"
                )
    for kt_name in kotlin:
        if not any(_camel_to_screaming(name) == kt_name for name in swift):
            errors.append(f"猫动效常数 {kt_name}: Swift 侧没有对应（{CAT_MOTION_SWIFT}）")
    for cs_name in csharp:
        if not any(_camel_to_screaming(name) == cs_name for name in swift):
            errors.append(f"猫动效常数 {cs_name}: Swift 侧没有对应（{CAT_MOTION_SWIFT}）")


PACKAGE_TARGET_DEPS = {
    "MeterCore": frozenset(),
    "MeterDesign": frozenset(),
    "MeterFormat": frozenset({"MeterCore"}),
    "MeterProviders": frozenset({"MeterCore"}),
    "MeterPersistence": frozenset({"MeterCore"}),
    "MeterTips": frozenset(),
    "MeterInbox": frozenset({"MeterCore"}),
    "MeterFeedback": frozenset(),
    "MeterUsage": frozenset(),
    # 仪表盘模块的视图层。依赖表就是 widget 的安全说明书：
    # 加一条边就等于把那个 target 拖进 widget 扩展。
    "MeterModules": frozenset({"MeterCore", "MeterDesign", "MeterFormat"}),
    "MeterFeatures": frozenset(
        {
            "MeterCore",
            "MeterDesign",
            "MeterFormat",
            "MeterModules",
            "MeterProviders",
            "MeterPersistence",
            "MeterTips",
            "MeterInbox",
            "MeterFeedback",
            "MeterUsage",
        }
    ),
}

MATERIAL_RE = re.compile(
    r"\.(ultraThin|thin|regular|thick|ultraThick)Material\b"
)
WIDGET_PRODUCTS_RE = re.compile(
    r"^  TollCatWidget:\n(.*?)(?=^  [A-Za-z]|\Z)", re.M | re.S
)
APP_TARGET_RE = re.compile(r"^  TollCat:\n(.*?)(?=^  [A-Za-z]|\Z)", re.M | re.S)
WORKER_PATH_RE = re.compile(r'pathname === "(/v1/[^"]+)"')
SWIFT_TARGET_RE = re.compile(r"\.target\(")


def _matching_paren_block(text: str, open_index: int) -> str:
    depth = 0
    for i in range(open_index, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[open_index : i + 1]
    return text[open_index:]


def check_widget_module_list(root: Path, errors: list[str]) -> None:
    """widget 不许自己维护一份模块清单。

    主屏上的一格就是仪表盘上的一块：画什么由 `DashboardModuleFactory` 那一个 switch
    说了算，选单由 `DashboardModuleID.defaultOrder` 说了算。Widget/ 里一旦出现第二个
    模块名，就说明有人开始在这边另攒一份——那份迟早和仪表盘漂开，而且没有编译期信号。

    路由认两个名字：`DashboardModuleFactory` 直接调，或者经 `WidgetModuleTile`
    （那一块在 MeterModules 里，内部就是这个 factory；商店宣传图渲的是同一份视图）。

    和 `DashboardLayoutTests.widgetDoesNotKeepItsOwnModuleList` 同一条判据。
    """
    module_ids = re.findall(
        r"^    case (\w+)$",
        (
            root / "Packages/MeterKit/Sources/MeterModules/DashboardModuleID.swift"
        ).read_text(encoding="utf-8"),
        re.M,
    )
    if len(module_ids) < 5:
        errors.append("DashboardModuleID 解析不出模块清单")
        return
    mentioned: set[str] = set()
    uses_factory = False
    for path in swift_files(root / "Widget"):
        raw = path.read_text(encoding="utf-8")
        # 生成物例外：`TollCatWidgetBundle.swift` 一块模块一个 kind，本来就该点名，
        # 但它是从 `shared/widgets.json` 生成的，漂不了（generate-shared --check 守着）。
        if raw.lstrip().startswith(f"// {GENERATED_MARK}"):
            continue
        text = mask_comments_and_strings(raw)
        if "DashboardModuleFactory" in text or "WidgetModuleTile" in text:
            uses_factory = True
        for name in module_ids:
            # 裸的 `.monthToDate` 才算枚举 case；`store.subscriptions` 这种属性访问不算，
            # 所以点号前面不能是标识符字符。
            if re.search(rf"(?<![A-Za-z0-9_)\]])\.{name}\b", text) or (
                f"DashboardModuleID.{name}" in text
            ):
                mentioned.add(name)
    if not uses_factory:
        errors.append(
            "Widget 没走 DashboardModuleFactory / WidgetModuleTile：模块清单会漂成两份"
        )
    if len(mentioned) > 1:
        errors.append(
            "Widget 里出现了多个模块名（"
            + "、".join(sorted(mentioned))
            + "）：模块清单只许有一份，画什么交给 DashboardModuleFactory"
        )


def check_module_width_source(root: Path, errors: list[str]) -> None:
    """模块视图不许自己量宽度。

    宽度档（`ModuleWidth`）由容器声明——bento 行算得出卡宽、widget 有 widgetFamily、
    分享卡是定宽。模块自己量再据此改版式，是「量自身宽 → 改内容 → 内容改变理想宽」
    的反馈环：仪表盘实验室第一版就是这样把主线程转死的（12pt 一步涨到无限）。

    容器那一层量是允许的，所以这条只扫 MeterModules。
    """
    modules = root / "Packages" / "MeterKit" / "Sources" / "MeterModules"
    if not modules.is_dir():
        errors.append("找不到 MeterModules")
        return
    for path in swift_files(modules):
        text = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        for token in ("GeometryReader", "onGeometryChange"):
            if token in text:
                errors.append(
                    f"MeterModules/{path.name} 用了 {token}："
                    "模块不许自己量宽，档位由容器用 meterModuleStyle 声明"
                )


def check_package_graph(root: Path, errors: list[str]) -> None:
    path = root / "Packages" / "MeterKit" / "Package.swift"
    if not path.is_file():
        errors.append("找不到 Packages/MeterKit/Package.swift")
        return
    text = path.read_text(encoding="utf-8")
    if ".package(" in text:
        errors.append("Package.swift 引入了第三方包。这个项目不许第三方库。")
    found: set[str] = set()
    for match in SWIFT_TARGET_RE.finditer(text):
        block = _matching_paren_block(text, match.end() - 1)
        name_match = re.search(r'name:\s*"(\w+)"', block)
        if not name_match:
            continue
        name = name_match.group(1)
        found.add(name)
        deps_match = re.search(r"dependencies:\s*\[(.*?)\]", block, re.S)
        deps = set(re.findall(r'"(\w+)"', deps_match.group(1))) if deps_match else set()
        allowed = PACKAGE_TARGET_DEPS.get(name)
        if allowed is None:
            errors.append(f"Package.swift 多了 target {name}，先改架构合约")
            continue
        extra = deps - allowed
        missing = allowed - deps
        for item in sorted(extra):
            errors.append(f"Package.swift {name} 多了依赖 {item}")
        for item in sorted(missing):
            errors.append(f"Package.swift {name} 少了依赖 {item}")
    for name in sorted(set(PACKAGE_TARGET_DEPS) - found):
        errors.append(f"Package.swift 少了 target {name}")

    android = root / "Android" / "native" / "Package.swift"
    text = gate_text(root, android, errors)
    if text is not None and ".package(" in text:
        errors.append("Android/native/Package.swift 引入了第三方包")


def check_outbound_scope(root: Path, errors: list[str]) -> None:
    """关于页列的是「这个壳会连的」，不是「声明过的」。

    `OutboundHosts.all` 是全集（本仓库的出站脚本按它放行字面量），里面有只有
    Mac 直发版才会连的更新通道。关于页读 `all` 就会在 iPhone 上列出一支这台
    设备永远不会连的域名——那张表是给用户看的承诺，不能宽。
    """
    about = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Settings"
        / "AboutView.swift"
    )
    if not about.is_file():
        errors.append("找不到 AboutView.swift")
        return
    text = mask_comments_and_strings(about.read_text(encoding="utf-8"))
    if "OutboundHosts.visible" not in text:
        errors.append("AboutView 要列 OutboundHosts.visible（按壳过滤），不是 all")
    if "OutboundHosts.all" in text:
        errors.append("AboutView 列了 OutboundHosts.all：会把只有 Mac 会连的域名摆到 iPhone 上")


def check_project_yml_linkage(root: Path, errors: list[str]) -> None:
    path = root / "project.yml"
    if not path.is_file():
        errors.append("找不到 project.yml")
        return
    text = path.read_text(encoding="utf-8")
    widget = WIDGET_PRODUCTS_RE.search(text)
    if widget is None:
        errors.append("project.yml 读不出 TollCatWidget")
    elif "MeterProviders" in widget.group(1):
        errors.append(
            "TollCatWidget 链了 MeterProviders。SPEC 第 09 节：Widget 不能自己调 API。"
        )
    app = APP_TARGET_RE.search(text)
    if app is None:
        errors.append("project.yml 读不出 TollCat target")
    elif re.search(r"^\s*- sdk: StoreKitTest\.framework", app.group(1), re.M):
        errors.append(
            "App target 链了 StoreKitTest.framework。真机启动会 SIGABRT。"
        )

    for swift in swift_files(root / "Widget"):
        if "import MeterProviders" in swift.read_text(encoding="utf-8"):
            errors.append(f"Widget/{swift.name} import MeterProviders")

    check_xcode_specs(root, errors)


def check_xcode_specs(root: Path, errors: list[str]) -> None:
    """两份 spec 的分工：第三方包只准出现在 Mac 那一份。

    SPM 的包解析是工程级的：Sparkle 只要写进 iOS 那份 spec，
    `xcodebuild -scheme TollCat` 也会先 fetch / checkout 一遍它永远不链的东西
    ——离线构建会卡在跟 iOS 无关的第三方包上。所以 Mac 壳自己一份工程。
    """
    mac = root / "project-mac.yml"
    common = root / "project-common.yml"
    for path in (mac, common):
        if not path.is_file():
            errors.append(f"找不到 {path.name}")
            return

    for path in (root / "project.yml", common):
        text = path.read_text(encoding="utf-8")
        if re.search(r"^\s+url: https://", text, re.M):
            errors.append(
                f"{path.name} 里有远程 package。第三方只准进 project-mac.yml，"
                "否则 iOS 构建也要解析它。"
            )
        if re.search(r"^\s*Sparkle:", text, re.M):
            errors.append(f"{path.name} 里出现 Sparkle。它只属于 project-mac.yml。")

    mac_text = mac.read_text(encoding="utf-8")
    if not re.search(r"^\s*Sparkle:", mac_text, re.M):
        errors.append("project-mac.yml 里没有 Sparkle：Mac 直发版的自动更新靠它")
    mac_widget = re.search(
        r"^  TollCatWidgetMac:\n(.*?)(?=^  [A-Za-z]|\Z)", mac_text, re.M | re.S
    )
    if mac_widget is None:
        errors.append("project-mac.yml 读不出 TollCatWidgetMac")
    elif "MeterProviders" in mac_widget.group(1):
        errors.append(
            "TollCatWidgetMac 链了 MeterProviders。SPEC 第 09 节：Widget 不能自己调 API。"
        )
    if "include:" not in mac_text or "project-common.yml" not in mac_text:
        errors.append("project-mac.yml 要 include project-common.yml，团队 ID 和版本号只有一处")

    # 两份工程引用同一个本地包，分别打开会互相抢（后开的报 Missing package product）。
    # workspace 是唯一能让它们同时开着的方式，列漏一个就等于没有。
    workspace = root / "TollCat.xcworkspace" / "contents.xcworkspacedata"
    if not workspace.is_file():
        errors.append("找不到 TollCat.xcworkspace：Xcode 里同时开两份工程要靠它")
        return
    workspace_text = workspace.read_text(encoding="utf-8")
    for ref in ("TollCat.xcodeproj", "TollCatMac.xcodeproj", "Packages/MeterKit"):
        if ref not in workspace_text:
            errors.append(f"TollCat.xcworkspace 少了 {ref}：两份工程会抢同一个本地包")


def check_keychain_and_transfer(root: Path, errors: list[str]) -> None:
    keychain = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterPersistence"
        / "KeychainCredentialStore.swift"
    )
    if not keychain.is_file():
        errors.append("找不到 KeychainCredentialStore.swift")
    else:
        text = keychain.read_text(encoding="utf-8")
        if "kSecAttrAccessibleWhenUnlockedThisDeviceOnly" not in text:
            errors.append(
                "KeychainCredentialStore 必须用 WhenUnlockedThisDeviceOnly"
            )
        if re.search(r"kSecAttrAccessibleWhenUnlocked\b(?!ThisDeviceOnly)", text):
            errors.append("Keychain 不能用 WhenUnlocked（会进备份）")
        if "kSecAttrAccessibleAfterFirstUnlock" in text:
            errors.append("Keychain 不能用 AfterFirstUnlock")
        if re.search(r"kSecAttrSynchronizable[^\n]*kCFBooleanTrue", text):
            errors.append("Keychain 不能开 Synchronizable")

    store = (
        root
        / "Android"
        / "app"
        / "src"
        / "main"
        / "kotlin"
        / "com"
        / "zhechengqi"
        / "tollcat"
        / "AndroidKeystoreCredentialStore.kt"
    )
    text = gate_text(root, store, errors)
    if text is not None:
        if "setUnlockedDeviceRequired(true)" not in text:
            errors.append(
                "Android Keystore 必须 setUnlockedDeviceRequired(true)，对齐 ThisDeviceOnly"
            )

    code = root / "Packages" / "MeterKit" / "Sources" / "MeterCore" / "TransferCode.swift"
    if not code.is_file():
        errors.append("找不到 TransferCode.swift")
    elif not re.search(r"static let characterCount = 10\b", code.read_text(encoding="utf-8")):
        errors.append("TransferCode.characterCount 必须是 10（约 50 bit）")

    deriver = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterPersistence"
        / "TransferKeyDeriver.swift"
    )
    if not deriver.is_file():
        errors.append("找不到 TransferKeyDeriver.swift")
    else:
        text = deriver.read_text(encoding="utf-8")
        if not re.search(r"static let iterationCount = 600_000\b", text):
            errors.append("PBKDF2 iterationCount 必须是 600_000")
        if not re.search(r"static let minimumIterationCount = 600_000\b", text):
            errors.append("PBKDF2 minimumIterationCount 必须是 600_000")
        if re.search(r"\bHKDF\b", mask_comments_and_strings(text)):
            errors.append("转移密钥派生不许用 HKDF，必须是 PBKDF2")


def check_launch_arguments_are_debug_only(root: Path, errors: list[str]) -> None:
    """验收用的启动参数不许在 Release 生效。

    Mac 是直发的：`open -a TollCat --args -meter-refresh-bump` 能让每次刷新给金额
    加一笔假的增量，`-stub-inbox` 能把读数信箱换成 stub，`-open-developer` 能在
    正式包里推出开发页。这些钩子只服务模拟器验收，而截图和冒烟脚本全是 Debug 构建。

    判据只有一处：`arguments` 那个入口本身。下面几十个开关不必各自防一遍，
    但**这一处不能被绕开**——别处再读一次 `ProcessInfo.processInfo.arguments`
    就等于把这道闸拆了。
    """
    path = (
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures"
        / "FeatureLaunchArguments.swift"
    )
    text = gate_text(root, path, errors)
    if text is not None:
        entry = text.split("public static var arguments")[-1].split("}")[0]
        if "#if DEBUG" not in entry:
            errors.append(
                f"{rel(root, path)} 的 arguments 必须 `#if DEBUG` 才读 ProcessInfo，"
                "否则直发的 Mac 版能用 --args 打开验收钩子。"
            )

    for source in scan_app_widget_sources(root):
        if source.as_posix().endswith("/MeterFeatures/FeatureLaunchArguments.swift"):
            continue
        masked = mask_comments_and_strings(source.read_text(encoding="utf-8"))
        if "ProcessInfo.processInfo.arguments" in masked:
            errors.append(
                f"{rel(root, source)} 直接读了启动参数。"
                "统一走 FeatureLaunchArguments——它在 Release 里是空的。"
            )


AMBIENT_DATE_FORMAT_RE = re.compile(r"\.formatted\(\s*\.dateTime")


def check_dates_use_injected_calendar(root: Path, errors: list[str]) -> None:
    """日期排版一律走 `MeterDateFormat`，不许 `Date.formatted(.dateTime…)`。

    `Date.formatted` 用的是**系统**日历和时区，而这个 App 的折算按注入的那本切月
    切日。两者不一致的时候（测试注入 UTC、Widget 另开进程、用户刚换时区），
    月末最后一天会印成下个月 1 号——数字对、字错，而且只在边界值上错。
    `MeterDateFormat` 存在就是为了这件事：它把 calendar 的时区一起交给 formatter。

    同理 `Calendar.current`：Modules 是纯折算层，日历必须从参数进来。
    """
    for path in scan_app_widget_sources(root):
        posix = path.as_posix()
        if "/Sources/MeterFormat/" in posix:
            continue
        masked = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        if AMBIENT_DATE_FORMAT_RE.search(masked):
            errors.append(
                f"{rel(root, path)} 用了 Date.formatted(.dateTime…)，那是系统时区。"
                "日期排版走 MeterDateFormat，把注入的 calendar 交给它。"
            )
        if "/Sources/MeterModules/" in posix and "Calendar.current" in masked:
            errors.append(
                f"{rel(root, path)} 出现 Calendar.current。"
                "Modules 是折算层，日历必须从参数进来。"
            )


def check_shell_forks(root: Path, errors: list[str]) -> None:
    """「哪一种壳」只有一个出处，而且 `#if os` 只留给 API 可用性。

    以前只有一个 `usesPadChrome: Bool`，Mac 恒 true。于是「只有 Mac」这个问题
    在展示层根本问不出来，只能写 `#if os(macOS)`——一个纯粹的版式选择就变成
    编译期分叉，而编译期分叉的代价是另一边的代码根本不参与编译。
    现在壳是一个值（`MeterDesign/MeterShell.swift`），宽版式从它派生。

    两条机械判据：

    - **`MeterModules` 一处 `#if os` 都不许有。**那一层收的是已经算好的值，
      没有任何平台 API，出现 `#if os` 说明版式判断漏到了折算层。
    - **平台默认壳只在 `MeterShell.swift` 里算。**别处再写一遍
      `#if os(macOS) true #else false` 就是第二个出处，两边迟早不一致。
    """
    for path in swift_files(root / "Packages" / "MeterKit" / "Sources" / "MeterModules"):
        if "#if os(" in mask_comments_and_strings(path.read_text(encoding="utf-8")):
            errors.append(
                f"{rel(root, path)} 出现 #if os。模块层收的是算好的值，"
                "版式分岔走 MeterShell（环境值），不在这一层判平台。"
            )

    # 只扫展示层。`OutboundHost.isActiveHere` 那种「当前编译目标会不会连这个域名」
    # 问的不是壳，是构建目标，和版式无关。
    sources = root / "Packages" / "MeterKit" / "Sources"
    for folder in ("MeterFeatures", "MeterModules"):
        for path in swift_files(sources / folder):
            masked = mask_comments_and_strings(path.read_text(encoding="utf-8"))
            if "MeterShell.platformDefault" in masked:
                continue
            if re.search(r"#if os\(macOS\)\s*\n\s*true\s*\n\s*#else\s*\n\s*false", masked):
                errors.append(
                    f"{rel(root, path)} 自己判了一遍「是不是 Mac 壳」。"
                    "唯一出处是 MeterShell.platformDefault。"
                )
            # 版式分叉不许躲在 `#if os` 里：Mac 列内手工栈（`MacColumnStack` 及它的
            # push/pop）两个平台都能编，该问的是「壳是不是 .mac」，不是「编给谁」。
            # 编译期分叉的代价是另一边的代码根本不参与编译，改错了要等切平台才知道。
            for block in re.finditer(r"#if\s+!?os\([^)]*\)(.*?)#endif", masked, re.S):
                body = block.group(1)
                if re.search(r"\bMacColumnStack\(|\bmac(?:Detail)?Stack\.(?:push|pop|popToRoot)\b|\bpadSplit\b", body):
                    line = masked.count("\n", 0, block.start()) + 1
                    errors.append(
                        f"{rel(root, path)}:{line} #if os 里包着版式分叉（Mac 列内手工栈）。"
                        "这不是 API 可用性——问 meterShell == .mac，让两条路都参与编译。"
                    )


def check_session_and_stubs(root: Path, errors: list[str]) -> None:
    for path in scan_app_widget_sources(root):
        original = path.read_text(encoding="utf-8")
        masked = mask_comments_and_strings(original)
        posix = rel(root, path)
        if "URLSession.shared" in masked or re.search(
            r"URLSession\s*=\s*\.shared", masked
        ):
            errors.append(f"{posix} 用了 URLSession.shared。生产会话必须 ephemeral + 重定向白名单。")
        if MATERIAL_RE.search(masked):
            errors.append(f"{posix} 手搓了 Material 玻璃。玻璃只许系统导航层。")
        if "≈" in masked:
            errors.append(f"{posix} 含 ≈。金额格式化不许再标约等。")
        if "import ActivityKit" in original or "registerForRemoteNotifications" in masked:
            errors.append(f"{posix} 接了远程推送或 Live Activity")
        if "MockBillingProvider" in masked:
            errors.append(f"{posix} 出现 MockBillingProvider")

    for path in scan_app_widget_sources(root):
        posix = path.as_posix()
        if not any(posix.endswith(suffix) for suffix in URLSESSION_ALLOWED):
            continue
        text = path.read_text(encoding="utf-8")
        if "URLSession(" in text and "delegate:" not in text:
            errors.append(
                f"{rel(root, path)} 建了 URLSession 却没有 delegate。"
                "重定向必须再过一次 host 白名单。"
            )

    production_kt = root / "Android" / "app" / "src" / "main" / "kotlin"
    for path in sorted(production_kt.rglob("*.kt")) if production_kt.is_dir() else []:
        if "/build/" in path.as_posix():
            continue
        text = path.read_text(encoding="utf-8")
        relative = rel(root, path)
        if path.name == "Proof.kt":
            continue
        if "useStub" in text or "usedStub" in text:
            errors.append(f"{relative} 有运行时 stub 开关。生产取数必须走真 HTTP。")
        if "MockBillingProvider" in text:
            errors.append(f"{relative} 出现 MockBillingProvider")
        if MATERIAL_RE.search(text):
            errors.append(f"{relative} 手搓了 Material 玻璃")

    for folder in (
        root / "Android" / "native" / "Sources" / "MeterCoreJNI",
        root / "Android" / "native" / "Sources" / "MeterBridge",
        root / "Windows" / "native" / "Sources" / "MeterCoreCLR",
    ):
        if not folder.is_dir():
            continue
        for path in swift_files(folder):
            if path.name in {"AndroidProof.swift"}:
                continue
            text = path.read_text(encoding="utf-8")
            if re.search(r"\buseStub\b", mask_comments_and_strings(text)):
                errors.append(f"{rel(root, path)} 桥取数口带了 useStub")
            if "PathFixtureHTTPClient" in text:
                errors.append(f"{rel(root, path)} 生产取数口还挂着 PathFixtureHTTPClient")

    for path in (production_kt.rglob("*.kt") if production_kt.is_dir() else []):
        if path.name not in {"FeedbackClient.kt", "UsageAnalytics.kt"}:
            continue
        text = path.read_text(encoding="utf-8")
        via_bridge = "postFeedbackJson" in text or "postUsageJson" in text
        if via_bridge:
            continue
        if "instanceFollowRedirects = false" not in text:
            errors.append(
                f"{rel(root, path)} POST 必须走桥（postFeedbackJson / postUsageJson）"
                "或关掉跟随重定向"
            )


# ─────────────────────────────────────────────────────────────
# 迁移包信封的常数三端一致（和猫动效那道闸同一条路子）。
#
# `.tollcat` 的头是**两份手写的实现**在读同一段字节：Apple 侧
# `TransferFileFormat` + `TransferKeyDeriver`，Android 侧 `DeviceTransfer.kt` 的
# javax.crypto。任何一个数字对不上，导出的包在另一台设备上就打不开——而且不会
# 在编译期、也不会在单测里露头，只会在用户换机那天。
#
# 只核数字，不核算法：算法各平台走系统实现，那本来就该各写各的。
TRANSFER_ENVELOPE_SWIFT_FORMAT = "Packages/MeterKit/Sources/MeterPersistence/TransferFileFormat.swift"
TRANSFER_ENVELOPE_SWIFT_KDF = "Packages/MeterKit/Sources/MeterPersistence/TransferKeyDeriver.swift"
TRANSFER_ENVELOPE_SWIFT_LIFETIME = "Packages/MeterKit/Sources/MeterPersistence/TransferLifetime.swift"
TRANSFER_ENVELOPE_SWIFT_CODE = "Packages/MeterKit/Sources/MeterCore/TransferCode.swift"
TRANSFER_ENVELOPE_KOTLIN = (
    "Android/app/src/main/kotlin/com/zhechengqi/tollcat/settings/DeviceTransfer.kt"
)


def check_transfer_envelope(root: Path, errors: list[str]) -> None:
    def read(relative: str) -> str | None:
        path = root / relative
        if not path.is_file():
            errors.append(f"迁移信封：缺 {relative}，三端一致闸罩不住")
            return None
        return path.read_text(encoding="utf-8")

    swift_format = read(TRANSFER_ENVELOPE_SWIFT_FORMAT)
    swift_kdf = read(TRANSFER_ENVELOPE_SWIFT_KDF)
    swift_lifetime = read(TRANSFER_ENVELOPE_SWIFT_LIFETIME)
    swift_code = read(TRANSFER_ENVELOPE_SWIFT_CODE)
    kotlin = read(TRANSFER_ENVELOPE_KOTLIN)
    if None in (swift_format, swift_kdf, swift_lifetime, swift_code, kotlin):
        return

    def swift_int(text: str, name: str) -> int | None:
        match = re.search(rf"static let {name}[^=]*=\s*([0-9_]+)", text)
        return int(match.group(1).replace("_", "")) if match else None

    def kotlin_int(name: str) -> int | None:
        match = re.search(rf"const val {name}[^=]*=\s*([0-9_]+)", kotlin)
        return int(match.group(1).replace("_", "")) if match else None

    # (人话名字, Swift 源文件里的常量, Swift 文本, Kotlin 常量)
    pairs = [
        ("格式版本", "version", swift_format, "VERSION"),
        ("salt 长度", "saltByteCount", swift_format, "SALT_LEN"),
        ("nonce 长度", "nonceByteCount", swift_format, "NONCE_LEN"),
        ("tag 长度", "tagByteCount", swift_format, "TAG_LEN"),
        ("PBKDF2 迭代数", "iterationCount", swift_kdf, "ITERATIONS"),
        ("PBKDF2 迭代下限", "minimumIterationCount", swift_kdf, "MIN_ITER"),
        ("PBKDF2 迭代上限", "maximumIterationCount", swift_kdf, "MAX_ITER"),
        ("派生密钥长度", "keyByteCount", swift_kdf, "KEY_LEN"),
        ("转移码位数", "characterCount", swift_code, "CODE_LENGTH"),
    ]
    for label, swift_name, text, kotlin_name in pairs:
        expected = swift_int(text, swift_name)
        actual = kotlin_int(kotlin_name)
        if expected is None:
            errors.append(f"迁移信封 {label}：Swift 侧读不到 {swift_name}")
            continue
        if actual is None:
            errors.append(f"迁移信封 {label}：Kotlin 缺 {kotlin_name}（{TRANSFER_ENVELOPE_KOTLIN}）")
        elif actual != expected:
            errors.append(
                f"迁移信封漂移 {label}：Swift {swift_name}={expected} "
                f"Kotlin {kotlin_name}={actual}。两边一起改，否则换机包打不开。"
            )

    # 头长度 = 4 + 1 + 16 + 4 + 12 + 8，Kotlin 写成算式，这里按值比。
    header = re.search(r"const val HEADER_LEN\s*=\s*([0-9 +]+)", kotlin)
    if header is None:
        errors.append(f"迁移信封：Kotlin 缺 HEADER_LEN（{TRANSFER_ENVELOPE_KOTLIN}）")
    else:
        actual_header = sum(int(part) for part in header.group(1).split("+"))
        magic = swift_int(swift_format, "magicByteCount") or 0
        version_bytes = swift_int(swift_format, "versionByteCount") or 0
        salt = swift_int(swift_format, "saltByteCount") or 0
        iterations = swift_int(swift_format, "iterationsByteCount") or 0
        nonce = swift_int(swift_format, "nonceByteCount") or 0
        not_after = swift_int(swift_format, "notAfterByteCount") or 0
        expected_header = magic + version_bytes + salt + iterations + nonce + not_after
        if actual_header != expected_header:
            errors.append(
                f"迁移信封漂移 头长度：Swift={expected_header} Kotlin HEADER_LEN={actual_header}"
            )

    # 有效期：Swift 写秒，Kotlin 写毫秒。
    lifetime = re.search(r"duration: TimeInterval = ([0-9 *]+)", swift_lifetime)
    kotlin_lifetime = re.search(r"const val LIFETIME_MS\s*=\s*([0-9L *]+)", kotlin)
    if lifetime and kotlin_lifetime:
        expected_seconds = eval(lifetime.group(1))  # noqa: S307 — 表达式来自本仓库源码
        actual_ms = eval(kotlin_lifetime.group(1).replace("L", ""))  # noqa: S307
        if actual_ms != expected_seconds * 1000:
            errors.append(
                f"迁移信封漂移 有效期：Swift={expected_seconds}s Kotlin={actual_ms}ms"
            )

    if '"TOLL"' not in kotlin:
        errors.append(f"迁移信封：Kotlin 的 MAGIC 不是 \"TOLL\"（{TRANSFER_ENVELOPE_KOTLIN}）")


# ─────────────────────────────────────────────────────────────
# 平台皮不许自己发 HTTP。
#
# 四条 worker 出口（反馈 / 匿名计数 / 打赏留言 / 读数信箱）的 URL 编在
# `MeterBridge/ProductWorker` 和 `ProductInbox` 里，出站闸自动覆盖。这道闸原来
# 只按文件名认两个文件——新写的 `TipMessageClient.kt` 自带一个 `HttpURLConnection`
# 就绕过去了。改成扫整棵 Kotlin 树。
def check_kotlin_has_no_http(root: Path, errors: list[str]) -> None:
    kotlin_root = root / "Android/app/src/main/kotlin"
    if not kotlin_root.is_dir():
        return
    for path in sorted(kotlin_root.rglob("*.kt")):
        text = path.read_text(encoding="utf-8")
        if "HttpURLConnection" in text or "okhttp3" in text:
            errors.append(
                f"{rel(root, path)} 自己发 HTTP——出口要编在桥上"
                "（MeterBridge/ProductWorker、ProductInbox），这一端只递 JSON"
            )


def check_jni_schema(root: Path, errors: list[str]) -> None:
    swift = (
        root / "Android" / "native" / "Sources" / "MeterBridge" / "BridgeJSON.swift"
    )
    kotlin = (
        root
        / "Android"
        / "app"
        / "src"
        / "main"
        / "kotlin"
        / "com"
        / "zhechengqi"
        / "tollcat"
        / "CatalogModels.kt"
    )
    if not swift.is_file() or not kotlin.is_file():
        errors.append("JNI schema 文件不在原位")
        return
    swift_match = re.search(r"static let version = (\d+)", swift.read_text(encoding="utf-8"))
    kotlin_match = re.search(
        r"EXPECTED_JNI_SCHEMA = (\d+)", kotlin.read_text(encoding="utf-8")
    )
    if not swift_match or not kotlin_match:
        errors.append("读不出 JNISchema.version / EXPECTED_JNI_SCHEMA")
        return
    csharp = root / "Windows" / "app" / "Models" / "CatalogModels.cs"
    csharp_text = gate_text(root, csharp, errors)
    csharp_match = (
        re.search(r"EXPECTED_JNI_SCHEMA = (\d+)", csharp_text)
        if csharp_text is not None
        else None
    )
    if swift_match.group(1) != kotlin_match.group(1):
        errors.append(
            f"JNI schema 漂移：Swift={swift_match.group(1)} Kotlin={kotlin_match.group(1)}"
        )
    if csharp_match and csharp_match.group(1) != swift_match.group(1):
        errors.append(
            f"JNI schema 漂移：Swift={swift_match.group(1)} C#={csharp_match.group(1)}"
        )


WORKER_ALLOWED_PATHS = {
    "/v1/tip",
    "/v1/feedback",
    "/v1/catalog",
    "/v1/usage",
    "/v1/inbox",
    "/v1/readings",
}


def check_worker_boundaries(root: Path, errors: list[str]) -> None:
    src = root / "worker" / "src"
    index = src / "index.ts"
    if not index.is_file():
        errors.append("找不到 worker/src/index.ts")
        return
    index_text = index.read_text(encoding="utf-8")
    for path in WORKER_PATH_RE.findall(index_text):
        if path not in WORKER_ALLOWED_PATHS:
            errors.append(f"worker 多了路由 {path}。加 endpoint 先改 SPEC 第 12.5 节。")

    http = src / "http.ts"
    text = gate_text(root, http, errors)
    if text is not None:
        if "MAX_BODY_BYTES = 8 * 1024" not in text and "MAX_BODY_BYTES = 8192" not in text:
            errors.append("worker http.ts MAX_BODY_BYTES 必须是 8KiB")
        if "content-type must be application/json" not in text:
            errors.append("worker 必须卡住 application/json，否则跨站表单能烧建箱配额")
        if "function requireJSONContentType" not in text:
            errors.append("worker 缺少 requireJSONContentType")

    inbox = src / "inbox.ts"
    text = gate_text(root, inbox, errors)
    if text is not None and "requireJSONContentType" not in text:
        errors.append("POST /v1/inbox 必须 requireJSONContentType")
    for name in ("tip.ts", "feedback.ts", "usage.ts"):
        path = src / name
        text = gate_text(root, path, errors)
        if text is not None and "guardedPostBody" not in text:
            errors.append(f"worker/{name} POST 必须走 guardedPostBody")

    fetch_re = re.compile(r"(?<!async )(?<!function )\bfetch\s*\(")
    for path in sorted(src.glob("*.ts")):
        if path.name == "worker-configuration.d.ts":
            continue
        masked = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        if fetch_re.search(masked):
            errors.append(
                f"worker/src/{path.name} 调用了 fetch(。"
                "Worker 不许代理任何 provider API。"
            )


def check_plain_http(root: Path, errors: list[str]) -> None:
    folders = (
        root / "App",
        root / "Widget",
        root / "Packages" / "MeterKit" / "Sources",
        root / "Android" / "app" / "src" / "main",
        root / "Android" / "native" / "Sources",
        root / "Windows",
    )
    for folder in folders:
        if not folder.is_dir():
            continue
        for path in folder.rglob("*"):
            if not path.is_file() or path.suffix not in {".swift", ".kt", ".cs"}:
                continue
            posix = path.as_posix()
            # /bin/ /obj/ 是 dotnet build 的产物（含 CsWinRT 生成源），跟
            # check_windows_no_http 用同一套跳过规则，否则本地构建后闸变慢又误报。
            if "/build/" in posix or "/.build/" in posix or "/bin/" in posix or "/obj/" in posix:
                continue
            for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if "http://" in line and "xmlns" not in line:
                    errors.append(f"{rel(root, path)}:{index} 明文 http://")


def main() -> int:
    root = repo_root()
    errors: list[str] = []
    check_leaf_imports(root, errors)
    check_network_surface(root, errors)
    check_filter_scope(root, errors)
    check_ledger_boundary(root, errors)
    check_ledger_read_not_swallowed(root, errors)
    check_persistence_contract(root, errors)
    check_catalog_sync(root, errors)
    check_catalog_copyables(root, errors)
    check_declined_providers(root, errors)
    check_provider_wiring(root, errors)
    check_credential_fields_match_guides(root, errors)
    check_billing_provider_clock(root, errors)
    check_no_tracked_node_modules(root, errors)
    check_billing_url_is_a_page(root, errors)
    check_device_transfer_coverage(root, errors)
    check_copy_terms(root, errors)
    check_module_count_not_hardcoded(root, errors)
    check_changelog(root, errors)
    check_generated_shared(root, errors)
    check_android_strings(root, errors)
    check_windows_strings(root, errors)
    check_windows_no_http(root, errors)
    check_cat_motion_constants(root, errors)
    check_module_width_source(root, errors)
    check_widget_module_list(root, errors)
    check_package_graph(root, errors)
    check_outbound_scope(root, errors)
    check_project_yml_linkage(root, errors)
    check_keychain_and_transfer(root, errors)
    check_launch_arguments_are_debug_only(root, errors)
    check_dates_use_injected_calendar(root, errors)
    check_shell_forks(root, errors)
    check_session_and_stubs(root, errors)
    check_jni_schema(root, errors)
    check_transfer_envelope(root, errors)
    check_kotlin_has_no_http(root, errors)
    check_worker_boundaries(root, errors)
    check_plain_http(root, errors)

    if errors:
        print(f"check-source-invariants: {len(errors)} 处越界:", file=sys.stderr)
        for line in errors:
            print(f"  {line}", file=sys.stderr)
        print(
            "这些是架构禁令，不是风格偏好。"
            "要扩大名单，先改对应 Isolation / Scope 测试和本脚本。",
            file=sys.stderr,
        )
        return 1

    print("check-source-invariants: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
