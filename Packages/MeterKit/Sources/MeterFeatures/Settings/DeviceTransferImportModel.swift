import Foundation
import Observation
import MeterCore
import MeterPersistence

@MainActor
@Observable
final class DeviceTransferImportModel {
    var codeInput = ""
    var fileName: String?
    var banner: DeviceTransferImportBanner?
    var lockout = TransferLockout()
    var isWorking = false

    private let dashboard: DashboardModel
    private let settings: SettingsModel
    private var fileBytes: Data?
    private var sourceURL: URL?

    var isLocked: Bool {
        lockout.isLocked(now: Date())
    }

    var canImport: Bool {
        fileBytes != nil
            && TransferCode(userInput: codeInput) != nil
            && !isWorking
            && !isLocked
    }

    init(
        dashboard: DashboardModel,
        settings: SettingsModel,
        initialURL: URL? = nil,
        previewBanner: DeviceTransferImportBanner? = nil,
        previewFileName: String? = nil,
        previewCode: String = ""
    ) {
        self.dashboard = dashboard
        self.settings = settings
        self.banner = previewBanner
        self.fileName = previewFileName
        self.codeInput = previewCode
        if let initialURL {
            load(url: initialURL)
        }
        applyLaunchFixtureIfNeeded()
    }

    func handlePicked(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            return
        }
        load(url: url)
    }

    func load(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            fileBytes = try Data(contentsOf: url)
            fileName = url.lastPathComponent
            sourceURL = url
            if banner == .expired || banner == .invalidFile || banner == .success {
                banner = nil
            }
        } catch {
            banner = .invalidFile
        }
    }

    func importSelected() async {
        let now = Date()
        if lockout.isLocked(now: now) {
            banner = .locked(seconds: lockout.remainingSeconds(now: now))
            return
        }
        guard let fileBytes else {
            banner = .invalidFile
            return
        }
        guard let code = TransferCode(userInput: codeInput) else {
            banner = .invalidCode
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try dashboard.applyImportedDeviceTransfer(fileBytes: fileBytes, code: code, now: now)
            lockout.registerSuccess()
            if let sourceURL, TransferTemporaryFile.shouldDeleteAfterImport(sourceURL) {
                TransferTemporaryFile.delete(sourceURL)
            }
            self.fileBytes = nil
            banner = .success
            settings.handleTransferImported()
            await settings.alignRemindersOnLaunch()
            await dashboard.refresh()
        } catch let error as TransferImportError {
            applyImportError(error, now: now)
        } catch {
            banner = .failed
        }
    }

    private func applyImportError(_ error: TransferImportError, now: Date) {
        switch error {
        case .authenticationFailed:
            lockout.registerFailure(now: now)
            if lockout.isLocked(now: now) {
                banner = .locked(seconds: lockout.remainingSeconds(now: now))
            } else {
                banner = .remainingAttempts(lockout.remainingFreeAttempts)
            }
        case .expired:
            banner = .expired
        case .unsupportedPayloadSchema:
            banner = .unsupportedSchema
        default:
            banner = .invalidFile
        }
    }

    private func applyLaunchFixtureIfNeeded() {
        switch FeatureLaunchArguments.transferImportBanner {
        case "wrong-code":
            fileName = fileName ?? "TollCat-transfer.tollcat"
            codeInput = codeInput.isEmpty ? "AAAAA-AAAAA" : codeInput
            banner = .remainingAttempts(4)
        case "expired":
            fileName = fileName ?? "TollCat-transfer.tollcat"
            banner = .expired
        case "old-schema":
            fileName = fileName ?? "TollCat-transfer.tollcat"
            banner = .unsupportedSchema
        default:
            break
        }
    }

    static var previewIdle: DeviceTransferImportModel {
        DeviceTransferImportModel(
            dashboard: .preview,
            settings: .preview
        )
    }

    static var previewWrongCode: DeviceTransferImportModel {
        DeviceTransferImportModel(
            dashboard: .preview,
            settings: .preview,
            previewBanner: .remainingAttempts(4),
            previewFileName: "TollCat-transfer.tollcat",
            previewCode: "AAAAA-AAAAA"
        )
    }

    static var previewExpired: DeviceTransferImportModel {
        DeviceTransferImportModel(
            dashboard: .preview,
            settings: .preview,
            previewBanner: .expired,
            previewFileName: "TollCat-transfer.tollcat"
        )
    }

    static var previewOldSchema: DeviceTransferImportModel {
        DeviceTransferImportModel(
            dashboard: .preview,
            settings: .preview,
            previewBanner: .unsupportedSchema,
            previewFileName: "TollCat-transfer.tollcat"
        )
    }
}
