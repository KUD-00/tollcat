// GENERATED — 由 scripts/generate-shared.py 从 shared/cat.json 生成。
// 不要手改：改 shared/cat.json 后重跑生成器。


namespace TollCat;

using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using Microsoft.UI.Xaml.Media;

/// <summary>
/// docs/assets/tollcat.svg 的图层库，和 iOS MeterDesign.CatArtwork 同一份 path。
/// 每条路径在进程里只 tokenize 一次。
/// </summary>
internal static class CatArtwork
{
    public const float ViewBox = 1024f;
    public static readonly Vector2 BodyCenter = new(512f, 532f);
    public static readonly Vector2 TailPivot = new(790f, 700f);

    /// <summary>剪影上左耳内侧根。动耳朵只绕这一点拧，身体其余点不动。</summary>
    public static readonly Vector2 LeftEarPivot = new(422f, 306f);

    /// <summary>剪影上右耳内侧根。</summary>
    public static readonly Vector2 RightEarPivot = new(602f, 306f);

    /// <summary>三个 Z，贴着头顶右上斜着排，越飘越大。单个 Z 在 1024 的 viewBox 里占 62 单位，缩到仪表尺寸只剩一个灰点，所以只画一个是不够的。</summary>
    public readonly record struct ZzzMark(Vector2 Center, float Size);

    public static readonly ZzzMark[] ZzzMarks =
    [
        new(new Vector2(712f, 206f), 58f),
        new(new Vector2(802f, 128f), 82f),
        new(new Vector2(900f, 62f), 112f),
    ];
    public const float ZzzWidth = 62f;
    public const float ZzzHeight = 64f;

    /// <summary>耳朵和身体同一条闭合路径，没有接缝。</summary>
    private const string SILHOUETTE =
        "M326 236 C 356 296 380 304 422 306 C 472 292 552 292 602 306 C 644 304 668 296 698 236 C 738 302 806 362 826 482 C 846 630 800 766 660 806 C 580 828 444 828 364 806 C 224 766 178 630 198 482 C 218 362 288 302 326 236 Z";

    private const string TAIL =
        "M786 690 C 862 708 916 668 908 612 C 902 570 862 552 844 582 C 832 604 862 614 868 638 C 874 668 832 678 790 666 Z";

    private static readonly string[] EYE_NORMAL =
    [
        "M436 500 C 460 500 474 524 474 556 C 474 588 460 610 436 610 C 412 610 398 588 398 556 C 398 524 412 500 436 500 Z",
        "M588 500 C 612 500 626 524 626 556 C 626 588 612 610 588 610 C 564 610 550 588 550 556 C 550 524 564 500 588 500 Z",
    ];

    private static readonly string[] EYE_CLOSED =
    [
        "M396 544 C 396 530 406 522 436 522 C 466 522 476 530 476 544 C 476 558 466 566 436 566 C 406 566 396 558 396 544 Z",
        "M548 544 C 548 530 558 522 588 522 C 618 522 628 530 628 544 C 628 558 618 566 588 566 C 558 566 548 558 548 544 Z",
    ];

    private static readonly string[] EYE_SPARKLE =
    [
        "M436 490 C 446 532 456 544 498 556 C 456 568 446 580 436 622 C 426 580 416 568 374 556 C 416 544 426 532 436 490 Z",
        "M588 490 C 598 532 608 544 650 556 C 608 568 598 580 588 622 C 578 580 568 568 526 556 C 568 544 578 532 588 490 Z",
    ];

    private static readonly string[] EYE_ALERT =
    [
        "M436 512 C 456 512 470 532 470 558 C 470 584 456 602 436 602 C 416 602 402 584 402 558 C 402 532 416 512 436 512 Z",
        "M588 512 C 608 512 622 532 622 558 C 622 584 608 602 588 602 C 568 602 554 584 554 558 C 554 532 568 512 588 512 Z",
        "M374 456 C 400 440 432 440 456 452 C 432 456 402 466 378 480 Z",
        "M650 456 C 624 440 592 440 568 452 C 592 456 622 466 646 480 Z",
    ];

