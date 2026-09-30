import Foundation
import MeterCore

/// 添加列表那一行下面的小字：计费方式，外加「刷新要花钱」或「读数信箱」。
///
/// **不是服务介绍。** 介绍在接入指南的 `summary`（「GPT 等模型的 API 平台……」），
/// 确认抽屉读的是那一句。两样以前在桥上共用一个 `summary` 字段名，
/// Android 的确认抽屉于是把「预充值余额」当介绍显示了。
///
/// iOS（`ProviderListingCopy`）和桥上的目录都调这里，措辞只有一份。
public enum ProviderListingCaption {
    public static func kindTitle(_ kind: ProviderKind) -> String {
        switch kind {
        case .usage: L("用量后付费")
        case .prepaid: L("预充值余额")
        case .subscription: L("固定订阅")
        case .freeTier: L("免费额度内")
        case .planAndUsage: L("月费加超额")
        }
    }

    public static func make(kind: ProviderKind, costsMoneyToRefresh: Bool, supportsInbox: Bool) -> String {
        let title = kindTitle(kind)
        if costsMoneyToRefresh {
            return L("\(title) · 刷新要花钱 约 $0.01")
        }
        if supportsInbox {
            return L("\(title) · 读数信箱")
        }
        return title
    }
}
