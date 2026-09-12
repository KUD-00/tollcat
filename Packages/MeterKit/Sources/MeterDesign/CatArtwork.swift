// GENERATED — 由 scripts/generate-shared.py 从 shared/cat.json 生成。
// 不要手改：改 shared/cat.json 后重跑生成器。


import SwiftUI

/// `docs/assets/tollcat.svg` 的图层库，内联成常量。不要在运行时读 SVG。
enum CatArtwork {
    static let viewBox: CGFloat = 1024
    static let bodyCenter = CGPoint(x: 512, y: 532)
    static let tailPivot = CGPoint(x: 790, y: 700)
    /// 剪影上左耳内侧根。动耳朵只绕这一点拧，身体其余点不动。
    static let leftEarPivot = CGPoint(x: 422, y: 306)
    /// 剪影上右耳内侧根。
    static let rightEarPivot = CGPoint(x: 602, y: 306)
    /// 三个 Z，贴着头顶右上斜着排，越飘越大。
    /// 单个 Z 在 1024 的 viewBox 里占 62 单位，缩到仪表尺寸只剩一个灰点，所以只画一个是不够的。
    static let zzzMarks: [(center: CGPoint, size: CGFloat)] = [
        (CGPoint(x: 712, y: 206), 58),
        (CGPoint(x: 802, y: 128), 82),
        (CGPoint(x: 900, y: 62), 112),
    ]

    /// 耳朵和身体同一条闭合路径，没有接缝。
    static let silhouette =
        "M326 236 C 356 296 380 304 422 306 C 472 292 552 292 602 306 C 644 304 668 296 698 236 C 738 302 806 362 826 482 C 846 630 800 766 660 806 C 580 828 444 828 364 806 C 224 766 178 630 198 482 C 218 362 288 302 326 236 Z"

    static let tail =
        "M786 690 C 862 708 916 668 908 612 C 902 570 862 552 844 582 C 832 604 862 614 868 638 C 874 668 832 678 790 666 Z"

    static let eyeNormal = [
        "M436 500 C 460 500 474 524 474 556 C 474 588 460 610 436 610 C 412 610 398 588 398 556 C 398 524 412 500 436 500 Z",
        "M588 500 C 612 500 626 524 626 556 C 626 588 612 610 588 610 C 564 610 550 588 550 556 C 550 524 564 500 588 500 Z",
    ]

    static let eyeClosed = [
        "M396 544 C 396 530 406 522 436 522 C 466 522 476 530 476 544 C 476 558 466 566 436 566 C 406 566 396 558 396 544 Z",
        "M548 544 C 548 530 558 522 588 522 C 618 522 628 530 628 544 C 628 558 618 566 588 566 C 558 566 548 558 548 544 Z",
    ]

    static let eyeSparkle = [
        "M436 490 C 446 532 456 544 498 556 C 456 568 446 580 436 622 C 426 580 416 568 374 556 C 416 544 426 532 436 490 Z",
        "M588 490 C 598 532 608 544 650 556 C 608 568 598 580 588 622 C 578 580 568 568 526 556 C 568 544 578 532 588 490 Z",
    ]

    static let eyeAlert = [
        "M436 512 C 456 512 470 532 470 558 C 470 584 456 602 436 602 C 416 602 402 584 402 558 C 402 532 416 512 436 512 Z",
        "M588 512 C 608 512 622 532 622 558 C 622 584 608 602 588 602 C 568 602 554 584 554 558 C 554 532 568 512 588 512 Z",
        "M374 456 C 400 440 432 440 456 452 C 432 456 402 466 378 480 Z",
        "M650 456 C 624 440 592 440 568 452 C 592 456 622 466 646 480 Z",
    ]

    static let eyeX = [
        "M408 512 L 436 540 L 464 512 L 480 528 L 452 556 L 480 584 L 464 600 L 436 572 L 408 600 L 392 584 L 420 556 L 392 528 Z",
        "M560 512 L 588 540 L 616 512 L 632 528 L 604 556 L 632 584 L 616 600 L 588 572 L 560 600 L 544 584 L 572 556 L 544 528 Z",
    ]

    static let mouthNeutral =
        "M484 652 C 490 670 506 676 512 664 C 518 676 534 670 540 652 C 532 664 518 668 512 658 C 506 668 492 664 484 652 Z"

    static let mouthSmile =
        "M474 646 C 486 684 538 684 550 646 C 540 668 484 668 474 646 Z"

    static let mouthFlat =
        "M480 654 C 480 646 487 642 512 642 C 537 642 544 646 544 654 C 544 662 537 666 512 666 C 487 666 480 662 480 654 Z"

