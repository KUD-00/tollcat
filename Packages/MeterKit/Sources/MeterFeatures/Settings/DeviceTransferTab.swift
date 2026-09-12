import Foundation

enum DeviceTransferTab: Hashable, CaseIterable, Identifiable {
    case exporting
    case importing

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .exporting: L("导出")
        case .importing: L("导入")
        }
    }

    static func initial(inboundURL: URL?, prefersImport: Bool) -> Self {
        if inboundURL != nil || prefersImport { return .importing }
        return .exporting
    }
}
