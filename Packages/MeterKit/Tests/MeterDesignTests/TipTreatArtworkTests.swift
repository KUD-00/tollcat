import CoreGraphics
import Testing
@testable import MeterDesign

struct TipTreatArtworkTests {
    @Test("三档各占一块画面，都在 viewBox 里、横向居中")
    func boundsStayCenteredInsideViewBox() {
        let box = CGRect(origin: .zero, size: TipTreatArtwork.viewBox)
        #expect(TipTreatKind.allCases.count == 3)
        for kind in TipTreatKind.allCases {
            let bounds = TipTreatArtwork.bounds(for: kind)
            #expect(box.contains(bounds))
            #expect(bounds.midX == box.midX)
        }
    }

    @Test("三档面积相近，并排时视觉重量不打架")
    func boundsAreasStayComparable() throws {
        let areas = TipTreatKind.allCases.map { kind in
            let bounds = TipTreatArtwork.bounds(for: kind)
            return bounds.width * bounds.height
        }
        let largest = try #require(areas.max())
        let smallest = try #require(areas.min())
        #expect(largest / smallest <= 1.4)
    }
}
