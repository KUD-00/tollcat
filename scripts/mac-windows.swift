#!/usr/bin/env swift
import CoreGraphics
import Foundation

/// 列出 / 挑选 TollCat 窗口的 CGWindowID，给 screencapture -l 用。
/// 用法：
///   swift scripts/mac-windows.swift list
///   swift scripts/mac-windows.swift main
///   swift scripts/mac-windows.swift panel

struct Win {
    var id: Int
    var pid: Int
    var name: String
    var width: Double
    var height: Double
}

func windows() -> [Win] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return []
    }
    return raw.compactMap { item in
        guard (item[kCGWindowOwnerName as String] as? String) == "TollCat" else { return nil }
        guard let id = item[kCGWindowNumber as String] as? Int else { return nil }
        let pid = item[kCGWindowOwnerPID as String] as? Int ?? 0
        let bounds = item[kCGWindowBounds as String] as? [String: Double] ?? [:]
        let width = bounds["Width"] ?? 0
        let height = bounds["Height"] ?? 0
        if width < 80 || height < 40 { return nil }
        return Win(
            id: id,
            pid: pid,
            name: item[kCGWindowName as String] as? String ?? "",
            width: width,
            height: height
        )
    }
}

let args = Array(CommandLine.arguments.dropFirst())
let mode = args.first ?? "list"
let pidFilter = args.dropFirst().compactMap { Int($0) }.first
let found = windows().filter { win in
    guard let pidFilter else { return true }
    return win.pid == pidFilter
}

let settingsNames: Set<String> = ["设置", "Settings", "設定"]

switch mode {
case "list":
    for win in found {
        print("\(win.id)\tpid=\(win.pid)\t\(Int(win.width))x\(Int(win.height))\t\(win.name)")
    }
case "main":
    // 主窗口：截图进程里最大的那扇，排除菜单栏面板和设置页。
    let main = found
        .filter { $0.name != "MenuBarShot" && $0.width >= 700 && !settingsNames.contains($0.name) }
        .max { $0.width * $0.height < $1.width * $1.height }
    guard let main else { exit(1) }
    print(main.id)
case "panel":
    let panel = found.first { $0.name == "MenuBarShot" }
        ?? found.filter { $0.width <= 420 && $0.width >= 240 }.max { $0.height < $1.height }
    guard let panel else { exit(1) }
    print(panel.id)
default:
    fputs("usage: mac-windows.swift list|main|panel [pid]\n", stderr)
    exit(2)
}
