import Foundation
import Observation

/// 这一趟数据落在哪儿。
///
/// 「建库失败」有两种，处理方式**相反**，以前它们被折成同一个 `persistsToDisk: false`：
///
/// - 没有 App Group entitlement（未签名的测试宿主、刚换过 group id 的设备）：
///   本来就没有数据，退内存库是对的，提示一句就够。
/// - **库文件在，却打不开**（迁移推不动、文件损坏）：退内存是灾难。用户看到的是
///   一个空 App，会以为数据没了，然后重新接一遍——而这一遍写下去的东西退出就没，
///   同时磁盘上那份真数据还在原地。这一种必须说得更重，而且**绝不能铺演示种子**。
public enum PersistenceStorage: Sendable, Equatable {
    case disk
    case memoryWithoutAppGroup
    case memoryStoreUnreadable
}

/// 落盘失败和演示种子都要在界面上说清楚，不能 silently 混进「真实账单」。
@MainActor
@Observable
public final class PersistenceStatus {
    public var storage: PersistenceStorage
    public var containsDemoData: Bool
    public var isDemoBannerDismissed: Bool
    /// 上一次读库失败了：屏幕上是**上一次读到的**数字，不是库里此刻的。
    ///
    /// 读失败时展示层什么都不敢动（见 `DashboardModel.loadFromPersistence`），
    /// 于是数字看起来完全正常——正因为如此，这一条必须自己说出来。
    public var didFailToRead: Bool
    /// 上一次写库失败了：屏幕上那一项**看起来已经改了**（内存里的副本变了），
    /// 而磁盘上还是旧的，退出再进来会弹回去。
    ///
    /// 和 `didFailToRead` 分开：读失败是「你看到的是旧的」，写失败是
    /// 「你以为改了其实没改」。两句话不能合成一句。
    public var didFailToWrite: Bool

    public init(
        storage: PersistenceStorage,
        containsDemoData: Bool,
        isDemoBannerDismissed: Bool = false,
        didFailToRead: Bool = false,
        didFailToWrite: Bool = false
    ) {
        self.storage = storage
        self.containsDemoData = containsDemoData
        self.isDemoBannerDismissed = isDemoBannerDismissed
        self.didFailToRead = didFailToRead
        self.didFailToWrite = didFailToWrite
    }

    public convenience init(
        persistsToDisk: Bool,
        containsDemoData: Bool,
        isDemoBannerDismissed: Bool = false
    ) {
        self.init(
            storage: persistsToDisk ? .disk : .memoryWithoutAppGroup,
            containsDemoData: containsDemoData,
            isDemoBannerDismissed: isDemoBannerDismissed
        )
    }

    public var persistsToDisk: Bool { storage == .disk }

    public static var preview: PersistenceStatus {
        PersistenceStatus(storage: .disk, containsDemoData: false)
    }

    public var notices: [PersistenceNotice] {
        var result: [PersistenceNotice] = []
        switch storage {
        case .disk:
            break
        case .memoryWithoutAppGroup:
            result.append(
                PersistenceNotice(id: "memory", message: String(localized: L("数据不会被保存")), isDismissible: false)
            )
        case .memoryStoreUnreadable:
            result.append(
                PersistenceNotice(
                    id: "unreadable",
                    message: String(localized: L("数据打不开，这次的改动不会保存")),
                    isDismissible: false
                )
            )
        }
        if didFailToRead {
            result.append(
                PersistenceNotice(
                    id: "read-failed",
                    message: String(localized: L("读不出最新数据，显示的是上次的")),
                    isDismissible: false
                )
            )
        }
        if didFailToWrite {
            result.append(
                PersistenceNotice(
                    id: "write-failed",
                    message: String(localized: L("有一项没能保存")),
                    isDismissible: false
                )
            )
        }
        if containsDemoData, !isDemoBannerDismissed {
            result.append(
                PersistenceNotice(id: "demo", message: String(localized: L("当前是演示数据")), isDismissible: true)
            )
        }
        return result
    }
}