    private static readonly string[] EYE_X =
    [
        "M408 512 L 436 540 L 464 512 L 480 528 L 452 556 L 480 584 L 464 600 L 436 572 L 408 600 L 392 584 L 420 556 L 392 528 Z",
        "M560 512 L 588 540 L 616 512 L 632 528 L 604 556 L 632 584 L 616 600 L 588 572 L 560 600 L 544 584 L 572 556 L 544 528 Z",
    ];

    private const string MOUTH_NEUTRAL =
        "M484 652 C 490 670 506 676 512 664 C 518 676 534 670 540 652 C 532 664 518 668 512 658 C 506 668 492 664 484 652 Z";

    private const string MOUTH_SMILE =
        "M474 646 C 486 684 538 684 550 646 C 540 668 484 668 474 646 Z";

    private const string MOUTH_FLAT =
        "M480 654 C 480 646 487 642 512 642 C 537 642 544 646 544 654 C 544 662 537 666 512 666 C 487 666 480 662 480 654 Z";

    private const string MOUTH_O =
        "M512 630 C 530 630 542 648 542 668 C 542 688 530 704 512 704 C 494 704 482 688 482 668 C 482 648 494 630 512 630 Z";

    /// <summary>省到了：星眼下面那只小圆嘴。比吓到的大 O 大约小一半。</summary>
    private const string MOUTH_SMALL_O =
        "M512 652 C 521 652 528 659 528 668 C 528 677 521 684 512 684 C 503 684 496 677 496 668 C 496 659 503 652 512 652 Z";

    private const string MOUTH_WAVE =
        "M472 650 C 482 632 500 664 512 650 C 524 636 542 668 552 650 C 542 674 524 646 512 660 C 500 674 482 668 472 650 Z";

    /// <summary>镜片挖空。fill-rule 是填充时的 evenodd，不是 path `d` 里的命令。</summary>
    private static readonly string[] GLASSES_LENSES =
    [
        "M366 556 A 70 62 0 1 0 506 556 A 70 62 0 1 0 366 556 Z M382 556 A 54 46 0 1 1 490 556 A 54 46 0 1 1 382 556 Z",
        "M518 556 A 70 62 0 1 0 658 556 A 70 62 0 1 0 518 556 Z M534 556 A 54 46 0 1 1 642 556 A 54 46 0 1 1 534 556 Z",
    ];

    private static readonly string[] GLASSES_BRIDGE_AND_ARMS =
    [
        "M500 546 L 524 546 L 524 562 L 500 562 Z",
        "M366 546 L 300 528 L 296 544 L 362 562 Z",
        "M658 546 L 724 528 L 728 544 L 662 562 Z",
    ];

    private const string ZZZ =
        "M0 0 L 62 0 L 62 16 L 28 48 L 62 48 L 62 64 L 0 64 L 0 48 L 34 16 L 0 16 Z";

    private static readonly string[] BANG =
    [
        "M772 150 C 790 150 804 164 802 182 L 792 268 C 791 278 784 284 774 284 C 764 284 757 278 756 268 L 746 182 C 744 164 754 150 772 150 Z",
        "M774 306 C 790 306 802 318 802 334 C 802 350 790 362 774 362 C 758 362 746 350 746 334 C 746 318 758 306 774 306 Z",
    ];

    private const string SKULL_HEAD =
        "M790 150 C 842 150 876 188 876 234 C 876 262 862 282 844 292 L 844 320 L 736 320 L 736 292 C 718 282 704 262 704 234 C 704 188 738 150 790 150 Z";

    private static readonly string[] SKULL_EYES =
    [
        "M756 224 C 770 224 780 236 780 250 C 780 264 770 274 756 274 C 742 274 732 264 732 250 C 732 236 742 224 756 224 Z",
        "M824 224 C 838 224 848 236 848 250 C 848 264 838 274 824 274 C 810 274 800 264 800 250 C 800 236 810 224 824 224 Z",
        "M790 282 L 802 306 L 778 306 Z",
    ];

