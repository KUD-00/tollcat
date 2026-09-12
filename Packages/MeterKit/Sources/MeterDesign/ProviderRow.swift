import SwiftUI

/// `ProviderGlyph` + 标准列表行内容。背景和分隔线交给 `List`。
public struct ProviderRow: View {
    private let name: String
    private let colorKey: String
    private let value: String
    private let subtitle: String?
    private let isConnected: Bool
    private let usesSecondaryValue: Bool
    private let staleLabel: String?
    private let valueCaption: String?
    private let spokenValue: String?
    private let amountValue: Double
    private let accessibilityName: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        name: String,
        colorKey: String,
        value: String,
        subtitle: String? = nil,
        isConnected: Bool = true,
        usesSecondaryValue: Bool = false,
        staleLabel: String? = nil,
        valueCaption: String? = nil,
        spokenValue: String? = nil,
        amountValue: Double = 0,
        accessibilityName: String? = nil
    ) {
        self.name = name
        self.colorKey = colorKey
        self.value = value
        self.subtitle = subtitle
        self.isConnected = isConnected
        self.usesSecondaryValue = usesSecondaryValue
        self.staleLabel = staleLabel
        self.valueCaption = valueCaption
        self.spokenValue = spokenValue
        self.amountValue = amountValue
        self.accessibilityName = accessibilityName ?? name
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                inline
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var inline: some View {
        HStack(spacing: MeterSpacing.sm) {
            ProviderGlyph(colorKey: colorKey, accessibilityName: accessibilityName)
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(name)
                    .font(MeterFont.body)
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: MeterSpacing.sm)
            trailingValues
        }
    }

    private var stacked: some View {
        HStack(alignment: .top, spacing: MeterSpacing.sm) {
            ProviderGlyph(colorKey: colorKey, accessibilityName: accessibilityName)
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(name)
                    .font(MeterFont.body)
                    .foregroundStyle(nameColor)
                trailingValues
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var trailingValues: some View {
        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: MeterSpacing.xxs
        ) {
            Text(value)
                .meterInlineAmountStyle()
                .foregroundStyle(valueColor)
                .contentTransition(.numericText(value: amountValue))
            if let staleLabel {
                Text(staleLabel)
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.warn)
            } else if let valueCaption, !valueCaption.isEmpty {
                Text(valueCaption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
        }
        .animation(.snappy(duration: 0.45), value: amountValue)
    }

    private var nameColor: Color {
        isConnected ? Color.meterLabel : Color.meterSecondaryLabel
    }

    private var valueColor: Color {
        if usesSecondaryValue || !isConnected {
            return Color.meterSecondaryLabel
        }
        return Color.meterLabel
    }

    private var accessibilityLabel: String {
        var parts = [accessibilityName, spokenValue ?? value]
        if let staleLabel {
            parts.append(staleLabel)
        }
        if let valueCaption, !valueCaption.isEmpty, valueCaption != staleLabel {
            parts.append(valueCaption)
        }
        if let subtitle, !subtitle.isEmpty, subtitle != staleLabel {
            parts.append(subtitle)
        }
        return parts.joined(separator: "，")
    }
}

#Preview("Light") {
    List {
        ProviderRow(
            name: "AWS",
            colorKey: "aws",
            value: "$21.40",
            subtitle: String(localized: L("手动刷新")),
            valueCaption: "约 $0.01",
            spokenValue: "21 美元 40 美分",
            amountValue: 21.4
        )
        ProviderRow(
            name: "Cloudflare",
            colorKey: "cloudflare",
            value: "$11.05",
            subtitle: "12 分钟前",
            staleLabel: String(localized: L("数据陈旧")),
            spokenValue: "11 美元 5 美分",
            amountValue: 11.05
        )
        ProviderRow(
            name: "Vercel",
            colorKey: "vercel",
            value: String(localized: L("免费额度")),
            subtitle: "用了 34%",
            usesSecondaryValue: true,
            spokenValue: "免费额度，用了百分之 34",
            amountValue: 0.34
        )
        ProviderRow(
            name: "Fly.io",
            colorKey: "fly",
            value: String(localized: L("未接入")),
            isConnected: false,
            usesSecondaryValue: true,
            spokenValue: String(localized: L("未接入"))
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        ProviderRow(
            name: "OpenAI",
            colorKey: "openai",
            value: "$7.62",
            subtitle: "余额 $42",
            spokenValue: "7 美元 62 美分",
            amountValue: 7.62
        )
        ProviderRow(
            name: "Anthropic",
            colorKey: "anthropic",
            value: String(localized: L("未接入")),
            isConnected: false,
            usesSecondaryValue: true,
            spokenValue: String(localized: L("未接入"))
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    List {
        ProviderRow(
            name: "OpenAI",
            colorKey: "openai",
            value: "$7.62",
            subtitle: "余额 $42.00",
            spokenValue: "7 美元 62 美分",
            amountValue: 7.62
        )
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("两个 Cloudflare") {
    List {
        ProviderRow(
            name: "Cloudflare · 工作",
            colorKey: "cloudflare",
            value: "$11.05",
            subtitle: "12 分钟前",
            spokenValue: "11 美元 5 美分",
            amountValue: 11.05,
            accessibilityName: "Cloudflare · 工作"
        )
        ProviderRow(
            name: "Cloudflare · 个人",
            colorKey: "cloudflare",
            value: "$3.20",
            subtitle: "12 分钟前",
            spokenValue: "3 美元 20 美分",
            amountValue: 3.20,
            accessibilityName: "Cloudflare · 个人"
        )
    }
}
