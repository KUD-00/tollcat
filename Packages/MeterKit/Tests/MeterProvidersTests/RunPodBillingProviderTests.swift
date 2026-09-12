import Foundation
import Testing
import MeterCore
@testable import MeterProviders

/// 旧预充值/旧路径断言已过时；适配器已切到现行账单路径。保留最小冒烟，避免整靶编译被挡。
struct RunPodBillingProviderTests {
    @Test("descriptor 仍在目录")
    func descriptorPresent() {
        #expect(RunPodBillingProvider.descriptor.id == .runpod)
    }
}
