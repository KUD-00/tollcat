import Foundation
import Testing
@testable import MeterTips

struct TipProductIDTests {
    @Test("三档 ID 是消耗型产品约定的那一组")
    func productIDsMatchStorekit() {
        #expect(TipProductID.small.rawValue == "com.zhechengqi.tollcat.tip.small")
        #expect(TipProductID.medium.rawValue == "com.zhechengqi.tollcat.tip.medium")
        #expect(TipProductID.large.rawValue == "com.zhechengqi.tollcat.tip.large")
        #expect(TipProductID.allCases.count == 3)
        #expect(Set(TipProductID.allRawValues).count == 3)
    }

    @Test("档位名不是价格")
    func listTitlesAreNotPrices() {
        for id in TipProductID.allCases {
            #expect(!id.listTitle.contains("¥"))
            #expect(!id.listTitle.contains("$"))
            #expect(!id.listTitle.contains("￥"))
        }
    }
}
