import SwiftUI
import MeterCore
import MeterFormat
import MeterDesign

struct ManualSubscriptionRow: View {
    let item: ManualSubscriptionItem
    @Environment(\.moneyPresentation) private var moneyPresentation
    @Environment(\.calendar) private var calendar

    var body: some View {
        HStack(spacing: MeterSpacing.sm) {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(item.name)
                    .font(MeterFont.body)
                    .foregroundStyle(item.hasEnded ? Color.meterSecondaryLabel : Color.meterLabel)
                Text(periodCaption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            Spacer(minLength: MeterSpacing.sm)
            Text(item.amount.formatted(using: moneyPresentation))
                .meterInlineAmountStyle()
                .foregroundStyle(item.hasEnded ? Color.meterSecondaryLabel : Color.meterLabel)
                .accessibilityLabel(
                    SpokenMoney.label(for: item.amount, presentation: moneyPresentation)
                )
        }
        .accessibilityElement(children: .combine)
    }

    private var periodCaption: String {
        let period = switch item.period {
        case .monthly: String(localized: L("月付"))
        case .annual: String(localized: L("年付"))
        }
        guard let endDate = item.endDate else { return period }
        // 拼两条已有的句子，不另起一条三段式——多一条 key 就多两处要翻译的地方。
        // 结束月填在未来的那种还在付，写「到 X 为止」，不能写成「已结束」。
        let month = MeterDateFormat.yearMonth(endDate, calendar: calendar)
        let ended = item.hasEnded
            ? String(localized: L("已结束 · \(month)"))
            : String(localized: L("到 \(month) 为止"))
        return String(localized: L("\(period) · \(ended)"))
    }
}

#Preview("Light") {
    List {
        ManualSubscriptionRow(
            item: ManualSubscriptionItem(
                id: ManualSubscriptionPreviewID.value,
                name: "ChatGPT Plus",
                amount: .init(usd: 20),
                period: .monthly,
                anchorDate: Date(timeIntervalSince1970: 0),
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai
            )
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        ManualSubscriptionRow(
            item: ManualSubscriptionItem(
                id: ManualSubscriptionPreviewID.value,
                name: "Claude Max",
                amount: .init(usd: 200),
                period: .monthly,
                anchorDate: Date(timeIntervalSince1970: 0),
                accountID: AccountID.fixture(for: .anthropic),
                providerID: .anthropic
            )
        )
    }
    .preferredColorScheme(.dark)
}

/// Preview 需要一个 PersistentIdentifier，用内存库里随便一条的类型占位。
private enum ManualSubscriptionPreviewID {
    static let value = ManualSubscriptionItem.previewIdentifier
}

import SwiftData
import MeterPersistence

private extension ManualSubscriptionItem {
    static var previewIdentifier: PersistentIdentifier {
        let container = try! PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let record = SubscriptionRecord(
            domain: .init(
                name: "preview",
                amount: .init(usd: 1),
                period: .monthly,
                anchorDate: Date.distantPast
            ),
            calendar: Calendar(identifier: .gregorian)
        )
        context.insert(record)
        try? context.save()
        return record.persistentModelID
    }
}
