package com.zhechengqi.tollcat.ui.cat

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** 一帧的动效参数。 */
data class CatMotionFrame(
    /** 0 静止；1 压扁满振幅；负值是回弹。常态循环不再压扁，只给画廊静帧拧。 */
    val squash: Float = 0f,
    /** 0 睁眼，1 闭成眼缝。连续值，不是硬切。 */
    val blink: Float = 0f,
    /** 尾巴相对根部的角度，度。 */
    val tailDegrees: Float = 2f,
    /** ZZZ 上浮，0…1。 */
    val zzzLift: Float = 0.35f,
    /** 吓到时的左右颤抖，−1…1。 */
    val shake: Float = 0f,
    /** 吓到时的竖向拉长，0…1。 */
    val stretch: Float = 0f,
    /** 视线水平偏移，viewBox 单位。正值向右。 */
    val gazeX: Float = 0f,
    /** 视线竖直偏移，viewBox 单位。正值向下。 */
    val gazeY: Float = 0f,
    /** 嘴相对原位的水平偏移。比视线小、比视线晚，不是同一条轨迹。 */
    val mouthX: Float = 0f,
    /** 嘴相对原位的竖直偏移。 */
    val mouthY: Float = 0f,
    /** 左耳相对耳根的角度，度。正值顺时针。 */
    val leftEarDegrees: Float = 0f,
    /** 右耳相对耳根的角度，度。正值顺时针。 */
    val rightEarDegrees: Float = 0f,
) {
    companion object {
        fun still(motion: CatMotionKind): CatMotionFrame = when (motion) {
            CatMotionKind.Shocked -> CatMotionFrame(stretch = 1f)
            CatMotionKind.Sleeping -> CatMotionFrame(tailDegrees = 2f, zzzLift = 0.35f)
            CatMotionKind.Idle, CatMotionKind.Still -> CatMotionFrame()
        }

        fun still(mood: CatMood): CatMotionFrame = still(mood.motion)
    }
}

/**
 * 由绝对时间算出这一帧，纯函数、可单测。一个时间源驱动整只猫，
 * 和 iOS `MeterDesign.CatMotion` 同一套常量与曲线。
 */
internal object CatMotion {
    const val TAIL_PERIOD = 2.4
    const val ZZZ_PERIOD = 2.1
    const val SHOCK_PERIOD = 1.4
    const val FLATTEN = 0.10f
    const val TAIL_MIN_DEGREES = -5.0
    const val TAIL_MAX_DEGREES = 8.0
    const val SHOCKED_STRETCH_X = 0.94f
    const val SHOCKED_STRETCH_Y = 1.12f
    const val SHAKE_AMPLITUDE = 0.028f

    /** 闭严时眼睛高度相对睁开的比例。和闭眼 path 的扁胶囊接近。 */
    const val CLOSED_LID_SCALE = 0.40f
    const val BLINK_DURATION = 0.18
    const val COVER_BLINK_DURATION = 0.20
    val COVER_SWAP_ELAPSED = COVER_BLINK_DURATION * 0.45

    /** 视线摆幅上界（两条波的振幅合计），viewBox 单位。测试拿它当断言边界。 */
    const val GAZE_X_AMPLITUDE = 24f
    const val GAZE_Y_AMPLITUDE = 12f

    /** 嘴走视线的几成。1 就是整张脸在滑，呆。 */
    const val MOUTH_FOLLOW_X = 0.36f
    const val MOUTH_FOLLOW_Y = 0.30f

    /** 嘴比眼睛晚多少秒。横竖错开，避免锁死成缩放后的同一条线。 */
    const val MOUTH_LAG_X = 0.18
    const val MOUTH_LAG_Y = 0.26
    const val EAR_MIN_DEGREES = -8.0
    const val EAR_MAX_DEGREES = 14.0
    const val EAR_CYCLE = 53.7
    const val EAR_FLICK_DURATION = 0.32

    /** 长周期，对不上尾巴，肉眼对不上循环。 */
    const val BLINK_CYCLE = 97.3

