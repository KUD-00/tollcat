// swift-tools-version: 6.2

import PackageDescription

/// Windows 壳用来把仓库里那份 MeterCore + MeterProviders 编成 dll。
/// 不要把这个 package 嵌进 MeterKit：MeterKit 仍是 iOS 26 / macOS 26。
let package = Package(
    name: "MeterCoreWindows",
    products: [
        .library(name: "MeterCoreCLR", type: .dynamic, targets: ["MeterCoreCLR"]),
    ],
    targets: [
        .target(name: "MeterCore"),
        .target(
            name: "MeterProviders",
            dependencies: ["MeterCore"],
            resources: [.process("Fixtures"), .process("Resources")]
        ),
        .target(
            name: "MeterFormat",
            dependencies: ["MeterCore"],
            resources: [.process("Resources")]
        ),
        // 仪表盘的折算（各模块 builder）。和 iOS 同一份源码，不在桥里另抄。
        .target(
            name: "MeterDashboard",
            dependencies: ["MeterCore", "MeterFormat"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "MeterBridge",
            dependencies: ["MeterCore", "MeterProviders", "MeterFormat", "MeterDashboard"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "MeterCoreCLR",
            dependencies: ["MeterBridge", "MeterProviders"]
        ),
    ]
)
