import MeterCore
import MeterPersistence
import MeterProviders

/// 简介页上那些编译期就知道的事实。文案走 Features catalog，不进远程目录。
enum SetupProviderFacts {
    enum SupportLevel: Equatable {
        /// 有公开只读账单接口，真实账单对过。
        case full
        /// 接口按文档接上了，我们没用真实账号测过。
        case theoretical
        /// 官方没有账单接口，走读数信箱。
        case inbox
        /// 现在接不上。
        case unavailable
    }

    static func kindTitle(for descriptor: ProviderDescriptor?) -> String {
        guard let descriptor else { return "" }
        return ProviderListingCopy.kindTitle(descriptor.kind)
    }

    static func supportLevel(for descriptor: ProviderDescriptor?) -> SupportLevel {
        guard let descriptor else { return .unavailable }
        if descriptor.supportsInboxIngest {
            return .inbox
        }
        if ProviderAssembly.liveRESTProviderIDs.contains(descriptor.id),
           descriptor.accessStatus == .available {
            return .full
        }
        // 刷新花钱（AWS Cost Explorer）不是这一档的理由，那是列表 caption。
        if ProviderAssembly.liveRESTProviderIDs.contains(descriptor.id)
            || descriptor.accessStatus == .pendingVerification {
            return .theoretical
        }
        return .unavailable
    }

    static func supportTitle(for descriptor: ProviderDescriptor?) -> String {
        switch supportLevel(for: descriptor) {
        case .full:
            return String(localized: L("完全支持"))
        case .theoretical:
            return String(localized: L("理论支持"))
        case .inbox:
            return String(localized: L("读数信箱"))
        case .unavailable:
            return String(localized: L("暂不支持"))
        }
    }

    static func supportBars(for descriptor: ProviderDescriptor?) -> Int {
        switch supportLevel(for: descriptor) {
        case .full: 3
        case .theoretical: 2
        case .inbox: 1
        case .unavailable: 0
        }
    }

    static func supportCaption(for descriptor: ProviderDescriptor?) -> String {
        switch supportLevel(for: descriptor) {
        case .full:
            return ""
        case .theoretical:
            return String(localized: L("我们没正式测过，接入说明可能写错。能接上的话，试试看。"))
        case .inbox:
            return String(localized: L("不能自动取账单。你把数字取来，投进来给 App 读。"))
        case .unavailable:
            return String(localized: L("现在还接不上。"))
        }
    }

    /// 测完连接后要不要出反馈节：还没拿真实账单对过，而且不是读数信箱。
    static func offersSetupFeedback(for descriptor: ProviderDescriptor?) -> Bool {
        guard let descriptor else { return false }
        return descriptor.accessStatus == .pendingVerification
            && !descriptor.supportsInboxIngest
    }

    static func needsLine(guide: SetupGuide, usesInbox: Bool) -> String {
        if !guide.needsLine.isEmpty {
            return guide.needsLine
        }
        if usesInbox {
            return String(localized: L("读数信箱"))
        }
        return ""
    }
}
