import SwiftUI

/// 一帧的动效参数。
public struct CatMotionFrame: Equatable, Sendable {
    /// 0 静止；1 压扁满振幅；负值是回弹。常态循环不再压扁，只给画廊静帧拧。
    public var squash: CGFloat
    /// 0 睁眼，1 闭成眼缝。连续值，不是硬切。
    public var blink: CGFloat
    /// 尾巴相对根部的角度，度。
    public var tailDegrees: Double
    /// ZZZ 上浮，0…1。
    public var zzzLift: CGFloat
    /// 吓到时的左右颤抖，−1…1。
    public var shake: CGFloat
    /// 吓到时的竖向拉长，0…1。
    public var stretch: CGFloat
    /// 视线水平偏移，viewBox 单位。正值向右。
    public var gazeX: CGFloat
    /// 视线竖直偏移，viewBox 单位。正值向下。
    public var gazeY: CGFloat
    /// 嘴相对原位的水平偏移。比视线小、比视线晚，不是同一条轨迹。
    public var mouthX: CGFloat
    /// 嘴相对原位的竖直偏移。
    public var mouthY: CGFloat
    /// 左耳相对耳根的角度，度。正值顺时针。
    public var leftEarDegrees: Double
    /// 右耳相对耳根的角度，度。正值顺时针。
    public var rightEarDegrees: Double

    public init(
        squash: CGFloat = 0,
        blink: CGFloat = 0,
        tailDegrees: Double = 2,
        zzzLift: CGFloat = 0.35,
        shake: CGFloat = 0,
        stretch: CGFloat = 0,
        gazeX: CGFloat = 0,
        gazeY: CGFloat = 0,
        mouthX: CGFloat = 0,
        mouthY: CGFloat = 0,
        leftEarDegrees: Double = 0,
        rightEarDegrees: Double = 0
    ) {
        self.squash = squash
        self.blink = blink
        self.tailDegrees = tailDegrees
        self.zzzLift = zzzLift
        self.shake = shake
        self.stretch = stretch
        self.gazeX = gazeX
        self.gazeY = gazeY
        self.mouthX = mouthX
        self.mouthY = mouthY
        self.leftEarDegrees = leftEarDegrees
        self.rightEarDegrees = rightEarDegrees
    }

    public static func still(for mood: CatMood) -> CatMotionFrame {
        still(for: mood.motion)
    }

    public static func still(for motion: CatMotionKind) -> CatMotionFrame {
        switch motion {
        case .shocked:
            CatMotionFrame(stretch: 1)
        case .sleeping:
            CatMotionFrame(tailDegrees: 2, zzzLift: 0.35)
        case .idle, .still:
            CatMotionFrame()
        }
    }
}

enum CatMotion {
    static let tailPeriod: TimeInterval = 2.4
    static let zzzPeriod: TimeInterval = 2.1
    static let shockPeriod: TimeInterval = 1.4
    static let flatten: CGFloat = 0.10
    static let tailMinDegrees: Double = -5
    static let tailMaxDegrees: Double = 8
    static let shockedStretchX: CGFloat = 0.94
    static let shockedStretchY: CGFloat = 1.12
    static let shakeAmplitude: CGFloat = 0.028
    /// 闭严时眼睛高度相对睁开的比例。和闭眼 path 的扁胶囊接近。
    static let closedLidScale: CGFloat = 0.40
    static let blinkDuration: TimeInterval = 0.18
    static let coverBlinkDuration: TimeInterval = 0.20
    static var coverSwapElapsed: TimeInterval { coverBlinkDuration * 0.45 }
    static let gazeXAmplitude: CGFloat = 24
    static let gazeYAmplitude: CGFloat = 12
    /// 嘴走视线的几成。1 就是整张脸在滑，呆。
    static let mouthFollowX: CGFloat = 0.36
    static let mouthFollowY: CGFloat = 0.30
    /// 嘴比眼睛晚多少秒。横竖错开，避免锁死成缩放后的同一条线。
    static let mouthLagX: TimeInterval = 0.18
    static let mouthLagY: TimeInterval = 0.26
    static let earMinDegrees: Double = -8
    static let earMaxDegrees: Double = 14
    static let earCycle: TimeInterval = 53.7
    static let earFlickDuration: TimeInterval = 0.32
    /// 长周期，对不上尾巴，肉眼对不上循环。
    static let blinkCycle: TimeInterval = 97.3

