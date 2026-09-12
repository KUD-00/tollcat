import SwiftUI
import MeterCore
import MeterDesign

/// 「特别关心」的列表行：每家一行，金额、较上月、近 30 天日线。
public struct ServicesModuleView: View {
    public let content: ServicesModuleContent

    public init(content: ServicesModuleContent) {
        self.content = content
    }
    @Environment(\.moduleWidth) private var width
    @Environment(\.moduleHeight) private var height

    public var body: some View {
        if columnCount > 1 {
            // 宽卡里行分两列。卡是定高的，往下加行会被裁掉——横向摊开才是宽度能买到的东西。
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: MeterSpacing.md, alignment: .leading),
                    count: columnCount
                ),
                alignment: .leading,
                spacing: 0
            ) {
                rows
            }
        } else {
            rows
        }
    }

    private var rows: some View {
        ForEach(visibleItems) { item in
            ModuleLink(route: .account(item.accountID)) {
                ServiceCardRow(item: item)
            }
            .accessibilityHint(L("查看 \(item.displayName) 详情"))
        }
        .animation(DashboardMotion.number, value: content.animationSignature)
    }

    /// 高度不封顶（手机 List）就列全部；其余按高度预算裁——列出来看不见的行只是被裁掉。
    private var visibleItems: [ServiceCardItem] {
        guard height.prefersCardMetrics else { return content.items }
        return Array(content.items.prefix(rowLimit))
    }

    /// 列几行**高度**说了算。宽度只在分了两列之后放大它：
    /// 两列装两倍的行，而卡不会因此变高。
    private var rowLimit: Int {
        let perColumn = switch height {
        case .tight: 2
        case .regular: 4
        case .tall, .unbounded: 8
        }
        return perColumn * columnCount
    }

    /// 只有卡里才分列：手机 List 的一行就是一行，往里塞网格会把行分隔线画到网格外面。
    private var columnCount: Int {
        height.prefersCardMetrics && width >= .wide ? 2 : 1
    }
}

public struct ServiceCardRow: View {
    public let item: ServiceCardItem

    public init(item: ServiceCardItem) {
        self.item = item
    }
    @Environment(\.moduleWidth) private var width
    @Environment(\.moduleContainer) private var container
    /// Mac 列里的链接行自带 chevron，别再叠一颗。
    @Environment(\.moduleRowChromeFromLink) private var rowChromeFromLink

    public var body: some View {
        HStack(alignment: .center, spacing: MeterSpacing.sm) {
            // 挤到 compact 时图标和走势图都收掉：名字和金额是这一行的全部意思，
            // 剩下两样在 190pt 宽里只会把它们挤成省略号。
            if width > .compact {
                ProviderGlyph(colorKey: item.colorKey, accessibilityName: item.displayName)
                    .frame(width: MeterSpacing.providerGlyph, alignment: .center)
            }
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(item.displayName)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                    .lineLimit(1)
                if let change = item.changeText {
                    Text(change)
                        .font(MeterFont.footnote)
                        .foregroundStyle(item.changeIsUp ? MeterColor.warn : Color.meterSecondaryLabel)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if item.spark.count >= 2, width > .compact {
                SparklineChart(values: item.spark)
                    .frame(width: MeterSpacing.sparkline, height: MeterSpacing.sparklineHeight)
            }
            Text(item.amountText)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
                .monospacedDigit()
                .lineLimit(1)
                .contentTransition(.numericText(value: item.amountValue))
            if container.drawsOwnChevron, !rowChromeFromLink {
                Image(systemName: "chevron.right")
                    .font(MeterFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: container.suppliesRowChrome ? 0 : MeterSpacing.minTap)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.spokenLabel)
    }
}

/// 宽壳上一家一张卡：名字、金额、较上月、走势。
public struct ServiceTileView: View {
    public let item: ServiceCardItem

    public init(item: ServiceCardItem) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            HStack(spacing: MeterSpacing.sm) {
                ProviderGlyph(colorKey: item.colorKey, accessibilityName: item.displayName)
                    .frame(width: MeterSpacing.providerGlyph)
                Text(item.displayName)
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let change = item.changeText {
                    Text(change)
                        .font(MeterFont.footnote.weight(.semibold))
                        .foregroundStyle(item.changeIsUp ? MeterColor.warn : MeterColor.good)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline) {
                Text(item.amountText)
                    .font(MeterFont.largeTitle.weight(.semibold))
                    .foregroundStyle(Color.meterLabel)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: item.amountValue))
                Spacer(minLength: MeterSpacing.sm)
                if item.spark.count >= 2 {
                    SparklineChart(values: item.spark)
                        .frame(width: MeterSpacing.sparkline, height: MeterSpacing.sparklineHeight)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.spokenLabel)
    }
}

#Preview("Light") {
    NavigationStack {
        List {
            Section {
                ServicesModuleView(content: ServicesPreviewData.sample)
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ServiceTileView(item: ServicesPreviewData.sample.items[0])
        .frame(width: 320, height: 150)
        .padding()
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}

public enum ServicesPreviewData {
    public static let sample = ServicesModuleContent(items: [
        ServiceCardItem(
            accountID: AccountID.fixture(for: .cloudflare),
            providerID: .cloudflare,
            displayName: "Cloudflare",
            colorKey: "cloudflare",
            amountText: "$11.05",
            amountValue: 11.05,
            spokenAmount: "11 美元 5 美分",
            changeText: "+12%",
            changeIsUp: true,
            spark: [6, 8, 7, 9, 10, 11]
        ),
        ServiceCardItem(
            accountID: AccountID.fixture(for: .neon),
            providerID: .neon,
            displayName: "Neon",
            colorKey: "neon",
            amountText: "$3.13",
            amountValue: 3.13,
            spokenAmount: "3 美元 13 美分",
            changeText: nil,
            changeIsUp: false,
            spark: [0, 0, 2, 3, 3, 3.1]
        ),
    ])
}
