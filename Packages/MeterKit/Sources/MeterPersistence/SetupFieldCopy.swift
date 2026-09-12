import Foundation
import MeterCore

extension SetupField {
    /// 空值用字段名提示；格式错误用 catalog 里那句具体说明。
    /// 文案留在本模块：`MeterCore` 不产生用户可见文案（架构红线）。
    public func errorMessage(for raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return String(localized: L("请填写\(label)"))
        }
        return validation?.errorMessage(for: value)
    }
}
