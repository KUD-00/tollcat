import MeterCore
import MeterProviders

struct AddProviderCatalogSection: Equatable, Identifiable {
    var category: ProviderCategory?
    var descriptors: [ProviderDescriptor]

    var id: String { category?.rawValue ?? "flat" }
}