    private static readonly string[] BUBBLE_DOTS =
    [
        "M690 356 C 704 356 714 366 714 380 C 714 394 704 404 690 404 C 676 404 666 394 666 380 C 666 366 676 356 690 356 Z",
        "M646 424 C 656 424 664 432 664 442 C 664 452 656 460 646 460 C 636 460 628 452 628 442 C 628 432 636 424 646 424 Z",
    ];

    private static readonly Dictionary<string, object> Cache = new();

    private static PathGeometry Parse(string d) => SvgPathParser.Parse(d);

    private static PathGeometry Once(string key, string d)
    {
        lock (Cache)
        {
            if (Cache.TryGetValue(key, out var existing)) return (PathGeometry)existing;
            var parsed = Parse(d);
            Cache[key] = parsed;
            return parsed;
        }
    }

    private static IReadOnlyList<PathGeometry> OnceMany(string key, string[] data)
    {
        lock (Cache)
        {
            if (Cache.TryGetValue(key, out var existing)) return (IReadOnlyList<PathGeometry>)existing;
            var parsed = Array.ConvertAll(data, Parse);
            Cache[key] = parsed;
            return parsed;
        }
    }

    public static PathGeometry SilhouettePath => Once(nameof(SILHOUETTE), SILHOUETTE);
    public static PathGeometry TailPath => Once(nameof(TAIL), TAIL);
    public static PathGeometry ZzzPath => Once(nameof(ZZZ), ZZZ);
    public static IReadOnlyList<PathGeometry> BangPaths => OnceMany(nameof(BANG), BANG);
    public static PathGeometry SkullHeadPath => Once(nameof(SKULL_HEAD), SKULL_HEAD);
    public static IReadOnlyList<PathGeometry> SkullEyePaths => OnceMany(nameof(SKULL_EYES), SKULL_EYES);
    public static IReadOnlyList<PathGeometry> BubbleDotPaths => OnceMany(nameof(BUBBLE_DOTS), BUBBLE_DOTS);

    private static IReadOnlyList<PathGeometry> EyeNormalPaths => OnceMany(nameof(EYE_NORMAL), EYE_NORMAL);
    private static IReadOnlyList<PathGeometry> EyeClosedPaths => OnceMany(nameof(EYE_CLOSED), EYE_CLOSED);
    private static IReadOnlyList<PathGeometry> EyeSparklePaths => OnceMany(nameof(EYE_SPARKLE), EYE_SPARKLE);
    private static IReadOnlyList<PathGeometry> EyeAlertPaths => OnceMany(nameof(EYE_ALERT), EYE_ALERT);
    private static IReadOnlyList<PathGeometry> EyeXPaths => OnceMany(nameof(EYE_X), EYE_X);

    private static PathGeometry MouthNeutralPath => Once(nameof(MOUTH_NEUTRAL), MOUTH_NEUTRAL);
    private static PathGeometry MouthSmilePath => Once(nameof(MOUTH_SMILE), MOUTH_SMILE);
    private static PathGeometry MouthFlatPath => Once(nameof(MOUTH_FLAT), MOUTH_FLAT);
    private static PathGeometry MouthOPath => Once(nameof(MOUTH_O), MOUTH_O);
    private static PathGeometry MouthSmallOPath => Once(nameof(MOUTH_SMALL_O), MOUTH_SMALL_O);
    private static PathGeometry MouthWavePath => Once(nameof(MOUTH_WAVE), MOUTH_WAVE);

    public static IReadOnlyList<PathGeometry> GlassesLensPaths => OnceMany(nameof(GLASSES_LENSES), GLASSES_LENSES);
    public static IReadOnlyList<PathGeometry> GlassesFramePaths => OnceMany(nameof(GLASSES_BRIDGE_AND_ARMS), GLASSES_BRIDGE_AND_ARMS);

