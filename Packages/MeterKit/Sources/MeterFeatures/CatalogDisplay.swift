import Foundation
import MeterCore

/// Features 侧把 `Locale.current` 收口成目录语言。MeterCore 只收语言标签。
enum CatalogDisplay {
    static var language: CatalogLanguage {
        CatalogLanguage.resolving(localeTag: Locale.current.identifier)
    }
}
