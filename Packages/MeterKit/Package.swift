// swift-tools-version: 6.2

import PackageDescription

// 这里的依赖方向是架构合约,见仓库根目录 ARCHITECTURE.md。
// 不要为了图方便加边 —— 需要反向调用就定协议,在 App 的 AppEnvironment 里注入。
let package = Package(
    name: "MeterKit",
    defaultLocalization: "zh-Hans",
    // watchOS 只为手表壳：它只链 MeterGlance（零依赖），其余 target 从来不在手表上编。
    platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26)],
    products: [
        .library(name: "MeterCore", targets: ["MeterCore"]),
        .library(name: "MeterDesign", targets: ["MeterDesign"]),
        .library(name: "MeterFormat", targets: ["MeterFormat"]),
        .library(name: "MeterProviders", targets: ["MeterProviders"]),
        .library(name: "MeterPersistence", targets: ["MeterPersistence"]),
        .library(name: "MeterTips", targets: ["MeterTips"]),
        .library(name: "MeterInbox", targets: ["MeterInbox"]),
        .library(name: "MeterFeedback", targets: ["MeterFeedback"]),
        .library(name: "MeterUsage", targets: ["MeterUsage"]),
        .library(name: "MeterGlance", targets: ["MeterGlance"]),
        .library(name: "MeterDashboard", targets: ["MeterDashboard"]),
        .library(name: "MeterModules", targets: ["MeterModules"]),
        .library(name: "MeterFeatures", targets: ["MeterFeatures"]),
    ],
    targets: [
        // 领域模型与折算。零依赖、纯函数、可脱离一切单测。
        .target(name: "MeterCore"),

        // 设计系统。只认 SwiftUI,不认领域概念。
        .target(
            name: "MeterDesign",
            resources: [.process("Resources")]
        ),

        // 领域值 → 用户可见字符串（读出来的金额、日期、币种名）。
        // Widget 和 MeterFeatures 共用，别在两边各抄一份文案。
        .target(
            name: "MeterFormat",
            dependencies: ["MeterCore"],
            resources: [.process("Resources")]
        ),

        // 取数。三十多家真实账单适配器；fixtures 走资源，只喂测试和 Stub。
        .target(
            name: "MeterProviders",
            dependencies: ["MeterCore"],
            resources: [.process("Fixtures"), .process("Resources")]
        ),

        // SwiftData + Keychain + 打包目录。
        .target(
            name: "MeterPersistence",
            dependencies: ["MeterCore"],
            resources: [.process("Catalog"), .process("Resources")]
        ),

        // 打赏。唯一会联网到我们自己服务器的模块。
        // 不链接 MeterProviders，反过来也一样——账单凭据走不了这条路。
        .target(
            name: "MeterTips",
            resources: [.process("Resources")],
            linkerSettings: [.linkedFramework("StoreKit")]
        ),

        // 读数信箱。官方没有账单接口的那几家，用户自己取数后投递到 Worker，
        // 这个模块只负责把它取回来。
        //
        // 依赖只到 MeterCore：它既不认识 provider 目录（那是 MeterProviders 的事），
        // 也不落库（那是 MeterPersistence 的事）。和 MeterTips 一样是叶子。
        .target(name: "MeterInbox", dependencies: ["MeterCore"]),

        // 反馈。零依赖叶子：它不认识 provider、不认识金额、不落库。
        //
        // 依赖表是这个模块的安全说明书——它连 MeterCore 都不需要，
        // 所以「反馈里不小心带上账单数据」在编译期就不可能发生。
        .target(name: "MeterFeedback"),

        // 匿名页面计数。零依赖叶子：不认识 provider、不认识金额、不落库。
        .target(name: "MeterUsage"),

        // 「一眼」：手表表盘、智能叠放、iPhone 锁屏那几格，和手表 App 那一屏。
        //
        // **零依赖**，和 MeterFeedback 同一个理由：手表壳只链这一个，所以
        // 「凭据、账本、厂商适配器被带上手表」在编译期就不可能发生。
        // 它收的是 iPhone 已经折好、排好字的一份 `Glance`，自己不折算、不格式化金额。
        .target(
            name: "MeterGlance",
            resources: [.process("Resources")]
        ),

        // 仪表盘的折算：账本 → 各模块要画的值（builder + 值类型），全是纯函数。
        //
        // 单独一个 target 是为了 **四个平台共用同一份**。Android / Windows / CLI 的桥
        // 把这个目录软链进各自的包，直接调这里的 builder——以前桥里抄了一份，
        // 抄的那份悄悄漂走（订阅只算月付、年付不摊）。所以这里不许出现 SwiftUI、
        // MeterDesign、`LocalizedStringResource` 这些 Android 上编不过的东西，
        // 文案走 MeterFormat 的 `PortableText`，`check-source-invariants.py` 按这条扫。
        .target(
            name: "MeterDashboard",
            dependencies: ["MeterCore", "MeterFormat"],
            resources: [.process("Resources")]
        ),

        // 仪表盘模块的视图层：模块本身。
        //
        // 单独一个 target 是为了 **widget 链得到**。Widget 不能链 MeterFeatures
        // （那会把三十多家账单适配器一起拖进扩展，SPEC 第 09 节也不许 widget 自己调 API），
        // 但模块视图本身只认「已经折算好的值」。值和 builder 在 MeterDashboard，
        // 取数、落库、DashboardModel 留在 MeterFeatures。
        //
        // 依赖只到 MeterCore / MeterDesign / MeterFormat / MeterDashboard / MeterGlance：
        // 这张依赖表就是「widget 会链进什么」的安全说明书，别往里加。
        .target(
            name: "MeterModules",
            // MeterGlance 是零依赖叶子：这条边只让 widget 多链一份值类型和几块锁屏视图，
            // 不会顺带拖进别的东西。`GlanceBuilder`（仪表内容 → 一眼）住在这边。
            dependencies: ["MeterCore", "MeterDesign", "MeterFormat", "MeterDashboard", "MeterGlance"],
            resources: [.process("Resources")]
        ),

        // 界面。
        .target(
            name: "MeterFeatures",
            dependencies: [
                "MeterCore", "MeterDesign", "MeterFormat", "MeterDashboard", "MeterModules",
                "MeterProviders", "MeterPersistence", "MeterTips", "MeterInbox",
                "MeterFeedback", "MeterUsage", "MeterGlance",
            ],
            resources: [.process("Resources")]
        ),
    ]
)
