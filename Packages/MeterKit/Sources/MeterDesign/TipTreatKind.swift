import Foundation

/// 打赏三档的画：一颗糖、一杯咖啡、一块披萨。Features 按产品 ID 来选，这里不认识 IAP。
public enum TipTreatKind: String, CaseIterable, Sendable, Hashable {
    case candy
    case coffee
    case pizza
}