    /// 由绝对时间算出这一帧。
    ///
    /// 原来是三层嵌套的 `KeyframeAnimator`（压扁 / 眨眼 / 尾巴各一层，因为三者
    /// 周期不同）。嵌套的代价是外层每出一个值就重建内层动画器，实测整只猫会有
    /// 17% 的帧画不出来。改成纯函数以后只有一个时间源，而且能写单测。
    ///
    /// 常态不再压扁回弹：身体锁住，生命感留给视线、眨眼，和带着惯性的嘴。
    static func frame(for motion: CatMotionKind, at time: TimeInterval) -> CatMotionFrame {
        switch motion {
        case .still:
            return .still(for: motion)
        case .shocked:
            return CatMotionFrame(shake: shake(at: time), stretch: 1)
        case .sleeping:
            return CatMotionFrame(tailDegrees: tail(at: time), zzzLift: zzzLift(at: time))
        case .idle:
            return CatMotionFrame(
                blink: blink(at: time),
                tailDegrees: tail(at: time),
                gazeX: gazeX(at: time),
                gazeY: gazeY(at: time),
                mouthX: mouthX(at: time),
                mouthY: mouthY(at: time)
            )
        }
    }

    /// 快闭（前 45%）慢开（后 55%）。
    static func lidEnvelope(_ k: CGFloat) -> CGFloat {
        let clamped = min(max(k, 0), 1)
        if clamped < 0.45 {
            return ease(clamped / 0.45)
        }
        return 1 - ease((clamped - 0.45) / 0.55)
    }

    static func coverBlink(elapsed: TimeInterval) -> CGFloat {
        guard elapsed >= 0, elapsed < coverBlinkDuration else { return 0 }
        return lidEnvelope(CGFloat(elapsed / coverBlinkDuration))
    }

    static func blink(at time: TimeInterval) -> CGFloat {
        let local = cyclic(time, blinkCycle)
        var peak: CGFloat = 0
        for start in blinkStartsInCycle {
            peak = max(peak, lidAt(local, start: start))
            peak = max(peak, lidAt(local + blinkCycle, start: start))
        }
        return peak
    }

    static func gazeX(at time: TimeInterval) -> CGFloat {
        wave(time, period: 11.3, phase: 0.4) * 18
            + wave(time, period: 3.7, phase: 2.1) * 6
    }

    static func gazeY(at time: TimeInterval) -> CGFloat {
        wave(time, period: 9.1, phase: 1.3) * 9
            + wave(time, period: 4.3, phase: 0.7) * 3
    }

    static func mouthX(at time: TimeInterval) -> CGFloat {
        lagged(gazeX, at: time, lag: mouthLagX) * mouthFollowX
    }

    static func mouthY(at time: TimeInterval) -> CGFloat {
        lagged(gazeY, at: time, lag: mouthLagY) * mouthFollowY
    }

    /// 画廊打开耳朵之后才叠到帧上。生产 `frame(for:at:)` 不调它。
    static func applyEars(_ frame: inout CatMotionFrame, at time: TimeInterval) {
        frame.leftEarDegrees = leftEar(at: time)
        frame.rightEarDegrees = rightEar(at: time)
    }

    static func leftEar(at time: TimeInterval) -> Double {
        clampEar(
            sway(at: time, period: 5.3, phase: 0.8, amplitude: 3.6)
                + sway(at: time, period: 1.9, phase: 2.4, amplitude: 1.1)
                + earFlick(at: time, starts: leftEarFlickStarts, amplitude: 9)
        )
    }

    static func rightEar(at time: TimeInterval) -> Double {
        clampEar(
            sway(at: time, period: 6.1, phase: 1.7, amplitude: 3.2)
                + sway(at: time, period: 2.3, phase: 0.5, amplitude: 1.3)
                + earFlick(at: time, starts: rightEarFlickStarts, amplitude: 8.5)
        )
    }

    static func tail(at time: TimeInterval) -> Double {
        let phase = cyclic(time, tailPeriod) / tailPeriod
        let wave = 0.5 - 0.5 * cos(2 * .pi * phase)
        return tailMinDegrees + (tailMaxDegrees - tailMinDegrees) * wave
    }

    static func zzzLift(at time: TimeInterval) -> CGFloat {
        let phase = cyclic(time, zzzPeriod) / zzzPeriod
        return 0.15 + 0.85 * CGFloat(0.5 - 0.5 * cos(2 * .pi * phase))
    }

