#!/usr/bin/env python3
"""版式规范的静态扫描。**和架构禁令分开一个文件。**

这六条（列表行热区、主操作栏、键盘收起、sheet 关闭、抽屉 chrome、下拉刷新）
是**设计规范**，不是架构禁令：违反它们的代码能跑、能出对的数字，只是长得不对。
它们以前和「模块不许 import Providers」「快照日志不许漏进展示层」挤在同一个
2500 行的文件里，那让那个文件变成了它自己想防的东西——一个只有作者敢改的巨块，
而且把「越界即红」和「这里应该更好看」混成了同一句话。

对应的 Swift 镜像测试：
- ListRowHitTargetGuardrailTests
- PrimaryActionBarGuardrailTests
- KeyboardDismissGuardrailTests
- SheetCloseGuardrailTests
- DrawerChromeGuardrailTests
- RefreshableGuardrailTests

判据改了两边一起改。词法（抹注释和字符串）在 `_swift_scan.py`，两个脚本共用。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _swift_scan import (  # noqa: E402
    CONTROL_RE,
    gate_text,
    last_control_start,
    mask_comments_and_strings,
    rel,
    repo_root,
    scan_app_widget_sources,
    swift_files,
)

PLAIN_STYLE_RE = re.compile(r"\.buttonStyle\(\s*\.plain\s*\)")
ROW_SHAPE_RE = re.compile(
    r"\bSpacer\b|\bLabeledContent\b|\bProviderRow\b|"
    r"\bManualSubscriptionRow\b|\bCompositionModuleView\b|"
    r"chevron\.right|\browContent\b"
)
EXPANDED_RE = re.compile(r"maxWidth:\s*\.infinity")
HIT_TARGET = "meterListRowHitTarget("
CONTENT_SHAPE = "contentShape(Rectangle())"
BOTTOM_INSET_RE = re.compile(r"\.safeArea(?:Inset|Bar)\(\s*edge:\s*\.bottom")



def check_plain_list_row_hit_targets(root: Path, errors: list[str]) -> None:
    """`.plain` 把热区缩成不透明子视图。列表行（有 Spacer / 行组件 / 撑满宽）
    必须在 label 上铺 `meterListRowHitTarget()`，否则点空白没反应。
    """
    skip_suffix = "/ListRowHitTarget.swift"
    for path in scan_app_widget_sources(root):
        if path.as_posix().endswith(skip_suffix):
            continue
        original = path.read_text(encoding="utf-8")
        masked = mask_comments_and_strings(original)
        for match in PLAIN_STYLE_RE.finditer(masked):
            start = last_control_start(masked, match.start())
            if start is None:
                continue
            construct = masked[start : match.start()]
            has_hit = HIT_TARGET in construct
            looks_like_row = ROW_SHAPE_RE.search(construct) is not None
            expanded = EXPANDED_RE.search(construct) is not None
            if looks_like_row and not has_hit:
                line = masked.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{rel(root, path)}:{line} `.plain` 列表行没有 meterListRowHitTarget()。"
                    "热区只包住文字，点空白没反应。"
                )
            elif expanded and not has_hit and CONTENT_SHAPE not in construct:
                line = masked.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{rel(root, path)}:{line} `.plain` 按钮撑满了宽却没铺热区。"
                    "在 label 上调用 meterListRowHitTarget()。"
                )


def check_primary_action_bar(root: Path, errors: list[str]) -> None:
    """单一主操作必须走 `meterPrimaryActionBar()`，底栏才能铺进 Home Indicator。

    `RootView` 侧栏那只猫不是主操作，除外。实现落在 MeterDesign。
    主按钮和测试连接必须是同一颗胶囊，凭据输入不许有 placeholder。
    """
    design = root / "Packages" / "MeterKit" / "Sources" / "MeterDesign"
    bar = design / "PrimaryActionBar.swift"
    fill = design / "FillProgressButton.swift"
    text = gate_text(root, bar, errors)
    if text is not None:
        if "buttonStyle(.borderedProminent)" not in text:
            errors.append(f"{rel(root, bar)} meterPrimaryActionStyle 必须是 borderedProminent")
        if "controlSize(.large)" not in text:
            errors.append(f"{rel(root, bar)} meterPrimaryActionStyle 必须是 controlSize(.large)")
        if "buttonBorderShape(.capsule)" not in text:
            errors.append(
                f"{rel(root, bar)} meterPrimaryActionStyle 必须是 buttonBorderShape(.capsule)，"
                "和 FillProgressButton 同一颗胶囊。"
            )
        if "scrollEdgeEffectHidden" not in text:
            errors.append(
                f"{rel(root, bar)} 必须关掉底边 scrollEdgeEffect，"
                "否则列表会从主按钮底下透出来。"
            )
        if "ignoresSafeArea" not in text:
            errors.append(
                f"{rel(root, bar)} 底栏背景必须 ignoresSafeArea 铺进 Home Indicator。"
            )
        if "ignoresKeyboard" not in text:
            errors.append(
                f"{rel(root, bar)} 有输入框的抽屉必须能 ignoresKeyboard，"
                "测试连接不能跟着软件键盘抬。"
            )
        if "contentMargins" not in text:
            errors.append(
                f"{rel(root, bar)} List 底边距要清掉，否则 Home Indicator 那截"
                "会把连接参考的按钮抬得比测试连接高。"
            )
    text = gate_text(root, fill, errors)
    if text is not None:
        if "controlSize(.large)" not in text:
            errors.append(f"{rel(root, fill)} FillProgressButton 必须 controlSize(.large)")
        if "Capsule()" not in text:
            errors.append(
                f"{rel(root, fill)} FillProgressButton 必须 clip Capsule()，"
                "不要另写圆角，才能和「我拿到凭据了，下一步」同一颗。"
            )
        if "RoundedRectangle" in text:
            errors.append(f"{rel(root, fill)} 不要用 RoundedRectangle 手写主按钮圆角")

    credential_files = (
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures" / "Setup" / "SetupCredentialsStepView.swift",
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures" / "Developer" / "Gallery" / "GalleryCredentialFieldsView.swift",
        design / "CredentialFieldRow.swift",
    )
    for path in credential_files:
        text = gate_text(root, path, errors)
        if text is None:
            continue
        if "prompt:" in text:
            errors.append(f"{rel(root, path)} 凭据输入不许有 prompt / placeholder")
        if "SecureField" in text or "isSecureTextEntry" in text or "CredentialSecretField" in text:
            errors.append(
                f"{rel(root, path)} 凭据输入不要掩码。"
                "一律 TextField，否则光标高度和热区会和旁边那栏对不上。"
            )
    credentials_step = (
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures"
        / "Setup" / "SetupCredentialsStepView.swift"
    )
    text = gate_text(root, credentials_step, errors)
    if text is not None:
        if "ignoresKeyboard: true" not in text:
            errors.append(
                f"{rel(root, credentials_step)} 测试连接必须 ignoresKeyboard，"
                "不要跟着软件键盘抬，否则抽屉会弹。"
            )
    row = design / "CredentialFieldRow.swift"
    text = gate_text(root, row, errors)
    if text is not None:
        if "TextField" not in text:
            errors.append(f"{rel(root, row)} CredentialFieldRow 必须自己放 TextField")
        if "minTap" not in text or "onTapGesture" not in text:
            errors.append(
                f"{rel(root, row)} 标题和输入行都要 44pt 热区，点空白也要能聚焦。"
            )

    folders = (
        root / "App",
        root / "Widget",
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures",
    )
    for folder in folders:
        for path in swift_files(folder):
            if path.name == "RootView.swift":
                continue
            original = path.read_text(encoding="utf-8")
            masked = mask_comments_and_strings(original)
            for match in BOTTOM_INSET_RE.finditer(masked):
                line = masked.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{rel(root, path)}:{line} 主操作底栏请用 meterPrimaryActionBar()，"
                    "不要自己写 safeAreaInset / safeAreaBar。"
                    "底栏背景必须铺进 Home Indicator，列表行才会被挡住。"
                )


INPUT_CONTROL_RE = re.compile(r"\b(?:TextField|SecureField|TextEditor)\s*\(")
UITEXTFIELD_RE = re.compile(r"\bUITextField\s*\(")
TEXT_CANCEL_BUTTON_RE = re.compile(r'Button\(\s*L\(\s*"取消"\s*\)\s*\)')


def check_keyboard_dismiss(root: Path, errors: list[str]) -> None:
    """有软件键盘的屏幕必须能关掉键盘。

    SwiftUI 输入走 `meterKeyboardDismiss()`，完成贴在软件键盘右上。
    `UITextField` 不吃那条工具栏，必须自己挂 `inputAccessoryView` 的完成。
    """
    dismiss_path = (
        root / "Packages" / "MeterKit" / "Sources" / "MeterDesign" / "KeyboardDismiss.swift"
    )
    text = gate_text(root, dismiss_path, errors)
    if text is not None:
        masked = mask_comments_and_strings(text)
        if "placement: .keyboard" not in masked:
            errors.append(
                f"{rel(root, dismiss_path)} 完成必须挂 placement: .keyboard，贴在键盘上，"
                "不要放进页面或 sheet 的导航栏。"
            )
        if "confirmationAction" in masked:
            errors.append(
                f"{rel(root, dismiss_path)} 完成不要用 confirmationAction。"
                "那会跑到页面/drawer 右上角，离键盘太远。"
            )

    folders = (
        root / "App",
        root / "Widget",
        root / "Packages" / "MeterKit" / "Sources",
    )
    for folder in folders:
        for path in swift_files(folder):
            original = path.read_text(encoding="utf-8")
            masked = mask_comments_and_strings(original)
            relative = rel(root, path)
            match = INPUT_CONTROL_RE.search(masked)
            if match is not None and "meterKeyboardDismiss" not in masked:
                line = masked.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{relative}:{line} TextField/SecureField/TextEditor 必须配合 "
                    "meterKeyboardDismiss()。软件键盘没有关闭键；完成贴在键盘右上，"
                    "见 KeyboardDismiss。"
                )
            field = UITEXTFIELD_RE.search(masked)
            if field is None:
                continue
            if "inputAccessoryView" not in masked:
                line = masked.count("\n", 0, field.start()) + 1
                errors.append(
                    f"{relative}:{line} UITextField 必须自己挂 inputAccessoryView 完成键。"
                    "SwiftUI 的键盘工具栏只跟 TextField 走，API token 那种掩码框会漏掉关闭键。"
                )
                continue
            if "KeyboardDismiss.doneTitle" not in masked and not path.name == "KeyboardDismiss.swift":
                # 不钉文案：完成键叫什么归 `KeyboardDismiss.doneTitle` 一处说，
                # 这里只查 UITextField 的附件栏有没有引用那一个出处。
                line = masked.count("\n", 0, field.start()) + 1
                errors.append(
                    f"{relative}:{line} UITextField 附件栏的完成必须引用 KeyboardDismiss.doneTitle，"
                    "和 SwiftUI 键盘工具栏同一个出处。"
                )


def check_sheet_close(root: Path, errors: list[str]) -> None:
    """关掉 sheet 用系统 X，不要在导航栏手写「取消」。

    `Button(L("取消"))` 没有 role 时会画出文字，不是 iOS 26 那颗 X。
    对话框里的 `Button(L("取消"), role: .cancel)` 不进这条。
    """
    editor = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Services"
        / "SubscriptionEditorSheet.swift"
    )
    filt = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Dashboard"
        / "DashboardFilterSheet.swift"
    )
    text = gate_text(root, editor, errors)
    if text is not None:
        if "meterSheetClose(" not in text:
            errors.append(f"{rel(root, editor)} 关掉订阅抽屉用 meterSheetClose")
        if "cancellationAction" in text:
            errors.append(f"{rel(root, editor)} 关闭不要再走 cancellationAction 文字位")
    text = gate_text(root, filt, errors)
    if text is not None:
        if "meterSheetClose" not in text:
            errors.append(f"{rel(root, filt)} 关掉筛选抽屉用 meterSheetClose")
        if "meterPrimaryActionBar" not in text:
            errors.append(f"{rel(root, filt)} 筛选「用这个」走 meterPrimaryActionBar，不要放导航栏")
        if "cancellationAction" in text or "confirmationAction" in text:
            errors.append(f"{rel(root, filt)} 筛选不要再把确认 / 放弃成对放进导航栏")
        if "meterPhoneDrawerChrome" not in text:
            errors.append(
                f"{rel(root, filt)} 筛选 iPad 是 popover，走 meterPhoneDrawerChrome，"
                "不要把 sheet 外壳套进去"
            )
        if "meterDrawerChrome(.large, usesPadChrome: usesPadChrome)" in text:
            errors.append(f"{rel(root, filt)} 筛选不要 meterDrawerChrome(.large) 进 popover")
    share = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Share"
        / "ShareCardSheet.swift"
    )
    text = gate_text(root, share, errors)
    if text is not None:
        if "meterSheetClose" not in text:
            errors.append(f"{rel(root, share)} 关掉分享卡用 meterSheetClose")
        if "meterDrawerChrome(usesPadChrome ? .fitted : .page" not in text:
            errors.append(
                f"{rel(root, share)} 分享卡的抽屉高度是 "
                "meterDrawerChrome(usesPadChrome ? .fitted : .page)："
                "宽壳按内容定尺寸，手机满屏"
            )
        if "presentationDetents" in text:
            errors.append(f"{rel(root, share)} 不要手写 presentationDetents")
        if "presentationSizing" in text:
            errors.append(f"{rel(root, share)} 不要手写 presentationSizing")
        if "xmark" in text:
            errors.append(f"{rel(root, share)} 关掉用系统 X，不要手写 xmark")

    features = root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures"
    for path in swift_files(features):
        masked = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        if "Button(role: .close)" in masked:
            errors.append(
                f"{rel(root, path)} 关掉 sheet 走 meterSheetClose，不要直接写 Button(role: .close)。"
                "Mac 的 sheet 没有导航栏，系统会把它甩到另起的一条底栏。"
            )

    folders = (
        root / "App",
        root / "Widget",
        root / "Packages" / "MeterKit" / "Sources",
    )
    for folder in folders:
        for path in swift_files(folder):
            original = path.read_text(encoding="utf-8")
            for match in TEXT_CANCEL_BUTTON_RE.finditer(original):
                line = original.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{rel(root, path)}:{line} 关掉 sheet 用 Button(role: .close)。"
                    "不要手写 Button(L(\"取消\"))。"
                    "confirmationDialog 里写 Button(L(\"取消\"), role: .cancel)。"
                )


DRAWER_CHROME_EXEMPT = {
    "DrawerChrome.swift",
}

PRESENTATION_CHROME_TOKENS = (
    "presentationDetents",
    "presentationSizing",
    "presentationDragIndicator",
    "presentationBackground",
)


def swift_method_body(text: str, signature: str) -> str | None:
    idx = text.find(signature)
    if idx < 0:
        return None
    brace = text.find("{", idx)
    if brace < 0:
        return None
    depth = 0
    for i in range(brace, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[brace : i + 1]
    return None


def check_refreshable(root: Path, errors: list[str]) -> None:
    """刷新不许转圈。Features 只能走 meterRefreshable。"""
    design = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterDesign"
        / "MeterRefreshable.swift"
    )
    if not design.is_file():
        errors.append(f"{rel(root, design)} 必须提供 meterRefreshable()")
    else:
        text = design.read_text(encoding="utf-8")
        if "meterRefreshable" not in text:
            errors.append(f"{rel(root, design)} 必须提供 meterRefreshable()")
        if "UIRefreshControl" not in text or "tintColor = .clear" not in text:
            errors.append(f"{rel(root, design)} 必须藏掉系统下拉转圈")

    folders = (
        root / "App",
        root / "Widget",
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures",
    )
    for folder in folders:
        for path in swift_files(folder):
            original = path.read_text(encoding="utf-8")
            if ".refreshable" not in original:
                continue
            relative = rel(root, path)
            for index, line in enumerate(original.splitlines(), 1):
                if ".refreshable" in line:
                    errors.append(
                        f"{relative}:{index} 下拉刷新走 meterRefreshable()，不要直接 .refreshable。"
                    )


def check_drawer_chrome(root: Path, errors: list[str]) -> None:
    """有主按钮的抽屉必须走 meterDrawerChrome，和连接参考同一套高度和底栏。

    有输入框的抽屉还要 ignoresKeyboard: true。
    横屏 iPad 走 form / page，不许 detent。
    """
    design = root / "Packages" / "MeterKit" / "Sources" / "MeterDesign" / "DrawerChrome.swift"
    text = gate_text(root, design, errors)
    if text is not None:
        if "meterDrawerChrome" not in text:
            errors.append(f"{rel(root, design)} 必须提供 meterDrawerChrome()")
        if "meterPhoneDrawerChrome" not in text:
            errors.append(f"{rel(root, design)} 必须提供 meterPhoneDrawerChrome()")
        if "presentationBackground" not in text:
            errors.append(f"{rel(root, design)} 抽屉底必须 presentationBackground 分组灰")
        pad = swift_method_body(text, "func pad(")
        phone = swift_method_body(text, "func phone(")
        if pad is None:
            errors.append(f"{rel(root, design)} 必须有 pad()：iPad 用 form / page")
        else:
            if "presentationDetents" in pad:
                errors.append(f"{rel(root, design)} pad() 不要 presentationDetents，detent 是 iPhone 的")
            if "presentationSizing" not in pad:
                errors.append(f"{rel(root, design)} pad() 必须 presentationSizing")
            if ".form" not in pad or ".page" not in pad:
                errors.append(f"{rel(root, design)} pad() 必须同时有 .form 和 .page")
            if "presentationDragIndicator(.hidden)" not in pad:
                errors.append(f"{rel(root, design)} pad() 必须关掉抓手")
            if "presentationDragIndicator(.visible)" in pad:
                errors.append(f"{rel(root, design)} pad() 不要显示抓手")
        if phone is None:
            errors.append(f"{rel(root, design)} 必须有 phone()：iPhone 用 detent")
        else:
            if "presentationDetents" not in phone:
                errors.append(f"{rel(root, design)} phone() 必须 presentationDetents")
            if "presentationSizing" in phone:
                errors.append(f"{rel(root, design)} phone() 不要 presentationSizing")
            if "presentationDragIndicator(.visible)" not in phone:
                errors.append(f"{rel(root, design)} phone() 必须有抓手")

    height = root / "Packages" / "MeterKit" / "Sources" / "MeterDesign" / "DrawerHeight.swift"
    text = gate_text(root, height, errors)
    if text is not None and "case page" not in text:
        errors.append(f"{rel(root, height)} DrawerHeight 必须有 page 档")

    setup = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "Setup"
        / "UsageSetupPresentation.swift"
    )
    text = gate_text(root, setup, errors)
    if text is not None:
        if "usesPadChrome ? .page" not in text or ".expandable" not in text:
            errors.append(
                f"{rel(root, setup)} 连接参考：手机 expandable，iPad page"
            )

    popover = (
        root
        / "Packages"
        / "MeterKit"
        / "Sources"
        / "MeterFeatures"
        / "PadPopoverOrSheet.swift"
    )
    text = gate_text(root, popover, errors)
    if text is not None and "meterPhoneDrawerChrome" not in text:
        errors.append(
            f"{rel(root, popover)} 注释里要点名 meterPhoneDrawerChrome，"
            "免得 popover 又被套上 sheet 外壳"
        )

    folders = (
        root / "App",
        root / "Widget",
        root / "Packages" / "MeterKit" / "Sources" / "MeterFeatures",
        root / "Packages" / "MeterKit" / "Sources" / "MeterDesign",
    )
    for folder in folders:
        for path in swift_files(folder):
            if path.name in DRAWER_CHROME_EXEMPT:
                continue
            original = path.read_text(encoding="utf-8")
            masked = mask_comments_and_strings(original)
            relative = rel(root, path)
            for token in PRESENTATION_CHROME_TOKENS:
                if token in masked:
                    errors.append(
                        f"{relative} 不要手写 {token}，走 meterDrawerChrome()。"
                        "iPad 的 form / page 也只许写在 DrawerChrome。"
                    )
            is_drawer = any(token in masked for token in PRESENTATION_CHROME_TOKENS)
            has_bar = "meterPrimaryActionBar" in masked
            if is_drawer and has_bar and "meterDrawerChrome" not in masked:
                errors.append(
                    f"{relative} 有主按钮的抽屉必须走 meterDrawerChrome()，"
                    "不要手写 presentationDetents。"
                    "高度和按钮才能和连接参考、添加确认对齐。"
                )
            if (
                has_bar
                and INPUT_CONTROL_RE.search(masked) is not None
                and "ignoresKeyboard: true" not in original
                and "meterDrawerChrome" in masked
            ):
                errors.append(
                    f"{relative} 有输入框的抽屉必须 meterPrimaryActionBar(ignoresKeyboard: true)，"
                    "否则测试连接那种按钮会跟着键盘抬。"
                )


def main() -> int:
    root = repo_root()
    errors: list[str] = []
    check_plain_list_row_hit_targets(root, errors)
    check_primary_action_bar(root, errors)
    check_keyboard_dismiss(root, errors)
    check_sheet_close(root, errors)
    check_drawer_chrome(root, errors)
    check_refreshable(root, errors)

    if errors:
        print(f"check-design-lint: {len(errors)} 处不合版式规范:", file=sys.stderr)
        for line in errors:
            print(f"  {line}", file=sys.stderr)
        print(
            "这些是版式规范。判据和对应的 *GuardrailTests 同一套，改了两边一起改。",
            file=sys.stderr,
        )
        return 1

    print("check-design-lint: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
