import SwiftUI

/// Simple Icons 的 `d` 含 M/L/H/V/C/S/Q/T/A/Z（及相对形式）。
/// 弧按 W3C 实现笔记展成三次贝塞尔，这样 SwiftUI `Path` 不用自己画椭圆弧。
enum SVGPathParser {
    static func path(from d: String) -> Path {
        var path = Path()
        var tokens = tokenize(d)
        var index = 0
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastCommand: Character?
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?

        func nextNumber() -> CGFloat? {
            guard index < tokens.count, case .number(let value, _) = tokens[index] else { return nil }
            index += 1
            return value
        }

        /// `a … 0 014.147 4.148` 里的 `01` 是两个 flag，必须拆开，不能当成 14.147。
        func nextFlag() -> CGFloat? {
            guard index < tokens.count, case .number(_, let raw) = tokens[index] else { return nil }
            guard let first = raw.first, first == "0" || first == "1" else { return nil }
            let rest = String(raw.dropFirst())
            if rest.isEmpty {
                index += 1
            } else if let value = Double(rest) {
                tokens[index] = .number(CGFloat(value), raw: rest)
            } else {
                return nil
            }
            return first == "1" ? 1 : 0
        }

        func nextPoint(relative: Bool) -> CGPoint? {
            guard let x = nextNumber(), let y = nextNumber() else { return nil }
            if relative {
                return CGPoint(x: current.x + x, y: current.y + y)
            }
            return CGPoint(x: x, y: y)
        }

        func reflect(_ point: CGPoint) -> CGPoint {
            CGPoint(x: 2 * current.x - point.x, y: 2 * current.y - point.y)
        }

        func clearSmoothControls() {
            lastCubicControl = nil
            lastQuadControl = nil
        }

        while index < tokens.count {
            let command: Character
            if case .command(let character) = tokens[index] {
                command = character
                index += 1
                lastCommand = character
            } else if let last = lastCommand {
                // 后续坐标对沿用上一命令；M/m 之后按规范变成 L/l。
                switch last {
                case "M": command = "L"
                case "m": command = "l"
                default: command = last
                }
            } else {
                break
            }

            switch command {
            case "M", "m":
                guard let point = nextPoint(relative: command == "m") else { return path }
                path.move(to: point)
                current = point
                start = point
                lastCommand = command
                clearSmoothControls()
            case "L", "l":
                guard let point = nextPoint(relative: command == "l") else { return path }
                path.addLine(to: point)
                current = point
                clearSmoothControls()
            case "H", "h":
                guard let x = nextNumber() else { return path }
                let point = CGPoint(x: command == "h" ? current.x + x : x, y: current.y)
                path.addLine(to: point)
                current = point
                clearSmoothControls()
            case "V", "v":
                guard let y = nextNumber() else { return path }
                let point = CGPoint(x: current.x, y: command == "v" ? current.y + y : y)
                path.addLine(to: point)
                current = point
                clearSmoothControls()
            case "C", "c":
                let relative = command == "c"
                guard
                    let control1 = nextPoint(relative: relative),
                    let control2 = nextPoint(relative: relative),
                    let point = nextPoint(relative: relative)
                else { return path }
                path.addCurve(to: point, control1: control1, control2: control2)
                current = point
                lastCubicControl = control2
                lastQuadControl = nil
            case "S", "s":
                let relative = command == "s"
                let control1 = lastCubicControl.map(reflect) ?? current
                guard
                    let control2 = nextPoint(relative: relative),
                    let point = nextPoint(relative: relative)
                else { return path }
                path.addCurve(to: point, control1: control1, control2: control2)
                current = point
                lastCubicControl = control2
                lastQuadControl = nil
            case "Q", "q":
                let relative = command == "q"
                guard
                    let control = nextPoint(relative: relative),
                    let point = nextPoint(relative: relative)
                else { return path }
                path.addQuadCurve(to: point, control: control)
                current = point
                lastQuadControl = control
                lastCubicControl = nil
            case "T", "t":
                let relative = command == "t"
                let control = lastQuadControl.map(reflect) ?? current
                guard let point = nextPoint(relative: relative) else { return path }
                path.addQuadCurve(to: point, control: control)
                current = point
                lastQuadControl = control
                lastCubicControl = nil
            case "A", "a":
                guard
                    let rx = nextNumber(),
                    let ry = nextNumber(),
                    let phi = nextNumber(),
                    let large = nextFlag(),
                    let sweep = nextFlag(),
                    let point = nextPoint(relative: command == "a")
                else { return path }
                appendArc(
                    to: &path,
                    from: current,
                    rx: Double(rx),
                    ry: Double(ry),
                    phiDegrees: Double(phi),
                    largeArc: large != 0,
                    sweep: sweep != 0,
                    to: point
                )
                current = point
                clearSmoothControls()
            case "Z", "z":
                path.closeSubpath()
                current = start
                clearSmoothControls()
            default:
                return path
            }
        }
        return path
    }

    private enum Token {
        case command(Character)
        case number(CGFloat, raw: String)
    }