    static let mouthO =
        "M512 630 C 530 630 542 648 542 668 C 542 688 530 704 512 704 C 494 704 482 688 482 668 C 482 648 494 630 512 630 Z"

    /// 省到了：星眼下面那只小圆嘴。比吓到的大 O 大约小一半。
    static let mouthSmallO =
        "M512 652 C 521 652 528 659 528 668 C 528 677 521 684 512 684 C 503 684 496 677 496 668 C 496 659 503 652 512 652 Z"

    static let mouthWave =
        "M472 650 C 482 632 500 664 512 650 C 524 636 542 668 552 650 C 542 674 524 646 512 660 C 500 674 482 668 472 650 Z"

    /// 镜片挖空。fill-rule 是填充时的 evenodd，不是 path `d` 里的命令。
    static let glassesLenses = [
        "M366 556 A 70 62 0 1 0 506 556 A 70 62 0 1 0 366 556 Z M382 556 A 54 46 0 1 1 490 556 A 54 46 0 1 1 382 556 Z",
        "M518 556 A 70 62 0 1 0 658 556 A 70 62 0 1 0 518 556 Z M534 556 A 54 46 0 1 1 642 556 A 54 46 0 1 1 534 556 Z",
    ]

    static let glassesBridgeAndArms = [
        "M500 546 L 524 546 L 524 562 L 500 562 Z",
        "M366 546 L 300 528 L 296 544 L 362 562 Z",
        "M658 546 L 724 528 L 728 544 L 662 562 Z",
    ]

    static let zzz =
        "M0 0 L 62 0 L 62 16 L 28 48 L 62 48 L 62 64 L 0 64 L 0 48 L 34 16 L 0 16 Z"

    static let zzzWidth: CGFloat = 62
    static let zzzHeight: CGFloat = 64

    static let bang = [
        "M772 150 C 790 150 804 164 802 182 L 792 268 C 791 278 784 284 774 284 C 764 284 757 278 756 268 L 746 182 C 744 164 754 150 772 150 Z",
        "M774 306 C 790 306 802 318 802 334 C 802 350 790 362 774 362 C 758 362 746 350 746 334 C 746 318 758 306 774 306 Z",
    ]

    static let skullHead =
        "M790 150 C 842 150 876 188 876 234 C 876 262 862 282 844 292 L 844 320 L 736 320 L 736 292 C 718 282 704 262 704 234 C 704 188 738 150 790 150 Z"

    static let skullEyes = [
        "M756 224 C 770 224 780 236 780 250 C 780 264 770 274 756 274 C 742 274 732 264 732 250 C 732 236 742 224 756 224 Z",
        "M824 224 C 838 224 848 236 848 250 C 848 264 838 274 824 274 C 810 274 800 264 800 250 C 800 236 810 224 824 224 Z",
        "M790 282 L 802 306 L 778 306 Z",
    ]

    static let bubbleDots = [
        "M690 356 C 704 356 714 366 714 380 C 714 394 704 404 690 404 C 676 404 666 394 666 380 C 666 366 676 356 690 356 Z",
        "M646 424 C 656 424 664 432 664 442 C 664 452 656 460 646 460 C 636 460 628 452 628 442 C 628 432 636 424 646 424 Z",
    ]

    // MARK: - 解析好的 Path

    /// 每条路径在进程里只 tokenize 一次。
    ///
    /// 之前每个图层都是一个 `Shape`，`path(in:)` 每次布局都要把五百来字符的 `d`
    /// 重新扫一遍。一只猫十几个图层、一秒几十帧，等于每秒解析上千次同样的字符串。
    /// `static let` 是惰性 + 线程安全的，正好当一次性缓存用。
    static let silhouettePath = SVGPathParser.path(from: silhouette)
    static let tailPath = SVGPathParser.path(from: tail)
    static let zzzPath = SVGPathParser.path(from: zzz)
    static let bangPaths = bang.map(SVGPathParser.path(from:))
    static let skullHeadPath = SVGPathParser.path(from: skullHead)
    static let skullEyePaths = skullEyes.map(SVGPathParser.path(from:))
    static let bubbleDotPaths = bubbleDots.map(SVGPathParser.path(from:))

    private static let eyeNormalPaths = eyeNormal.map(SVGPathParser.path(from:))
    private static let eyeClosedPaths = eyeClosed.map(SVGPathParser.path(from:))
    private static let eyeSparklePaths = eyeSparkle.map(SVGPathParser.path(from:))
    private static let eyeAlertPaths = eyeAlert.map(SVGPathParser.path(from:))
    private static let eyeXPaths = eyeX.map(SVGPathParser.path(from:))

