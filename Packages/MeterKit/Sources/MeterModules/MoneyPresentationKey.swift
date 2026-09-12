import SwiftUI
import MeterCore

private struct MoneyPresentationKey: EnvironmentKey {
    static let defaultValue = MoneyPresentation.usd
}

public extension EnvironmentValues {
    public var moneyPresentation: MoneyPresentation {
        get { self[MoneyPresentationKey.self] }
        set { self[MoneyPresentationKey.self] = newValue }
    }
}