    public static IReadOnlyList<PathGeometry> EyeballShapes(CatEyes eyes) => eyes switch
    {
        CatEyes.Normal => EyeNormalPaths,
        CatEyes.Closed => EyeClosedPaths,
        CatEyes.Sparkle => EyeSparklePaths,
        CatEyes.Alert => EyeAlertPaths.Take(2).ToArray(),
        CatEyes.X => EyeXPaths,
        _ => [],
    };

    public static IReadOnlyList<PathGeometry> EyeMarkShapes(CatEyes eyes) => eyes switch
    {
        CatEyes.Alert => EyeAlertPaths.Skip(2).ToArray(),
        _ => [],
    };

    public static PathGeometry? MouthShape(CatMouth mouth) => mouth switch
    {
        CatMouth.None => null,
        CatMouth.Neutral => MouthNeutralPath,
        CatMouth.Smile => MouthSmilePath,
        CatMouth.Flat => MouthFlatPath,
        CatMouth.SmallO => MouthSmallOPath,
        CatMouth.O => MouthOPath,
        CatMouth.Wave => MouthWavePath,
        _ => null,
    };

    /// <summary>
    /// 仍是同一条闭合剪影。0 度就是原稿；非 0 只把耳尖和近根控制点绕耳根转。
    /// </summary>
    public static PathGeometry SilhouettePathAt(float leftEarDegrees, float rightEarDegrees)
    {
        if (leftEarDegrees == 0f && rightEarDegrees == 0f) return SilhouettePath;
        Vector2 Left(Vector2 p) => Rotated(p, LeftEarPivot, leftEarDegrees);
        Vector2 Right(Vector2 p) => Rotated(p, RightEarPivot, rightEarDegrees);
        var figure = new PathFigure { IsClosed = true, IsFilled = true };
        var start = Left(new Vector2(326f, 236f));
        figure.StartPoint = new Windows.Foundation.Point(start.X, start.Y);
        Cubic(figure, Left(new Vector2(356f, 296f)), Left(new Vector2(380f, 304f)), Left(new Vector2(422f, 306f)));
        Cubic(figure, new Vector2(472f, 292f), new Vector2(552f, 292f), Right(new Vector2(602f, 306f)));
        Cubic(figure, Right(new Vector2(644f, 304f)), Right(new Vector2(668f, 296f)), Right(new Vector2(698f, 236f)));
        Cubic(figure, Right(new Vector2(738f, 302f)), new Vector2(806f, 362f), new Vector2(826f, 482f));
        Cubic(figure, new Vector2(846f, 630f), new Vector2(800f, 766f), new Vector2(660f, 806f));
        Cubic(figure, new Vector2(580f, 828f), new Vector2(444f, 828f), new Vector2(364f, 806f));
        Cubic(figure, new Vector2(224f, 766f), new Vector2(178f, 630f), new Vector2(198f, 482f));
        Cubic(figure, new Vector2(218f, 362f), Left(new Vector2(288f, 302f)), Left(new Vector2(326f, 236f)));
        var geometry = new PathGeometry();
        geometry.Figures.Add(figure);
        return geometry;
    }

    private static void Cubic(PathFigure figure, Vector2 c1, Vector2 c2, Vector2 to)
    {
        figure.Segments.Add(new BezierSegment
        {
            Point1 = new Windows.Foundation.Point(c1.X, c1.Y),
            Point2 = new Windows.Foundation.Point(c2.X, c2.Y),
            Point3 = new Windows.Foundation.Point(to.X, to.Y),
        });
    }

    /// <summary>和 iOS 同一套旋转，保证剪影逐点一致。</summary>
    private static Vector2 Rotated(Vector2 point, Vector2 pivot, float degrees)
    {
        var radians = degrees * MathF.PI / 180f;
        var cosine = MathF.Cos(radians);
        var sine = MathF.Sin(radians);
        var dx = point.X - pivot.X;
        var dy = point.Y - pivot.Y;
        return new Vector2(
            pivot.X + dx * cosine + dy * sine,
            pivot.Y - dx * sine + dy * cosine);
    }
}

