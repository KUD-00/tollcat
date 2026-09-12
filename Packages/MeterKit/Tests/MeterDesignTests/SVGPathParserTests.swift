import SwiftUI
import Testing
@testable import MeterDesign

@Suite("SVGPathParser")
struct SVGPathParserTests {
    // MARK: - M / m

    @Test("绝对 M 把起点放到给定坐标")
    func absoluteMove() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 10 20"))
        #expect(elements.count == 1)
        expectElement(elements, 0, .move(x: 10, y: 20))
    }

    @Test("路径开头的相对 m 相对原点，等价于绝对 M")
    func leadingRelativeMoveFromOrigin() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "m 10 20"))
        #expect(elements.count == 1)
        expectElement(elements, 0, .move(x: 10, y: 20))
    }

    @Test("后续相对 m 以当前点为原点开启新子路径")
    func relativeMoveAfterAbsolute() {
        // SwiftUI Path 会丢掉没有画线的前一个 move，所以紧跟一段 L 钉住第二个子路径。
        // (3, 4) + (1, −2) = (4, 2)，再绝对 L 到 (6, 7)。
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 3 4 m 1 -2 L 6 7"))
        #expect(
            elements.contains { element in
                if case .move(let x, let y) = element {
                    return abs(x - 4) <= 0.001 && abs(y - 2) <= 0.001
                }
                return false
            }
        )
        #expect(
            elements.contains { element in
                if case .line(let x, let y) = element {
                    return abs(x - 6) <= 0.001 && abs(y - 7) <= 0.001
                }
                return false
            }
        )
    }

    @Test("M 后多余的坐标对按规范变成绝对 L")
    func implicitLineAfterMove() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 3 4 8 9"))
        #expect(elements.count == 2)
        expectElement(elements, 0, .move(x: 3, y: 4))
        expectElement(elements, 1, .line(x: 8, y: 9))
    }

    @Test("m 后多余的坐标对变成相对 l")
    func implicitRelativeLineAfterRelativeMove() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "m 10 20 5 5"))
        #expect(elements.count == 2)
        expectElement(elements, 0, .move(x: 10, y: 20))
        expectElement(elements, 1, .line(x: 15, y: 25))
    }

    // MARK: - L / H / V

    @Test("L 画到绝对终点")
    func absoluteLine() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 0 0 L 10 5"))
        #expect(elements.count == 2)
        expectElement(elements, 0, .move(x: 0, y: 0))
        expectElement(elements, 1, .line(x: 10, y: 5))
    }

    @Test("l 相对当前点平移")
    func relativeLine() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 5 5 l 3 4"))
        #expect(elements.count == 2)
        expectElement(elements, 1, .line(x: 8, y: 9))
    }

    @Test("H / V 只改一个轴，相对形式从当前点累加")
    func horizontalAndVertical() {
        // (4, 5) → (9, 5) → (9, 8) → (7, 8) → (7, 7)
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 4 5 H 9 V 8 h -2 v -1")
        )
        #expect(elements.count == 5)
        expectElement(elements, 0, .move(x: 4, y: 5))
        expectElement(elements, 1, .line(x: 9, y: 5))
        expectElement(elements, 2, .line(x: 9, y: 8))
        expectElement(elements, 3, .line(x: 7, y: 8))
        expectElement(elements, 4, .line(x: 7, y: 7))
    }

    @Test("重复的 H 数字沿用上一命令")
    func implicitRepeatedHorizontal() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 0 5 H 10 20"))
        #expect(elements.count == 3)
        expectElement(elements, 1, .line(x: 10, y: 5))
        expectElement(elements, 2, .line(x: 20, y: 5))
    }

    // MARK: - C / c

    @Test("绝对三次贝塞尔的终点和控制点就是参数本身")
    func absoluteCubic() {
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 0 0 C 1 2 3 4 5 6")
        )
        #expect(elements.count == 2)
        expectElement(elements, 0, .move(x: 0, y: 0))
        expectElement(
            elements,
            1,
            .curve(toX: 5, toY: 6, control1X: 1, control1Y: 2, control2X: 3, control2Y: 4)
        )
    }

    @Test("相对三次贝塞尔的三个点都加上当前点")
    func relativeCubic() {
        // 当前点 (2, 3) + (1, 1) / (2, 2) / (3, 3) → (3, 4) / (4, 5) / (5, 6)
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 2 3 c 1 1 2 2 3 3")
        )
        #expect(elements.count == 2)
        expectElement(
            elements,
            1,
            .curve(toX: 5, toY: 6, control1X: 3, control1Y: 4, control2X: 4, control2Y: 5)
        )
    }

    @Test("C 后多余的 6 个数是另一段绝对三次贝塞尔")
    func implicitSecondCubic() {
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 0 0 C 1 1 2 2 3 3 4 4 5 5 6 6")
        )
        #expect(elements.count == 3)
        expectElement(
            elements,
            1,
            .curve(toX: 3, toY: 3, control1X: 1, control1Y: 1, control2X: 2, control2Y: 2)
        )
        expectElement(
            elements,
            2,
            .curve(toX: 6, toY: 6, control1X: 4, control1Y: 4, control2X: 5, control2Y: 5)
        )
    }

    // MARK: - Z

    @Test("Z 闭合子路径，随后的画笔回到子路径起点")
    func closeReturnsToSubpathStart() {
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 2 3 L 8 9 Z L 4 5")
        )
        #expect(elements.count == 4)
        expectElement(elements, 0, .move(x: 2, y: 3))
        expectElement(elements, 1, .line(x: 8, y: 9))
        if let close = element(at: 2, in: elements) {
            #expect(close == .close)
        }
        // Z 之后 current = (2, 3)，L 4 5 从起点再出发，而不是从 (8, 9)
        expectElement(elements, 3, .line(x: 4, y: 5))
    }

    @Test("z 与 Z 相同")
    func lowercaseClose() {
        let elements = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 1 1 L 2 2 z"))
        #expect(elements.last == .close)
    }

    // MARK: - A：large-arc × sweep 四个组合

    /// 圆 r = 10，从 (0, 0) 到 (10, 0)，φ = 0。
    ///
    /// 弦中点 (5, 0)，半弦长 5，圆心到弦的距离 √(10² − 5²) = 5√3。
    /// 两个圆心：(5, −5√3) 与 (5, +5√3)。
    ///
    /// 按 W3C `implnote.html#ArcImplementationNotes`：
    /// `sign(cx', cy') = (large == sweep) ? −1 : +1`，φ = 0 时圆心 y = sign · 5√3。
    /// 再按同一笔记展开 Δθ（sweep = 0 且 Δθ > 0 则减 2π；sweep = 1 且 Δθ < 0 则加 2π）。
    ///
    /// 弧上离弦最远的点（也是中点）因此是：
    /// - 0 0 → (5,  10 − 5√3) ≈ (5,  1.340)   短弧、y 正侧
    /// - 0 1 → (5, −10 + 5√3) ≈ (5, −1.340)   短弧、y 负侧
    /// - 1 0 → (5,  10 + 5√3) ≈ (5, 18.660)   长弧、y 正侧
    /// - 1 1 → (5, −10 − 5√3) ≈ (5, −18.660)  长弧、y 负侧
    ///
    /// flag 任一个搞反，最远点会换侧或从「贴着弦」变成「绕远路」。
    @Test("A 弧线 four flag 组合：最远点落在手算的那一侧")
    func arcFourFlagCombinations() {
        let small = 10 - 5 * CGFloat(3).squareRoot()
        let large = 10 + 5 * CGFloat(3).squareRoot()

        let cases: [(large: Int, sweep: Int, expectedY: CGFloat)] = [
            (0, 0, small),
            (0, 1, -small),
            (1, 0, large),
            (1, 1, -large),
        ]

        for item in cases {
            let d = "M 0 0 A 10 10 0 \(item.large) \(item.sweep) 10 0"
            let path = SVGPathParser.path(from: d)
            let farthest = SVGPathInspection.farthestFromXAxis(on: path)

            #expect(farthest != nil, "A \(item.large) \(item.sweep) 应解析出曲线")
            guard let farthest else { continue }

            #expect(
                abs(farthest.x - 5) < 0.35,
                "A \(item.large) \(item.sweep) 最远点应在弦中垂线上，x=\(farthest.x)"
            )
            #expect(
                farthest.y * item.expectedY > 0,
                "A \(item.large) \(item.sweep) 最远点 y=\(farthest.y) 应与期望 \(item.expectedY) 同侧"
            )
            #expect(
                abs(abs(farthest.y) - abs(item.expectedY)) < 0.4,
                "A \(item.large) \(item.sweep) 最远点 |y|=\(abs(farthest.y)) 应对上 \(abs(item.expectedY))"
            )

            let end = SVGPathInspection.endPoint(of: path)
            #expect(end != nil)
            if let end {
                #expect(abs(end.x - 10) < 0.001)
                #expect(abs(end.y - 0) < 0.001)
            }
        }
    }

    @Test("相对 a 的终点是当前点加上偏移")
    func relativeArcEndPoint() {
        let path = SVGPathParser.path(from: "M 2 3 a 10 10 0 0 0 10 0")
        let end = SVGPathInspection.endPoint(of: path)
        #expect(end != nil)
        if let end {
            #expect(abs(end.x - 12) < 0.001)
            #expect(abs(end.y - 3) < 0.001)
        }
    }

    @Test("半径为 0 的 A 退化成直线，不崩")
    func zeroRadiusArcBecomesLine() {
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 0 0 A 0 5 0 0 0 10 10")
        )
        #expect(elements.count == 2)
        expectElement(elements, 1, .line(x: 10, y: 10))
    }

    // MARK: - 畸形输入

    @Test("命令后参数不足时停在已解析部分，不 crash")
    func incompleteCommandsDoNotCrash() {
        let samples = [
            "",
            "   ",
            ",,,",
            "M",
            "M 1",
            "M 1 2 L",
            "M 1 2 C 1 2 3",
            "M 1 2 A 5 5 0 1",
            "M 1 2 Q 3 4 5 6",
            "M 1 2 @@ L 3 4",
            "hello",
            "M 1e+ 2",
            "M 1 2 G 3 4",
        ]
        for sample in samples {
            let path = SVGPathParser.path(from: sample)
            _ = path.boundingRect
            _ = SVGPathInspection.elements(of: path)
        }
    }

    @Test("多余空白和逗号分隔都能读出同一条折线")
    func whitespaceAndCommas() {
        let compact = SVGPathInspection.elements(of: SVGPathParser.path(from: "M1,2L3,4"))
        let padded = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "  M   1 , 2   L  3,4  ")
        )
        #expect(compact.count == 2)
        #expect(padded.count == 2)
        expectElement(compact, 0, .move(x: 1, y: 2))
        expectElement(compact, 1, .line(x: 3, y: 4))
        expectElement(padded, 0, .move(x: 1, y: 2))
        expectElement(padded, 1, .line(x: 3, y: 4))
    }

    @Test("科学计数法按字面指数求值")
    func scientificNotation() {
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 1.25e1 -2E-1 L 3.0e+1 4.5e-1")
        )
        #expect(elements.count == 2)
        expectElement(elements, 0, .move(x: 12.5, y: -0.2))
        expectElement(elements, 1, .line(x: 30, y: 0.45))
    }

    @Test("省略整数部分的小数、以及 10.20.30 这种连写")
    func leadingDotAndPackedDecimals() {
        let dotted = SVGPathInspection.elements(of: SVGPathParser.path(from: "M.5.5"))
        #expect(dotted.count == 1)
        expectElement(dotted, 0, .move(x: 0.5, y: 0.5))

        let packed = SVGPathInspection.elements(of: SVGPathParser.path(from: "M 10.20.30"))
        #expect(packed.count == 1)
        expectElement(packed, 0, .move(x: 10.20, y: 0.30))
    }

    @Test("参数不足的 M 得到空路径，而不是半个点")
    func incompleteMoveYieldsEmptyPath() {
        #expect(SVGPathParser.path(from: "M 1").isEmpty)
        #expect(SVGPathParser.path(from: "M").isEmpty)
    }

    @Test("眼镜镜片：evenodd 挖空镜片、留下镜框。fill-rule 是填充属性，不是 d 命令")
    func glassesEvenOddPunchesLensHole() {
        let d = CatArtwork.glassesLenses[0]
        let path = SVGPathParser.path(from: d)
        // 左镜片中心 (436, 556)；外椭圆 ry=62、内椭圆 ry=46，
        // (436, 502) 落在两圈之间的框上。
        let hole = CGPoint(x: 436, y: 556)
        let rim = CGPoint(x: 436, y: 502)
        #expect(!path.contains(hole, eoFill: true))
        #expect(path.contains(rim, eoFill: true))
    }

    @Test("Q 二次贝塞尔的终点是第三个点")
    func quadraticEndPoint() {
        let end = SVGPathInspection.endPoint(of: SVGPathParser.path(from: "M 0 0 Q 10 0 10 10"))
        #expect(end != nil)
        if let end {
            #expect(abs(end.x - 10) < 0.001)
            #expect(abs(end.y - 10) < 0.001)
        }
    }

    @Test("S 的第一控制点是上一段 C 的反射")
    func smoothCubicReflectsPrevious() {
        // C 的第二控制点 (2, 0)，当前点 (4, 0)，反射是 (6, 0)。
        let elements = SVGPathInspection.elements(
            of: SVGPathParser.path(from: "M 0 0 C 0 2 2 0 4 0 S 8 2 8 0")
        )
        #expect(
            elements.contains { element in
                if case .curve(let toX, let toY, let c1x, let c1y, _, _) = element {
                    return abs(toX - 8) < 0.001
                        && abs(toY - 0) < 0.001
                        && abs(c1x - 6) < 0.001
                        && abs(c1y - 0) < 0.001
                }
                return false
            }
        )
    }

    @Test("弧线 flag 可以和后续坐标连写")
    func gluedArcFlags() {
        let spaced = SVGPathInspection.endPoint(of: SVGPathParser.path(from: "M 0 0 A 10 10 0 0 1 10 0"))
        let glued = SVGPathInspection.endPoint(of: SVGPathParser.path(from: "M 0 0 A 10 10 0 0110 0"))
        #expect(spaced != nil && glued != nil)
        if let spaced, let glued {
            #expect(abs(spaced.x - glued.x) < 0.001)
            #expect(abs(spaced.y - glued.y) < 0.001)
            #expect(abs(glued.x - 10) < 0.001)
            #expect(abs(glued.y - 0) < 0.001)
        }
    }
}

