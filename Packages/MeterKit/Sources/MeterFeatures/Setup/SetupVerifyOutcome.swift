import MeterCore
import MeterPersistence
import MeterProviders

enum SetupVerifyOutcome: Equatable {
    case success(title: String, detail: String)
    case emptyReading
    case http(ErrorCase)
    case network
    case unknown

    /// 401 / 403 / 空读数 / 未知失败需要回教程改权限；断网只是等一会儿再试。
    var offersRevisePermissions: Bool {
        switch self {
        case .http, .emptyReading, .unknown:
            return true
        case .success, .network:
            return false
        }
    }
}
