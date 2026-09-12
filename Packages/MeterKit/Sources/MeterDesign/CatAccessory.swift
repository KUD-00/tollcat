import Foundation

/// 身体以外的挂件。和眼镜无关——眼镜是脸上的一层，可以跟挂件叠。
public enum CatAccessory: String, CaseIterable, Sendable, Hashable {
    case none
    case zzz
    case bang
    case skull
}