private enum SVGPathElement: Equatable {
    case move(x: CGFloat, y: CGFloat)
    case line(x: CGFloat, y: CGFloat)
    case curve(
        toX: CGFloat,
        toY: CGFloat,
        control1X: CGFloat,
        control1Y: CGFloat,
        control2X: CGFloat,
        control2Y: CGFloat
    )
    case close

    var point: CGPoint? {
        switch self {
        case .move(let x, let y), .line(let x, let y), .curve(let x, let y, _, _, _, _):
            return CGPoint(x: x, y: y)
        case .close:
            return nil
        }
    }
}

private enum SVGPathInspection {
    static func elements(of path: Path) -> [SVGPathElement] {
        var result: [SVGPathElement] = []
        path.cgPath.applyWithBlock { element in
            let points = element.pointee.points
            switch element.pointee.type {
            case .moveToPoint:
                result.append(.move(x: points[0].x, y: points[0].y))
            case .addLineToPoint:
                result.append(.line(x: points[0].x, y: points[0].y))
            case .addQuadCurveToPoint:
                result.append(
                    .curve(
                        toX: points[1].x,
                        toY: points[1].y,
                        control1X: points[0].x,
                        control1Y: points[0].y,
                        control2X: points[0].x,
                        control2Y: points[0].y
                    )
                )
            case .addCurveToPoint:
                result.append(
                    .curve(
                        toX: points[2].x,
                        toY: points[2].y,
                        control1X: points[0].x,
                        control1Y: points[0].y,
                        control2X: points[1].x,
                        control2Y: points[1].y
                    )
                )
            case .closeSubpath:
                result.append(.close)
            @unknown default:
                break
            }
        }
        return result
    }

