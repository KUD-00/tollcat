// swift-tools-version: 6.2

import PackageDescription

/// Linux / macOS 终端壳。不要把这个 package 嵌进 MeterKit：MeterKit 仍是 iOS 26 / macOS 26。
/// 共核走 symlink，和 Android/native、Windows/native 同一公式。
let package = Package(
    name: "MeterCoreCLI",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "tollcat", targets: ["tollcat"]),
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
            // 遥测 / 信箱走 api.tollcat.app。CLI 出站只许 provider API。
            exclude: ["ProductWorker.swift", "ProductInbox.swift"],
            resources: [.process("Resources")]
        ),
        // libsecret 运行时 dlopen，不链进二进制。macOS 上是空实现。
        .target(name: "CSecret"),
        .target(
            name: "TollcatCore",
            dependencies: ["MeterBridge", "MeterProviders", "CSecret"]
        ),
        .executableTarget(
            name: "tollcat",
            dependencies: ["TollcatCore"]
        ),
        .testTarget(
            name: "TollcatTests",
            dependencies: ["TollcatCore"]
        ),
    ]
)
