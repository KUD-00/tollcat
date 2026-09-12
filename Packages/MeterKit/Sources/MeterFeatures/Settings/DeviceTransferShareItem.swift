import CoreTransferable
import UniformTypeIdentifiers

/// 转移文件的分享载荷。字节留在内存里，系统要的时候再交出去，不落临时文件。
struct DeviceTransferShareItem: Transferable, Sendable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: TollcatUTType.utType) { item in
            item.data
        }
        .suggestedFileName("TollCat-transfer.tollcat")
    }
}
