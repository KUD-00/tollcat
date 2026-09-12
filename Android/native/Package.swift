// swift-tools-version: 6.2

import PackageDescription

/// Android 壳用来把仓库里那份 MeterCore + MeterProviders 编成 JNI。
/// 不要把这个 package 嵌进 MeterKit：MeterKit 仍是 iOS 26，这里只为官方 Swift Android SDK 出 .so。
let package = Package(
    name: "MeterCoreAndroid",
    products: [
        .library(name: "MeterCoreJNI", type: .dynamic, targets: ["MeterCoreJNI"]),
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
        .target(
            name: "MeterBridge",
            dependencies: ["MeterCore", "MeterProviders", "MeterFormat"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "MeterCoreJNI",
            dependencies: ["MeterBridge", "MeterCore", "MeterProviders", "MeterFormat"]
        ),
    ]
)
