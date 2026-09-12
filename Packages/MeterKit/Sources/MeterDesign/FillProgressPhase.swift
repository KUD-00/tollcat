import Foundation

/// 主按钮铺色的三个相位。测连接时从左到右走，不要转圈。
public enum FillProgressPhase: Equatable, Sendable, Hashable {
    case idle
    case progressing
    case completed
}
