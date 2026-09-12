// GENERATED — 由 scripts/generate-shared.py 从 shared/cat.json 生成。
// 不要手改：改 shared/cat.json 后重跑生成器。


package com.zhechengqi.tollcat.ui.cat

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.vector.PathParser
import kotlin.math.cos
import kotlin.math.sin

/**
 * `docs/assets/tollcat.svg` 的图层库，和 iOS `MeterDesign.CatArtwork` 同一份 path。
 * 每条路径在进程里只 tokenize 一次（`lazy`），绘制阶段不再扫字符串。
 */
internal object CatArtwork {
    const val VIEW_BOX = 1024f
    val bodyCenter = Offset(512f, 532f)
    val tailPivot = Offset(790f, 700f)

    /** 剪影上左耳内侧根。动耳朵只绕这一点拧，身体其余点不动。 */
    val leftEarPivot = Offset(422f, 306f)

    /** 剪影上右耳内侧根。 */
    val rightEarPivot = Offset(602f, 306f)

    /** 三个 Z，贴着头顶右上斜着排，越飘越大。单个 Z 在 1024 的 viewBox 里占 62 单位，缩到仪表尺寸只剩一个灰点，所以只画一个是不够的。 */
    data class ZzzMark(val center: Offset, val size: Float)

    val zzzMarks = listOf(
        ZzzMark(Offset(712f, 206f), 58f),
        ZzzMark(Offset(802f, 128f), 82f),
        ZzzMark(Offset(900f, 62f), 112f),
    )
    const val ZZZ_WIDTH = 62f
    const val ZZZ_HEIGHT = 64f

    /** 耳朵和身体同一条闭合路径，没有接缝。 */
    private const val SILHOUETTE =
        "M326 236 C 356 296 380 304 422 306 C 472 292 552 292 602 306 C 644 304 668 296 698 236 C 738 302 806 362 826 482 C 846 630 800 766 660 806 C 580 828 444 828 364 806 C 224 766 178 630 198 482 C 218 362 288 302 326 236 Z"

    private const val TAIL =
        "M786 690 C 862 708 916 668 908 612 C 902 570 862 552 844 582 C 832 604 862 614 868 638 C 874 668 832 678 790 666 Z"

    private val EYE_NORMAL = listOf(
        "M436 500 C 460 500 474 524 474 556 C 474 588 460 610 436 610 C 412 610 398 588 398 556 C 398 524 412 500 436 500 Z",
        "M588 500 C 612 500 626 524 626 556 C 626 588 612 610 588 610 C 564 610 550 588 550 556 C 550 524 564 500 588 500 Z",
    )

    private val EYE_CLOSED = listOf(
        "M396 544 C 396 530 406 522 436 522 C 466 522 476 530 476 544 C 476 558 466 566 436 566 C 406 566 396 558 396 544 Z",
        "M548 544 C 548 530 558 522 588 522 C 618 522 628 530 628 544 C 628 558 618 566 588 566 C 558 566 548 558 548 544 Z",
    )

    private val EYE_SPARKLE = listOf(
        "M436 490 C 446 532 456 544 498 556 C 456 568 446 580 436 622 C 426 580 416 568 374 556 C 416 544 426 532 436 490 Z",
        "M588 490 C 598 532 608 544 650 556 C 608 568 598 580 588 622 C 578 580 568 568 526 556 C 568 544 578 532 588 490 Z",
    )

    private val EYE_ALERT = listOf(
        "M436 512 C 456 512 470 532 470 558 C 470 584 456 602 436 602 C 416 602 402 584 402 558 C 402 532 416 512 436 512 Z",
        "M588 512 C 608 512 622 532 622 558 C 622 584 608 602 588 602 C 568 602 554 584 554 558 C 554 532 568 512 588 512 Z",
        "M374 456 C 400 440 432 440 456 452 C 432 456 402 466 378 480 Z",
        "M650 456 C 624 440 592 440 568 452 C 592 456 622 466 646 480 Z",
    )

    private val EYE_X = listOf(
        "M408 512 L 436 540 L 464 512 L 480 528 L 452 556 L 480 584 L 464 600 L 436 572 L 408 600 L 392 584 L 420 556 L 392 528 Z",
        "M560 512 L 588 540 L 616 512 L 632 528 L 604 556 L 632 584 L 616 600 L 588 572 L 560 600 L 544 584 L 572 556 L 544 528 Z",
    )

    private const val MOUTH_NEUTRAL =
        "M484 652 C 490 670 506 676 512 664 C 518 676 534 670 540 652 C 532 664 518 668 512 658 C 506 668 492 664 484 652 Z"