    /** 常态不压扁回弹：身体锁住，生命感留给视线、眨眼，和带着惯性的嘴。 */
    fun frame(motion: CatMotionKind, time: Double): CatMotionFrame = when (motion) {
        CatMotionKind.Still -> CatMotionFrame.still(motion)
        CatMotionKind.Shocked -> CatMotionFrame(shake = shake(time), stretch = 1f)
        CatMotionKind.Sleeping -> CatMotionFrame(tailDegrees = tail(time), zzzLift = zzzLift(time))
        CatMotionKind.Idle -> CatMotionFrame(
            blink = blink(time),
            tailDegrees = tail(time),
            gazeX = gazeX(time),
            gazeY = gazeY(time),
            mouthX = mouthX(time),
            mouthY = mouthY(time),
        )
    }

    /** 快闭（前 45%）慢开（后 55%）。 */
    fun lidEnvelope(k: Float): Float {
        val clamped = k.coerceIn(0f, 1f)
        if (clamped < 0.45f) {
            return ease(clamped / 0.45f)
        }
        return 1f - ease((clamped - 0.45f) / 0.55f)
    }

    fun coverBlink(elapsed: Double): Float {
        if (elapsed < 0 || elapsed >= COVER_BLINK_DURATION) return 0f
        return lidEnvelope((elapsed / COVER_BLINK_DURATION).toFloat())
    }

    fun blink(time: Double): Float {
        val local = cyclic(time, BLINK_CYCLE)
        var peak = 0f
        for (start in blinkStartsInCycle) {
            peak = max(peak, lidAt(local, start))
            peak = max(peak, lidAt(local + BLINK_CYCLE, start))
        }
        return peak
    }

    fun gazeX(time: Double): Float =
        wave(time, period = 11.3, phase = 0.4) * 18f +
            wave(time, period = 3.7, phase = 2.1) * 6f

    fun gazeY(time: Double): Float =
        wave(time, period = 9.1, phase = 1.3) * 9f +
            wave(time, period = 4.3, phase = 0.7) * 3f

    fun mouthX(time: Double): Float = lagged(::gazeX, time, MOUTH_LAG_X) * MOUTH_FOLLOW_X

    fun mouthY(time: Double): Float = lagged(::gazeY, time, MOUTH_LAG_Y) * MOUTH_FOLLOW_Y

    /** 画廊打开耳朵之后才叠到帧上。生产 [frame] 不调它。 */
    fun applyEars(frame: CatMotionFrame, time: Double): CatMotionFrame = frame.copy(
        leftEarDegrees = leftEar(time),
        rightEarDegrees = rightEar(time),
    )

    fun leftEar(time: Double): Float = clampEar(
        sway(time, period = 5.3, phase = 0.8, amplitude = 3.6) +
            sway(time, period = 1.9, phase = 2.4, amplitude = 1.1) +
            earFlick(time, leftEarFlickStarts, amplitude = 9.0),
    )

    fun rightEar(time: Double): Float = clampEar(
        sway(time, period = 6.1, phase = 1.7, amplitude = 3.2) +
            sway(time, period = 2.3, phase = 0.5, amplitude = 1.3) +
            earFlick(time, rightEarFlickStarts, amplitude = 8.5),
    )

    fun tail(time: Double): Float {
        val phase = cyclic(time, TAIL_PERIOD) / TAIL_PERIOD
        val wave = 0.5 - 0.5 * cos(2 * PI * phase)
        return (TAIL_MIN_DEGREES + (TAIL_MAX_DEGREES - TAIL_MIN_DEGREES) * wave).toFloat()
    }

    fun zzzLift(time: Double): Float {
        val phase = cyclic(time, ZZZ_PERIOD) / ZZZ_PERIOD
        return (0.15 + 0.85 * (0.5 - 0.5 * cos(2 * PI * phase))).toFloat()
    }

