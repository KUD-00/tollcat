enum ProvidersRenderer {
    static func render(_ catalog: CatalogDocument) -> String {
        let offered = catalog.offered
        guard !offered.isEmpty else { return "" }
        let idWidth = offered.map { TextWidth.displayWidth($0.id) }.max() ?? 8
        let nameWidth = offered.map { TextWidth.displayWidth($0.displayName) }.max() ?? 8
        return offered.map { provider in
            let id = TextWidth.pad(provider.id, idWidth)
            let name = TextWidth.pad(provider.displayName, nameWidth)
            return "\(id)  \(name)  \(provider.summary)"
        }
        .joined(separator: "\n")
    }
}
