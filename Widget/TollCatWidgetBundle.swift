// GENERATED — 由 scripts/generate-shared.py 从 shared/widgets.json 生成。
// 不要手改：改 shared/widgets.json 后重跑生成器。


import SwiftUI
import WidgetKit
import MeterModules

/// 一块模块一个 widget kind：图库里一行一块，能搜到名字，加完就是那一块。
///
/// 这份是**生成物**。手写的话，加一块模块就会安静地缺席主屏——
/// 没有编译错误、没有测试红，只有用户发现不了。所以清单只有一份：
/// `shared/widgets.json`，生成器核对它和 `DashboardModuleID` 完全对齐。
///
/// 画什么一律走 `DashboardModuleFactory`，这里只负责登记和声明尺寸。
@main
struct TollCatWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthToDateWidget()
        CompositionWidget()
        ServicesWidget()
        SubscriptionsWidget()
        HeatmapWidget()
        CategoriesWidget()
        BudgetWidget()
    }
}

/// 一个大数字加预计月底。2×2 正好。4×4 只是把同样三行抻长，不给。
struct MonthToDateWidget: Widget {
    private let module = DashboardModuleID.monthToDate

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.monthToDate",
            provider: ModuleTimelineProvider(module: .monthToDate)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemSmall, .systemMedium])
        .containerBackgroundRemovable()
    }
}

/// 圆环加图例。2×2 两边都不够看；4×4 只是把圆环放大，不给。自己就是一张图，不写标题。
struct CompositionWidget: Widget {
    private let module = DashboardModuleID.composition

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.composition",
            provider: ModuleTimelineProvider(module: .composition)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemMedium])
        .containerBackgroundRemovable()
    }
}

/// 一行一家，带日线。2×2 收掉图标和走势只剩名字加金额，不值一格。large 能列 8 行，是它最好的样子。
struct ServicesWidget: Widget {
    private let module = DashboardModuleID.services

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.services",
            provider: ModuleTimelineProvider(module: .services)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemMedium, .systemLarge])
        .containerBackgroundRemovable()
    }
}

/// 一个折算每月的大数字加几笔。2×2 装不下大数字加行。
struct SubscriptionsWidget: Widget {
    private let module = DashboardModuleID.subscriptions

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.subscriptions",
            provider: ModuleTimelineProvider(module: .subscriptions)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemMedium, .systemLarge])
        .containerBackgroundRemovable()
    }
}

/// 一个月的格子图。2×2 里只摆图和月份小字，正好——这块要的就是「一眼扫过」。再大只是把格子放大，没有多说一件事，所以只给这一档。图自带月份，不写标题。
struct HeatmapWidget: Widget {
    private let module = DashboardModuleID.heatmap

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.heatmap",
            provider: ModuleTimelineProvider(module: .heatmap)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemSmall])
        .containerBackgroundRemovable()
    }
}

/// 圆环加类别图例。类别名比厂商名长，4×2 的图例排不开，只给 4×4。
struct CategoriesWidget: Widget {
    private let module = DashboardModuleID.categories

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.categories",
            provider: ModuleTimelineProvider(module: .categories)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemLarge])
        .containerBackgroundRemovable()
    }
}

/// 一个百分比加两排小方块。2×2 正好。4×4 只是把同样三样东西抻长，没有多说一件事，不给。
struct BudgetWidget: Widget {
    private let module = DashboardModuleID.budget

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TollCatWidget.budget",
            provider: ModuleTimelineProvider(module: .budget)
        ) { entry in
            TollCatWidgetView(entry: entry)
        }
        .configurationDisplayName(module.title)
        .description(module.summary)
        .supportedFamilies([.systemSmall, .systemMedium])
        .containerBackgroundRemovable()
    }
}