    /** 一惊之后颤两下就停，剩下的周期站着不动。 */
    fun shake(time: Double): Float {
        val phase = cyclic(time, SHOCK_PERIOD)
        if (phase >= 0.32) return 0f
        val decay = 1 - phase / 0.32
        return (sin(2 * PI * phase / 0.08) * decay).toFloat()
    }

    /** 三个 Z 错开相位。折成三角波：`zzzLift` 本身是来回摆的，直接相加会越界。 */
    fun zzzPhase(lift: Float, index: Int): Float {
        val shifted = lift + index * 0.28f
        return if (shifted > 1f) 2f - shifted else shifted
    }

    private val leftEarFlickStarts: List<Double> = flickStarts(seed = 0xE4A1)
    private val rightEarFlickStarts: List<Double> = flickStarts(seed = 0xEA12)

    /** 种子写死：`frame(t)` 必须是时间的纯函数。 */
    private val blinkStartsInCycle: List<Double> = buildList {
        val rng = BlinkRng(seed = 0x5EED)
        var t = 1.4
        while (t < BLINK_CYCLE - BLINK_DURATION) {
            add(t)
            t += 1.9 + rng.unit() * 2.7
            if (rng.unit() < 0.18) {
                if (t < BLINK_CYCLE - BLINK_DURATION) {
                    add(t)
                }
                t += 0.24
            }
        }
    }

    private fun sway(time: Double, period: Double, phase: Double, amplitude: Double): Double =
        wave(time, period, phase) * amplitude

    private fun earFlick(time: Double, starts: List<Double>, amplitude: Double): Double {
        val local = cyclic(time, EAR_CYCLE)
        var peak = 0.0
        for (start in starts) {
            peak = max(peak, flickAt(local, start, amplitude))
            peak = max(peak, flickAt(local + EAR_CYCLE, start, amplitude))
        }
        return peak
    }

    private fun flickAt(time: Double, start: Double, amplitude: Double): Double {
        val k = (time - start) / EAR_FLICK_DURATION
        if (k < 0 || k > 1) return 0.0
        if (k < 0.3) {
            return amplitude * ease(k / 0.3)
        }
        return amplitude * (1 - ease((k - 0.3) / 0.7))
    }

    private fun flickStarts(seed: Int): List<Double> = buildList {
        val rng = BlinkRng(seed)
        var t = 2.1
        while (t < EAR_CYCLE - EAR_FLICK_DURATION) {
            add(t)
            t += 3.2 + rng.unit() * 5.5
        }
    }

    private fun clampEar(value: Double): Float =
        min(max(value, EAR_MIN_DEGREES), EAR_MAX_DEGREES).toFloat()

    private fun lidAt(time: Double, start: Double): Float {
        val k = (time - start) / BLINK_DURATION
        if (k < 0 || k > 1) return 0f
        return lidEnvelope(k.toFloat())
    }

    private fun wave(time: Double, period: Double, phase: Double): Float =
        sin((time + phase) * 2 * PI / period).toFloat()

    /** 现在的取样掺一点更早的。单纯 `gaze(t − lag)` 只是相位平移，看起来还是在抄眼睛。 */
    private fun lagged(sample: (Double) -> Float, time: Double, lag: Double): Float =
        0.7f * sample(time - lag) + 0.3f * sample(time - lag * 2.2)

    private fun cyclic(time: Double, period: Double): Double {
        val remainder = time % period
        return if (remainder < 0) remainder + period else remainder
    }

    /** 头尾都缓，中间快。 */
    private fun ease(t: Float): Float {
        val clamped = t.coerceIn(0f, 1f)
        return clamped * clamped * (3 - 2 * clamped)
    }

    private fun ease(t: Double): Double = ease(t.toFloat()).toDouble()

    /** 只给眨眼 / 耳朵时刻表用。不要拿来做运行时随机。 */
    private class BlinkRng(seed: Int) {
        private var state: Long = (if (seed == 0) 1 else seed).toLong() and 0xFFFFFFFFL

        fun unit(): Double {
            state = (state * 1_664_525L + 1_013_904_223L) and 0xFFFFFFFFL
            return state.toDouble() / 4_294_967_295.0
        }
    }
}