    private static let mouthNeutralPath = SVGPathParser.path(from: mouthNeutral)
    private static let mouthSmilePath = SVGPathParser.path(from: mouthSmile)
    private static let mouthFlatPath = SVGPathParser.path(from: mouthFlat)
    private static let mouthOPath = SVGPathParser.path(from: mouthO)
    private static let mouthSmallOPath = SVGPathParser.path(from: mouthSmallO)
    private static let mouthWavePath = SVGPathParser.path(from: mouthWave)

    static let glassesLensPaths = glassesLenses.map(SVGPathParser.path(from:))
    static let glassesFramePaths = glassesBridgeAndArms.map(SVGPathParser.path(from:))

    /// 两只眼珠。眨眼只压这几条；吊眼的眉留在 `eyeMarkShapes`。
    static func eyeballShapes(for eyes: CatEyes) -> [Path] {
        switch eyes {
        case .normal:
            return eyeNormalPaths
        case .closed:
            return eyeClosedPaths
        case .sparkle:
            return eyeSparklePaths
        case .alert:
            return Array(eyeAlertPaths.prefix(2))
        case .x:
            return eyeXPaths
        }
    }

    static func eyeMarkShapes(for eyes: CatEyes) -> [Path] {
        switch eyes {
        case .alert:
            return Array(eyeAlertPaths.suffix(2))
        case .normal, .closed, .sparkle, .x:
            return []
        }
    }

    static func mouthShape(for mouth: CatMouth) -> Path? {
        switch mouth {
        case .none:
            return nil
        case .neutral:
            return mouthNeutralPath
        case .smile:
            return mouthSmilePath
        case .flat:
            return mouthFlatPath
        case .smallO:
            return mouthSmallOPath
        case .o:
            return mouthOPath
        case .wave:
            return mouthWavePath
        }
    }

    /// 仍是同一条闭合剪影。0 度就是原稿；非 0 只把耳尖和近根控制点绕耳根转。
    /// 控制点和 `silhouette` 的 `d` 是同一份数据，生成器会校验两者重组一致。
    static func silhouettePath(leftEarDegrees: Double, rightEarDegrees: Double) -> Path {
        if leftEarDegrees == 0, rightEarDegrees == 0 {
            return silhouettePath
        }
        let left: (CGPoint) -> CGPoint = {
            rotated($0, around: leftEarPivot, degrees: leftEarDegrees)
        }
        let right: (CGPoint) -> CGPoint = {
            rotated($0, around: rightEarPivot, degrees: rightEarDegrees)
        }
        var path = Path()
        path.move(to: left(CGPoint(x: 326, y: 236)))
        path.addCurve(
            to: left(CGPoint(x: 422, y: 306)),
            control1: left(CGPoint(x: 356, y: 296)),
            control2: left(CGPoint(x: 380, y: 304))
        )
        path.addCurve(
            to: right(CGPoint(x: 602, y: 306)),
            control1: CGPoint(x: 472, y: 292),
            control2: CGPoint(x: 552, y: 292)
        )
        path.addCurve(
            to: right(CGPoint(x: 698, y: 236)),
            control1: right(CGPoint(x: 644, y: 304)),
            control2: right(CGPoint(x: 668, y: 296))
        )
        path.addCurve(
            to: CGPoint(x: 826, y: 482),
            control1: right(CGPoint(x: 738, y: 302)),
            control2: CGPoint(x: 806, y: 362)
        )
        path.addCurve(
            to: CGPoint(x: 660, y: 806),
            control1: CGPoint(x: 846, y: 630),
            control2: CGPoint(x: 800, y: 766)
        )
        path.addCurve(
            to: CGPoint(x: 364, y: 806),
            control1: CGPoint(x: 580, y: 828),
            control2: CGPoint(x: 444, y: 828)
        )
        path.addCurve(
            to: CGPoint(x: 198, y: 482),
            control1: CGPoint(x: 224, y: 766),
            control2: CGPoint(x: 178, y: 630)
        )
        path.addCurve(
            to: left(CGPoint(x: 326, y: 236)),
            control1: CGPoint(x: 218, y: 362),
            control2: left(CGPoint(x: 288, y: 302))
        )
        path.closeSubpath()
        return path
    }

    /// Canvas / SwiftUI 正角度顺时针。
    private static func rotated(_ point: CGPoint, around pivot: CGPoint, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        let cosine = Foundation.cos(radians)
        let sine = Foundation.sin(radians)
        let dx = point.x - pivot.x
        let dy = point.y - pivot.y
        return CGPoint(
            x: pivot.x + dx * cosine + dy * sine,
            y: pivot.y - dx * sine + dy * cosine
        )
    }
}
