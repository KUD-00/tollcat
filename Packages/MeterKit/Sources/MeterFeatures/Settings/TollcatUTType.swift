import UniformTypeIdentifiers

enum TollcatUTType {
    static let identifier = "com.zhechengqi.tollcat.transfer"

    static var utType: UTType {
        UTType(exportedAs: identifier, conformingTo: .data)
    }
}
