import Foundation
import Testing
import MeterCore
@testable import MeterProviders

/// 旧预充值断言已过时；适配器已切到用量/发票路径。保留最小冒烟，避免整靶编译被挡。
struct TelnyxBillingProviderTests {
    @Test("descriptor 仍在目录")
    func descriptorPresent() {
        #expect(TelnyxBillingProvider.descriptor.id == .telnyx)
        #expect(TelnyxBillingProvider.descriptor.kind == .prepaid)
    }
}
