import SwiftUI

/// 打赏三档的东西：糖果、咖啡、披萨。和猫一样走 Canvas，不读 SVG 文件。
enum TipTreatArtwork {
    static let viewBox = CGSize(width: 160, height: 118)

    /// 每档占的画面。三档横向都居中，面积相近——并排放时视觉重量才不打架。
    static func bounds(for kind: TipTreatKind) -> CGRect {
        switch kind {
        case .candy: CGRect(x: 24, y: 33, width: 112, height: 52)
        case .coffee: CGRect(x: 46, y: 22, width: 68, height: 74)
        case .pizza: CGRect(x: 36, y: 24, width: 88, height: 72)
        }
    }

    static func draw(
        _ kind: TipTreatKind,
        in context: inout GraphicsContext,
        canvas: CGSize,
        scheme: ColorScheme
    ) {
        let unit = min(
            canvas.width / viewBox.width,
            canvas.height / viewBox.height
        )
        let offset = CGSize(
            width: (canvas.width - viewBox.width * unit) / 2,
            height: (canvas.height - viewBox.height * unit) / 2
        )
        context.translateBy(x: offset.width, y: offset.height)
        context.scaleBy(x: unit, y: unit)

        let rect = bounds(for: kind)
        switch kind {
        case .candy: drawCandy(in: &context, rect: rect, scheme: scheme)
        case .coffee: drawCoffee(in: &context, rect: rect, scheme: scheme)
        case .pizza: drawPizza(in: &context, rect: rect, scheme: scheme)
        }
    }

    private static func drawCandy(
        in context: inout GraphicsContext,
        rect: CGRect,
        scheme: ColorScheme
    ) {
        let palette = MeterColor.tipTreat(for: scheme)
        let radius = rect.height / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var wrappers = Path()
        for side in [CGFloat(-1), 1] {
            let tip = CGPoint(x: center.x + side * rect.width / 2, y: center.y)
            wrappers.move(to: CGPoint(x: center.x + side * radius * 0.86, y: center.y))
            wrappers.addLine(to: CGPoint(x: tip.x, y: tip.y - rect.height * 0.42))
            wrappers.addLine(to: CGPoint(x: tip.x, y: tip.y + rect.height * 0.42))
            wrappers.closeSubpath()
        }
        context.fill(wrappers, with: .color(palette.candyWrapper))

        let body = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(body, with: .color(palette.candy))
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - radius * 0.62,
                y: center.y - radius * 0.66,
                width: radius * 0.7,
                height: radius * 0.46
            )),
            with: .color(Color.white.opacity(scheme == .dark ? 0.28 : 0.42))
        )
    }

    private static func drawCoffee(
        in context: inout GraphicsContext,
        rect: CGRect,
        scheme: ColorScheme
    ) {
        let palette = MeterColor.tipTreat(for: scheme)

        let lidTop = rect.minY + rect.height * 0.08
        let bodyTop = rect.minY + rect.height * 0.24
        let topHalf = rect.width * 0.44
        let bottomHalf = rect.width * 0.34

        func halfWidth(at y: CGFloat) -> CGFloat {
            let t = (y - bodyTop) / (rect.maxY - bodyTop)
            return topHalf + (bottomHalf - topHalf) * t
        }

        var cup = Path()
        cup.move(to: CGPoint(x: rect.midX - topHalf, y: bodyTop))
        cup.addLine(to: CGPoint(x: rect.midX + topHalf, y: bodyTop))
        cup.addLine(to: CGPoint(x: rect.midX + bottomHalf, y: rect.maxY))
        cup.addLine(to: CGPoint(x: rect.midX - bottomHalf, y: rect.maxY))
        cup.closeSubpath()
        context.fill(cup, with: .color(palette.cupPaper))

        let sleeveTop = bodyTop + (rect.maxY - bodyTop) * 0.3
        let sleeveBottom = bodyTop + (rect.maxY - bodyTop) * 0.62
        var sleeve = Path()
        sleeve.move(to: CGPoint(x: rect.midX - halfWidth(at: sleeveTop), y: sleeveTop))
        sleeve.addLine(to: CGPoint(x: rect.midX + halfWidth(at: sleeveTop), y: sleeveTop))
        sleeve.addLine(to: CGPoint(x: rect.midX + halfWidth(at: sleeveBottom), y: sleeveBottom))
        sleeve.addLine(to: CGPoint(x: rect.midX - halfWidth(at: sleeveBottom), y: sleeveBottom))
        sleeve.closeSubpath()
        context.fill(sleeve, with: .color(palette.cupSleeve))

        let tab = Path(roundedRect: CGRect(
            x: rect.midX - rect.width * 0.13,
            y: rect.minY,
            width: rect.width * 0.26,
            height: lidTop - rect.minY + 2
        ), cornerRadius: 2.4)
        context.fill(tab, with: .color(palette.cupLid))

        let lid = Path(roundedRect: CGRect(
            x: rect.minX,
            y: lidTop,
            width: rect.width,
            height: bodyTop - lidTop
        ), cornerRadius: 4.5)
        context.fill(lid, with: .color(palette.cupLid))

        context.fill(
            Path(roundedRect: CGRect(
                x: rect.midX - topHalf * 0.78,
                y: bodyTop + rect.height * 0.1,
                width: rect.width * 0.08,
                height: rect.height * 0.44
            ), cornerRadius: 3),
            with: .color(Color.white.opacity(0.22))
        )
    }

    private static func drawPizza(
        in context: inout GraphicsContext,
        rect: CGRect,
        scheme: ColorScheme
    ) {
        let palette = MeterColor.tipTreat(for: scheme)

        let crustHeight = rect.height * 0.22
        let cheeseTop = rect.minY + crustHeight

        var slice = Path()
        slice.move(to: CGPoint(x: rect.minX + rect.width * 0.03, y: cheeseTop))
        slice.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.03, y: cheeseTop))
        slice.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        slice.closeSubpath()
        context.fill(slice, with: .color(palette.cheese))

        let crust = Path(roundedRect: CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: crustHeight
        ), cornerRadius: crustHeight / 2)
        context.fill(crust, with: .color(palette.crust))
        context.stroke(crust, with: .color(palette.crustEdge), lineWidth: 1.2)

        let toppings: [(CGPoint, CGFloat)] = [
            (CGPoint(x: rect.midX - rect.width * 0.18, y: cheeseTop + rect.height * 0.24), rect.width * 0.082),
            (CGPoint(x: rect.midX + rect.width * 0.19, y: cheeseTop + rect.height * 0.19), rect.width * 0.07),
            (CGPoint(x: rect.midX, y: cheeseTop + rect.height * 0.5), rect.width * 0.062),
        ]
        for (center, radius) in toppings {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .color(palette.pepperoni)
            )
        }
    }
}
