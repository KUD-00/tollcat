import MeterCore
import MeterDashboard
import MeterProviders

enum ProviderListingCopy {
    /// 措辞在共享层（`ProviderListingCaption`），桥上的目录读同一份。
    static func kindTitle(_ kind: ProviderKind) -> String {
        ProviderListingCaption.kindTitle(kind)
    }

    /// 详情页图表下面那句读法。类型名已经是 section 标题，这里只说这张图怎么读。
    static func chartFooter(_ kind: ProviderKind) -> String? {
        switch kind {
        case .usage, .prepaid:
            return nil
        case .planAndUsage:
            return String(localized: L("柱是每天的超额用量。没数据的那天是空的，不是 $0。月费在下面「固定订阅」里，不进这张图。"))
        case .freeTier:
            return String(localized: L("还在额度里，合计按 $0 计。超出之后才会按用量记账。"))
        case .subscription:
            return String(localized: L("按扣款日全额计入当月，不画进每天的图。"))
        }
    }

    static func caption(for descriptor: ProviderDescriptor) -> String {
        ProviderListingCaption.make(
            kind: descriptor.kind,
            costsMoneyToRefresh: descriptor.costsMoneyToRefresh,
            supportsInbox: descriptor.supportsInboxIngest
        )
    }
}