    static func endPoint(of path: Path) -> CGPoint? {
        elements(of: path).last?.point
    }

    /// 在展开后的三次贝塞尔上均匀取样，取 |y| 最大的点。
    /// 对「弦在 x 轴上」的单位测试弧，这就是离弦最远、也最能区分 flag 的点。
    static func farthestFromXAxis(on path: Path) -> CGPoint? {
        var current = CGPoint.zero
        var farthest: CGPoint?
        var farthestAbsY: CGFloat = -1

        func consider(_ point: CGPoint) {
            let absY = abs(point.y)
            if absY > farthestAbsY {
                farthestAbsY = absY
                farthest = point
            }
        }

        for element in elements(of: path) {
            switch element {
            case .move(let x, let y):
                current = CGPoint(x: x, y: y)
            case .line(let x, let y):
                let point = CGPoint(x: x, y: y)
                consider(point)
                current = point
            case .curve(let toX, let toY, let c1x, let c1y, let c2x, let c2y):
                let to = CGPoint(x: toX, y: toY)
                let control1 = CGPoint(x: c1x, y: c1y)
                let control2 = CGPoint(x: c2x, y: c2y)
                for step in 1...24 {
                    let t = CGFloat(step) / 24
                    consider(cubic(from: current, control1: control1, control2: control2, to: to, t: t))
                }
                current = to
            case .close:
                break
            }
        }
        return farthest
    }

