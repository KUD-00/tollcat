enum SetupWizardStep: Hashable {
    case guide
    case credentials

    var displayNumber: Int {
        switch self {
        case .guide: 1
        case .credentials: 2
        }
    }

    static var totalCount: Int { 2 }
}