    private const val MOUTH_SMILE =
        "M474 646 C 486 684 538 684 550 646 C 540 668 484 668 474 646 Z"

    private const val MOUTH_FLAT =
        "M480 654 C 480 646 487 642 512 642 C 537 642 544 646 544 654 C 544 662 537 666 512 666 C 487 666 480 662 480 654 Z"

    private const val MOUTH_O =
        "M512 630 C 530 630 542 648 542 668 C 542 688 530 704 512 704 C 494 704 482 688 482 668 C 482 648 494 630 512 630 Z"

    /** 省到了：星眼下面那只小圆嘴。比吓到的大 O 大约小一半。 */
    private const val MOUTH_SMALL_O =
        "M512 652 C 521 652 528 659 528 668 C 528 677 521 684 512 684 C 503 684 496 677 496 668 C 496 659 503 652 512 652 Z"

    private const val MOUTH_WAVE =
        "M472 650 C 482 632 500 664 512 650 C 524 636 542 668 552 650 C 542 674 524 646 512 660 C 500 674 482 668 472 650 Z"

    /** 镜片挖空。fill-rule 是填充时的 evenodd，不是 path `d` 里的命令。 */
    private val GLASSES_LENSES = listOf(
        "M366 556 A 70 62 0 1 0 506 556 A 70 62 0 1 0 366 556 Z M382 556 A 54 46 0 1 1 490 556 A 54 46 0 1 1 382 556 Z",
        "M518 556 A 70 62 0 1 0 658 556 A 70 62 0 1 0 518 556 Z M534 556 A 54 46 0 1 1 642 556 A 54 46 0 1 1 534 556 Z",
    )

    private val GLASSES_BRIDGE_AND_ARMS = listOf(
        "M500 546 L 524 546 L 524 562 L 500 562 Z",
        "M366 546 L 300 528 L 296 544 L 362 562 Z",
        "M658 546 L 724 528 L 728 544 L 662 562 Z",
    )

    private const val ZZZ =
        "M0 0 L 62 0 L 62 16 L 28 48 L 62 48 L 62 64 L 0 64 L 0 48 L 34 16 L 0 16 Z"

    private val BANG = listOf(
        "M772 150 C 790 150 804 164 802 182 L 792 268 C 791 278 784 284 774 284 C 764 284 757 278 756 268 L 746 182 C 744 164 754 150 772 150 Z",
        "M774 306 C 790 306 802 318 802 334 C 802 350 790 362 774 362 C 758 362 746 350 746 334 C 746 318 758 306 774 306 Z",
    )

    private const val SKULL_HEAD =
        "M790 150 C 842 150 876 188 876 234 C 876 262 862 282 844 292 L 844 320 L 736 320 L 736 292 C 718 282 704 262 704 234 C 704 188 738 150 790 150 Z"

    private val SKULL_EYES = listOf(
        "M756 224 C 770 224 780 236 780 250 C 780 264 770 274 756 274 C 742 274 732 264 732 250 C 732 236 742 224 756 224 Z",
        "M824 224 C 838 224 848 236 848 250 C 848 264 838 274 824 274 C 810 274 800 264 800 250 C 800 236 810 224 824 224 Z",
        "M790 282 L 802 306 L 778 306 Z",
    )

    private val BUBBLE_DOTS = listOf(
        "M690 356 C 704 356 714 366 714 380 C 714 394 704 404 690 404 C 676 404 666 394 666 380 C 666 366 676 356 690 356 Z",
        "M646 424 C 656 424 664 432 664 442 C 664 452 656 460 646 460 C 636 460 628 452 628 442 C 628 432 636 424 646 424 Z",
    )

    private fun parse(d: String): Path = PathParser().parsePathString(d).toPath()

    val silhouettePath: Path by lazy { parse(SILHOUETTE) }
    val tailPath: Path by lazy { parse(TAIL) }
    val zzzPath: Path by lazy { parse(ZZZ) }
    val bangPaths: List<Path> by lazy { BANG.map(::parse) }
    val skullHeadPath: Path by lazy { parse(SKULL_HEAD) }
    val skullEyePaths: List<Path> by lazy { SKULL_EYES.map(::parse) }
    val bubbleDotPaths: List<Path> by lazy { BUBBLE_DOTS.map(::parse) }

