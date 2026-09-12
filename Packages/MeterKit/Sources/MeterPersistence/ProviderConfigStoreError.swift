import Foundation
import MeterCore

public enum ProviderConfigStoreError: Error, Equatable, Sendable {
    case accountNotFound(AccountID)
}
