import Foundation

/// 隐私、支持和源码。编译死在 App 里，不从远程目录来。
enum LegalURL {
    static var privacy: URL { page("privacy") }
    static var support: URL { page("support") }
    static let source = URL(string: "https://github.com/KUD-00/tollcat")!

    static func page(
        _ slug: String,
        languageCode: String? = Locale.current.language.languageCode?.identifier
    ) -> URL {
        URL(string: "https://tollcat.app\(pathPrefix(languageCode))/\(slug)/")!
    }

    static func pathPrefix(_ languageCode: String?) -> String {
        switch languageCode {
        case "en": "/en"
        case "ja": "/ja"
        default: ""
        }
    }
}