    private val eyeNormalPaths by lazy { EYE_NORMAL.map(::parse) }
    private val eyeClosedPaths by lazy { EYE_CLOSED.map(::parse) }
    private val eyeSparklePaths by lazy { EYE_SPARKLE.map(::parse) }
    private val eyeAlertPaths by lazy { EYE_ALERT.map(::parse) }
    private val eyeXPaths by lazy { EYE_X.map(::parse) }

    private val mouthNeutralPath by lazy { parse(MOUTH_NEUTRAL) }
    private val mouthSmilePath by lazy { parse(MOUTH_SMILE) }
    private val mouthFlatPath by lazy { parse(MOUTH_FLAT) }
    private val mouthOPath by lazy { parse(MOUTH_O) }
    private val mouthSmallOPath by lazy { parse(MOUTH_SMALL_O) }
    private val mouthWavePath by lazy { parse(MOUTH_WAVE) }

    val glassesLensPaths: List<Path> by lazy {
        GLASSES_LENSES.map { parse(it).apply { fillType = PathFillType.EvenOdd } }
    }
    val glassesFramePaths: List<Path> by lazy { GLASSES_BRIDGE_AND_ARMS.map(::parse) }

    /** 两只眼珠。眨眼只压这几条；吊眼的眉留在 [eyeMarkShapes]。 */
    fun eyeballShapes(eyes: CatEyes): List<Path> = when (eyes) {
        CatEyes.Normal -> eyeNormalPaths
        CatEyes.Closed -> eyeClosedPaths
        CatEyes.Sparkle -> eyeSparklePaths
        CatEyes.Alert -> eyeAlertPaths.take(2)
        CatEyes.X -> eyeXPaths
    }

    fun eyeMarkShapes(eyes: CatEyes): List<Path> = when (eyes) {
        CatEyes.Alert -> eyeAlertPaths.drop(2)
        else -> emptyList()
    }

    fun mouthShape(mouth: CatMouth): Path? = when (mouth) {
        CatMouth.None -> null
        CatMouth.Neutral -> mouthNeutralPath
        CatMouth.Smile -> mouthSmilePath
        CatMouth.Flat -> mouthFlatPath
        CatMouth.SmallO -> mouthSmallOPath
        CatMouth.O -> mouthOPath
        CatMouth.Wave -> mouthWavePath
    }

    /**
     * 仍是同一条闭合剪影。0 度就是原稿；非 0 只把耳尖和近根控制点绕耳根转。
     * 控制点和 [SILHOUETTE] 的 `d` 是同一份数据，生成器会校验两者重组一致。
     */
    fun silhouettePath(leftEarDegrees: Float, rightEarDegrees: Float): Path {
        if (leftEarDegrees == 0f && rightEarDegrees == 0f) return silhouettePath
        fun left(p: Offset) = rotated(p, leftEarPivot, leftEarDegrees)
        fun right(p: Offset) = rotated(p, rightEarPivot, rightEarDegrees)
        val path = Path()
        val start = left(Offset(326f, 236f))
        path.moveTo(start.x, start.y)
        cubic(path, left(Offset(356f, 296f)), left(Offset(380f, 304f)), left(Offset(422f, 306f)))
        cubic(path, Offset(472f, 292f), Offset(552f, 292f), right(Offset(602f, 306f)))
        cubic(path, right(Offset(644f, 304f)), right(Offset(668f, 296f)), right(Offset(698f, 236f)))
        cubic(path, right(Offset(738f, 302f)), Offset(806f, 362f), Offset(826f, 482f))
        cubic(path, Offset(846f, 630f), Offset(800f, 766f), Offset(660f, 806f))
        cubic(path, Offset(580f, 828f), Offset(444f, 828f), Offset(364f, 806f))
        cubic(path, Offset(224f, 766f), Offset(178f, 630f), Offset(198f, 482f))
        cubic(path, Offset(218f, 362f), left(Offset(288f, 302f)), left(Offset(326f, 236f)))
        path.close()
        return path
    }

    private fun cubic(path: Path, c1: Offset, c2: Offset, to: Offset) {
        path.cubicTo(c1.x, c1.y, c2.x, c2.y, to.x, to.y)
    }

    /** 和 iOS 同一套旋转，保证两端剪影逐点一致。 */
    private fun rotated(point: Offset, pivot: Offset, degrees: Float): Offset {
        val radians = degrees * Math.PI.toFloat() / 180f
        val cosine = cos(radians)
        val sine = sin(radians)
        val dx = point.x - pivot.x
        val dy = point.y - pivot.y
        return Offset(
            x = pivot.x + dx * cosine + dy * sine,
            y = pivot.y - dx * sine + dy * cosine,
        )
    }
}
