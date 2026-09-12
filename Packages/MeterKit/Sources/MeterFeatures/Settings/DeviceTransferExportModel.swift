import Foundation
import Observation
import MeterCore
import MeterPersistence

@MainActor
@Observable
final class DeviceTransferExportModel {
    enum Phase: Equatable {
        case preparing
        case ready(DeviceTransferExportSnapshot)
        case failed(String)
    }

    var phase: Phase = .preparing

    var shareItem: DeviceTransferShareItem? {
        fileBytes.map(DeviceTransferShareItem.init)
    }

    private let dashboard: DashboardModel
    private var fileBytes: Data?

    init(
        dashboard: DashboardModel,
        previewSnapshot: DeviceTransferExportSnapshot? = nil,
        previewFileBytes: Data? = nil
    ) {
        self.dashboard = dashboard
        if let previewSnapshot {
            self.phase = .ready(previewSnapshot)
            self.fileBytes = previewFileBytes ?? Data()
        }
    }

    func prepareIfNeeded() {
        guard fileBytes == nil else { return }
        prepare()
    }

    func prepare() {
        do {
            let exported = try dashboard.exportDeviceTransfer()
            fileBytes = exported.fileBytes
            phase = .ready(
                DeviceTransferExportSnapshot(
                    displayCode: exported.code.displayString,
                    notAfter: exported.notAfter,
                    deadlineCaption: MeterDateFormat.monthDayTime(
                        exported.notAfter,
                        calendar: dashboard.clock.calendar
                    )
                )
            )
        } catch {
            fileBytes = nil
            phase = .failed(String(localized: L("没能生成转移文件")))
        }
    }

    func cleanup() {
        fileBytes = nil
    }

    static var previewReady: DeviceTransferExportModel {
        DeviceTransferExportModel(
            dashboard: .preview,
            previewSnapshot: DeviceTransferExportSnapshot(
                displayCode: "K7M2Q-9XR4T",
                notAfter: Date(),
                deadlineCaption: "8:00"
            ),
            previewFileBytes: Data([0x74])
        )
    }
}
