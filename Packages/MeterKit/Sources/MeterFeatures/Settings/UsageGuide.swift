import Foundation
import MeterDesign

struct UsageGuide: Identifiable, Sendable {
    var id: UsageGuideID
    var title: LocalizedStringResource
    var body: LocalizedStringResource
    var mood: CatMood

    static var all: [UsageGuide] {
        UsageGuideID.allCases.map(make)
    }

    static func make(_ id: UsageGuideID) -> UsageGuide {
        switch id {
        case .heroExcludesSubscriptions:
            UsageGuide(
                id: id,
                title: L("这个数字不含月费"),
                body: L("仪表上最大的那个数，是用量、预充值消耗和超额。GitHub Copilot 这类月费单独一行，也不进构成图。整笔账单要把两行一起看。"),
                mood: .normal
            )
        case .awsRefreshCostsMoney:
            UsageGuide(
                id: id,
                title: L("AWS 刷新要花钱"),
                body: L("Cost Explorer 每问一次大约 $0.01。所以 AWS 默认不跟着全局刷新，也不会在进入 App 时自动刷。要最新数字，去这家服务里自己点，按钮上会写价钱。"),
                mood: .alert
            )
        case .keysStayOnThisDevice:
            UsageGuide(
                id: id,
                title: L("换手机，钥匙不会跟着走"),
                body: L("密钥只进这台设备的 Keychain，不进 iCloud，也不跟备份走。换机请用设置里的「导入与导出」，一次加密文件带走接入。"),
                mood: .awkward
            )
        case .inboxForMissingAPIs:
            UsageGuide(
                id: id,
                title: L("没有接口的可以投进信箱"),
                body: L("有的服务没有公开账单接口。你可以建一个读数信箱，按格式自己投递，数字仍然进仪表。"),
                mood: .saved
            )
        case .widgetOnLockScreen:
            UsageGuide(
                id: id,
                title: L("锁屏上也能看到这个月"),
                body: L("没有金额告警。把小组件放到主屏或锁屏，划过去就能看见数字。提醒只叫你回来刷新，通知里不会写金额。"),
                mood: .sleeping
            )
        }
    }
}
