import Testing
import Foundation
@testable import MeterDesign

@Suite("CatSquashAnchor")
struct CatSquashAnchorTests {
    private let canvas = CGSize(width: 100, height: 80)

    @Test("压扁时底边中点不动，脚还在原地")
    func bottomCenterStaysPlanted() {
        let planted = CGPoint(x: 50, y: 80)
        let mapped = CatSquashAnchor.map(
            planted,
            canvas: canvas,
            scaleX: 1 + CatMotion.flatten,
            scaleY: 1 - CatMotion.flatten
        )
        #expect(abs(mapped.x - planted.x) < 0.001)
        #expect(abs(mapped.y - planted.y) < 0.001)
    }

    @Test("变扁向左右两侧胀，不是整只往右挤")
    func flattenExpandsBothSides() {
        let left = CatSquashAnchor.map(CGPoint(x: 20, y: 40), canvas: canvas, scaleX: 1.10, scaleY: 1)
        let right = CatSquashAnchor.map(CGPoint(x: 80, y: 40), canvas: canvas, scaleX: 1.10, scaleY: 1)
        #expect(left.x < 20)
        #expect(right.x > 80)
        #expect(abs((50 - left.x) - (right.x - 50)) < 0.001)
    }

    @Test("左下角不再是锚点：变扁时它会往左走")
    func bottomLeftMovesOutward() {
        let mapped = CatSquashAnchor.map(
            CGPoint(x: 0, y: 80),
            canvas: canvas,
            scaleX: 1.10,
            scaleY: 1
        )
        #expect(mapped.x < -0.5)
        #expect(abs(mapped.y - 80) < 0.001)
    }

    @Test("拉长时左右往中间收，仍然对称")
    func stretchShrinksTowardCenter() {
        let left = CatSquashAnchor.map(CGPoint(x: 20, y: 40), canvas: canvas, scaleX: 0.94, scaleY: 1.12)
        let right = CatSquashAnchor.map(CGPoint(x: 80, y: 40), canvas: canvas, scaleX: 0.94, scaleY: 1.12)
        #expect(left.x > 20)
        #expect(right.x < 80)
        #expect(abs((50 - left.x) - (right.x - 50)) < 0.001)
    }
}