    /// 一惊之后颤两下就停，剩下的周期站着不动。
    static func shake(at time: TimeInterval) -> CGFloat {
        let phase = cyclic(time, shockPeriod)
        guard phase < 0.32 else { return 0 }
        let decay = 1 - phase / 0.32
        return CGFloat(sin(2 * .pi * phase / 0.08)) * decay
    }

    /// 三个 Z 错开相位。折成三角波：`zzzLift` 本身是来回摆的，直接相加会越界。
    static func zzzPhase(lift: CGFloat, index: Int) -> CGFloat {
        let shifted = lift + CGFloat(index) * 0.28
        return shifted > 1 ? 2 - shifted : shifted
    }

    static let leftEarFlickStarts: [TimeInterval] = flickStarts(seed: 0xE4A1)
    static let rightEarFlickStarts: [TimeInterval] = flickStarts(seed: 0xEA12)

    /// 种子写死：`sample(t)` 必须是时间的纯函数。
    static let blinkStartsInCycle: [TimeInterval] = {
        var rng = BlinkRNG(seed: 0x5EED)
        var times: [TimeInterval] = []
        var t = 1.4
        while t < blinkCycle - blinkDuration {
            times.append(t)
            t += 1.9 + rng.unit() * 2.7
            if rng.unit() < 0.18 {
                let extra = t
                if extra < blinkCycle - blinkDuration {
                    times.append(extra)
                }
                t += 0.24
            }
        }
        return times
    }()

    private static func sway(
        at time: TimeInterval,
        period: TimeInterval,
        phase: TimeInterval,
        amplitude: Double
    ) -> Double {
        Double(wave(time, period: period, phase: phase)) * amplitude
    }

    private static func earFlick(
        at time: TimeInterval,
        starts: [TimeInterval],
        amplitude: Double
    ) -> Double {
        let local = cyclic(time, earCycle)
        var peak = 0.0
        for start in starts {
            peak = max(peak, flickAt(local, start: start, amplitude: amplitude))
            peak = max(peak, flickAt(local + earCycle, start: start, amplitude: amplitude))
        }
        return peak
    }

    private static func flickAt(
        _ time: TimeInterval,
        start: TimeInterval,
        amplitude: Double
    ) -> Double {
        let k = (time - start) / earFlickDuration
        guard k >= 0, k <= 1 else { return 0 }
        if k < 0.3 {
            return amplitude * Double(ease(CGFloat(k / 0.3)))
        }
        return amplitude * Double(1 - ease(CGFloat((k - 0.3) / 0.7)))
    }

    private static func flickStarts(seed: UInt32) -> [TimeInterval] {
        var rng = BlinkRNG(seed: seed)
        var times: [TimeInterval] = []
        var t = 2.1
        while t < earCycle - earFlickDuration {
            times.append(t)
            t += 3.2 + rng.unit() * 5.5
        }
        return times
    }

    private static func clampEar(_ value: Double) -> Double {
        min(max(value, earMinDegrees), earMaxDegrees)
    }

    private static func lidAt(_ time: TimeInterval, start: TimeInterval) -> CGFloat {
        let k = (time - start) / blinkDuration
        guard k >= 0, k <= 1 else { return 0 }
        return lidEnvelope(CGFloat(k))
    }

    private static func wave(_ time: TimeInterval, period: TimeInterval, phase: TimeInterval) -> CGFloat {
        CGFloat(sin((time + phase) * 2 * .pi / period))
    }

    /// 现在的取样掺一点更早的。单纯 `gaze(t − lag)` 只是相位平移，看起来还是在抄眼睛。
    private static func lagged(
        _ sample: (TimeInterval) -> CGFloat,
        at time: TimeInterval,
        lag: TimeInterval
    ) -> CGFloat {
        0.7 * sample(time - lag) + 0.3 * sample(time - lag * 2.2)
    }

    private static func cyclic(_ time: TimeInterval, _ period: TimeInterval) -> TimeInterval {
        let remainder = time.truncatingRemainder(dividingBy: period)
        return remainder < 0 ? remainder + period : remainder
    }

    /// 头尾都缓，中间快。
    private static func ease(_ t: CGFloat) -> CGFloat {
        let clamped = min(max(t, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    /// 只给眨眼 / 耳朵时刻表用。不要拿来做运行时随机。
    private struct BlinkRNG {
        var state: UInt32

        init(seed: UInt32) {
            state = seed == 0 ? 1 : seed
        }

        mutating func unit() -> Double {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Double(state) / Double(UInt32.max)
        }
    }
}
