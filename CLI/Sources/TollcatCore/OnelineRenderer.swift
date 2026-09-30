import MeterBridge

enum OnelineRenderer {
    static func render(_ document: DashboardDocument, localeTag: String) -> String {
        if document.empty {
            return "—"
        }
        let total = document.formattedTotal
        guard let projected = document.formattedProjected else {
            return total
        }
        switch document.comparisonTone {
        case "up":
            return JNICopy.format("%@ ↗ 预计 %@", localeTag, total, projected)
        case "down":
            return JNICopy.format("%@ ↘ 预计 %@", localeTag, total, projected)
        default:
            return JNICopy.format("%@ · 预计 %@", localeTag, total, projected)
        }
    }
}