    static func cubic(
        from start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        to end: CGPoint,
        t: CGFloat
    ) -> CGPoint {
        let u = 1 - t
        let uu = u * u
        let uuu = uu * u
        let tt = t * t
        let ttt = tt * t
        return CGPoint(
            x: uuu * start.x + 3 * uu * t * control1.x + 3 * u * tt * control2.x + ttt * end.x,
            y: uuu * start.y + 3 * uu * t * control1.y + 3 * u * tt * control2.y + ttt * end.y
        )
    }
}

private func element(at index: Int, in elements: [SVGPathElement]) -> SVGPathElement? {
    guard elements.indices.contains(index) else {
        Issue.record("缺少第 \(index) 个元素，实际只有 \(elements.count) 个")
        return nil
    }
    return elements[index]
}

private func expectElement(
    _ elements: [SVGPathElement],
    _ index: Int,
    _ expected: SVGPathElement,
    epsilon: CGFloat = 0.001
) {
    guard let element = element(at: index, in: elements) else { return }
    expectPoint(element, expected, epsilon: epsilon)
}

private func expectPoint(
    _ element: SVGPathElement,
    _ expected: SVGPathElement,
    epsilon: CGFloat = 0.001
) {
    switch (element, expected) {
    case (.move(let gx, let gy), .move(let wx, let wy)),
         (.line(let gx, let gy), .line(let wx, let wy)):
        #expect(abs(gx - wx) <= epsilon && abs(gy - wy) <= epsilon)
    case (
        .curve(let gtx, let gty, let gc1x, let gc1y, let gc2x, let gc2y),
        .curve(let wtx, let wty, let wc1x, let wc1y, let wc2x, let wc2y)
    ):
        #expect(abs(gtx - wtx) <= epsilon && abs(gty - wty) <= epsilon)
        #expect(abs(gc1x - wc1x) <= epsilon && abs(gc1y - wc1y) <= epsilon)
        #expect(abs(gc2x - wc2x) <= epsilon && abs(gc2y - wc2y) <= epsilon)
    default:
        Issue.record("路径元素类型对不上：\(element) vs \(expected)")
    }
}