    private static func tokenize(_ d: String) -> [Token] {
        var tokens: [Token] = []
        let characters = Array(d)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character.isWhitespace || character == "," {
                index += 1
                continue
            }
            if "MmLlHhVvCcSsQqTtAaZz".contains(character) {
                tokens.append(.command(character))
                index += 1
                continue
            }

            let start = index
            if character == "+" || character == "-" {
                index += 1
            }
            var seenDot = false
            var seenExponent = false
            while index < characters.count {
                let next = characters[index]
                if next.isNumber {
                    index += 1
                    continue
                }
                if next == "." && !seenDot && !seenExponent {
                    seenDot = true
                    index += 1
                    continue
                }
                if (next == "e" || next == "E") && !seenExponent {
                    seenExponent = true
                    index += 1
                    if index < characters.count, characters[index] == "+" || characters[index] == "-" {
                        index += 1
                    }
                    continue
                }
                break
            }
            let raw = String(characters[start..<index])
            guard let value = Double(raw) else { break }
            tokens.append(.number(CGFloat(value), raw: raw))
        }
        return tokens
    }

    /// https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
    private static func appendArc(
        to path: inout Path,
        from: CGPoint,
        rx: Double,
        ry: Double,
        phiDegrees: Double,
        largeArc: Bool,
        sweep: Bool,
        to: CGPoint
    ) {
        var rx = abs(rx)
        var ry = abs(ry)
        if rx == 0 || ry == 0 {
            path.addLine(to: to)
            return
        }

        let phi = (phiDegrees.truncatingRemainder(dividingBy: 360)) * .pi / 180
        let dx2 = (Double(from.x) - Double(to.x)) / 2
        let dy2 = (Double(from.y) - Double(to.y)) / 2
        let x1p = cos(phi) * dx2 + sin(phi) * dy2
        let y1p = -sin(phi) * dx2 + cos(phi) * dy2
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let scale = sqrt(lambda)
            rx *= scale
            ry *= scale
        }

        let sign: Double = largeArc == sweep ? -1 : 1
        let numerator = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let denominator = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        let coefficient = sign * sqrt(max(0, numerator / denominator))
        let cxp = coefficient * (rx * y1p) / ry
        let cyp = coefficient * (-ry * x1p) / rx
        let centerX = cos(phi) * cxp - sin(phi) * cyp + (Double(from.x) + Double(to.x)) / 2
        let centerY = sin(phi) * cxp + cos(phi) * cyp + (Double(from.y) + Double(to.y)) / 2

        let theta1 = vectorAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = vectorAngle(
            (x1p - cxp) / rx,
            (y1p - cyp) / ry,
            (-x1p - cxp) / rx,
            (-y1p - cyp) / ry
        )
        if !sweep && delta > 0 {
            delta -= 2 * .pi
        } else if sweep && delta < 0 {
            delta += 2 * .pi
        }

        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        for index in 0..<segments {
            let startAngle = theta1 + delta * Double(index) / Double(segments)
            let endAngle = theta1 + delta * Double(index + 1) / Double(segments)
            addArcCubic(
                to: &path,
                centerX: centerX,
                centerY: centerY,
                rx: rx,
                ry: ry,
                phi: phi,
                startAngle: startAngle,
                endAngle: endAngle
            )
        }
    }

    private static func addArcCubic(
        to path: inout Path,
        centerX: Double,
        centerY: Double,
        rx: Double,
        ry: Double,
        phi: Double,
        startAngle: Double,
        endAngle: Double
    ) {
        let delta = endAngle - startAngle
        let alpha = sin(delta) * (sqrt(4 + 3 * pow(tan(delta / 2), 2)) - 1) / 3

        func point(at angle: Double) -> CGPoint {
            let x = rx * cos(angle)
            let y = ry * sin(angle)
            return CGPoint(
                x: cos(phi) * x - sin(phi) * y + centerX,
                y: sin(phi) * x + cos(phi) * y + centerY
            )
        }

        func tangent(at angle: Double) -> (Double, Double) {
            let dx = -rx * sin(angle)
            let dy = ry * cos(angle)
            return (
                cos(phi) * dx - sin(phi) * dy,
                sin(phi) * dx + cos(phi) * dy
            )
        }

        let end = point(at: endAngle)
        let d1 = tangent(at: startAngle)
        let d2 = tangent(at: endAngle)
        let start = point(at: startAngle)
        let control1 = CGPoint(x: start.x + alpha * d1.0, y: start.y + alpha * d1.1)
        let control2 = CGPoint(x: end.x - alpha * d2.0, y: end.y - alpha * d2.1)
        path.addCurve(to: end, control1: control1, control2: control2)
    }

    private static func vectorAngle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
        let norm = hypot(ux, uy) * hypot(vx, vy)
        if norm == 0 { return 0 }
        let cosine = max(-1, min(1, (ux * vx + uy * vy) / norm))
        let angle = acos(cosine)
        return ux * vy - uy * vx < 0 ? -angle : angle
    }
}
