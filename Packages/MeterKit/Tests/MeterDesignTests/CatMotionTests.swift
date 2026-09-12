import Testing
import Foundation
@testable import MeterDesign

/// 动效以前是三层嵌套的 `KeyframeAnimator`，测不了；改成时间的纯函数之后才有这组测试。
@Suite("CatMotion")
struct CatMotionTests {

    @Test("常态不压扁，身体锁住")
    func idleDoesNotSquash() {
        for step in 0..<400 {
            let frame = CatMotion.frame(for: .idle, at: Double(step) * 0.05)
            #expect(frame.squash == 0)
            #expect(frame.stretch == 0)
            #expect(abs(frame.gazeX) <= CatMotion.gazeXAmplitude + 0.001)
            #expect(abs(frame.gazeY) <= CatMotion.gazeYAmplitude + 0.001)
            #expect(frame.leftEarDegrees == 0)
            #expect(frame.rightEarDegrees == 0)
        }
    }

    @Test("常态会看向别处")
    func idleGazeWanders() {
        var farthest: CGFloat = 0
        for step in 0..<400 {
            let frame = CatMotion.frame(for: .idle, at: Double(step) * 0.05)
            farthest = max(farthest, abs(frame.gazeX) + abs(frame.gazeY))
        }
        #expect(farthest > 8)
    }

    @Test("嘴跟着视线走，但更小、更晚")
    func mouthFollowsGazeWithInertia() {
        var farthest: CGFloat = 0
        var lockstep = 0
        var drifted = 0
        for step in 0..<400 {
            let time = Double(step) * 0.05
            let frame = CatMotion.frame(for: .idle, at: time)
            farthest = max(farthest, abs(frame.mouthX) + abs(frame.mouthY))
            #expect(abs(frame.mouthX) <= CatMotion.gazeXAmplitude * CatMotion.mouthFollowX + 0.001)
            #expect(abs(frame.mouthY) <= CatMotion.gazeYAmplitude * CatMotion.mouthFollowY + 0.001)
            #expect(abs(frame.mouthX - CatMotion.mouthX(at: time)) < 0.0001)

            let asEyes = CatMotion.gazeX(at: time) * CatMotion.mouthFollowX
            if abs(frame.mouthX - asEyes) < 0.05 {
                lockstep += 1
            } else {
                drifted += 1
            }
        }
        #expect(farthest > 2)
        #expect(drifted > lockstep)
        #expect(CatMotion.mouthFollowX < 1)
        #expect(CatMotion.mouthFollowY < 1)
        #expect(CatMotion.mouthLagX > 0)
        #expect(CatMotion.mouthLagY != CatMotion.mouthLagX)
    }

    @Test("画廊打开耳朵之后左右不同步")
    func earTwitchIsAsymmetric() {
        var farthest: Double = 0
        var differed = 0
        for step in 0..<400 {
            let time = Double(step) * 0.05
            var frame = CatMotion.frame(for: .idle, at: time)
            CatMotion.applyEars(&frame, at: time)
            farthest = max(farthest, abs(frame.leftEarDegrees) + abs(frame.rightEarDegrees))
            #expect(frame.leftEarDegrees >= CatMotion.earMinDegrees - 0.001)
            #expect(frame.leftEarDegrees <= CatMotion.earMaxDegrees + 0.001)
            #expect(frame.rightEarDegrees >= CatMotion.earMinDegrees - 0.001)
            #expect(frame.rightEarDegrees <= CatMotion.earMaxDegrees + 0.001)
            if abs(frame.leftEarDegrees - frame.rightEarDegrees) > 0.4 {
                differed += 1
            }
        }
        #expect(farthest > 4)
        #expect(differed > 50)
    }

    @Test("尾巴始终在两个极限角之间")
    func tailStaysWithinLimits() {
        for step in 0..<400 {
            let value = CatMotion.tail(at: Double(step) * 0.01)
            #expect(value >= CatMotion.tailMinDegrees - 0.001)
            #expect(value <= CatMotion.tailMaxDegrees + 0.001)
        }
    }

    @Test("眨眼是眼皮，不是硬切")
    func blinkIsALid() {
        let samples = 4000
        let step = 0.01
        var mid = 0
        var closed = 0
        var peak: CGFloat = 0
        for index in 0..<samples {
            let value = CatMotion.blink(at: Double(index) * step)
            if value > 0.15 && value < 0.85 { mid += 1 }
            if value > 0.5 { closed += 1 }
            peak = max(peak, value)
        }
        #expect(mid > 0)
        #expect(peak > 0.9)
        #expect(Double(closed) / Double(samples) < 0.12)
    }

    @Test("时刻表里有连眨")
    func scheduleHasDoubleBlink() {
        let starts = CatMotion.blinkStartsInCycle
        #expect(starts.count > 8)
        var found = false
        for index in 1..<starts.count {
            if starts[index] - starts[index - 1] < 0.3 {
                found = true
                break
            }
        }
        #expect(found)
    }

    @Test("换脸那次眨眼在闭眼时最深")
    func coverBlinkPeaksAtSwap() {
        #expect(CatMotion.coverBlink(elapsed: -0.1) == 0)
        #expect(CatMotion.coverBlink(elapsed: CatMotion.coverBlinkDuration) == 0)
        let peak = CatMotion.coverBlink(elapsed: CatMotion.coverSwapElapsed)
        #expect(peak > 0.9)
        #expect(CatMotion.coverBlink(elapsed: 0.04) < peak)
        #expect(CatMotion.coverBlink(elapsed: 0.16) < peak)
    }

    @Test("尾巴和 ZZZ 周期到了就回到原处")
    func everyWaveIsPeriodic() {
        let time = 3.7
        #expect(abs(CatMotion.tail(at: time) - CatMotion.tail(at: time + CatMotion.tailPeriod)) < 0.0001)
        #expect(abs(CatMotion.zzzLift(at: time) - CatMotion.zzzLift(at: time + CatMotion.zzzPeriod)) < 0.0001)
    }

    @Test("负时间不炸，也落在同一区间")
    func handlesNegativeTime() {
        let value = CatMotion.tail(at: -12.3)
        #expect(value >= CatMotion.tailMinDegrees - 0.001)
        #expect(value <= CatMotion.tailMaxDegrees + 0.001)
        #expect(CatMotion.zzzLift(at: -5) >= 0.15 - 0.001)
        let blink = CatMotion.blink(at: -1)
        #expect(blink >= 0)
        #expect(blink <= 1)
    }

    @Test("吓到只在开头颤两下，之后站着不动")
    func shakeSettles() {
        #expect(CatMotion.shake(at: 0.5) == 0)
        #expect(CatMotion.shake(at: 1.0) == 0)
        var peak: CGFloat = 0
        for step in 0..<64 {
            peak = max(peak, abs(CatMotion.shake(at: Double(step) * 0.005)))
        }
        #expect(peak > 0.5)
        #expect(peak <= 1.001)
    }

    @Test("三个 Z 的相位都落在 0…1，且互不相同")
    func zzzPhasesStayNormalised() {
        for lift in stride(from: 0.15, through: 1.0, by: 0.05) {
            let phases = (0..<3).map { CatMotion.zzzPhase(lift: CGFloat(lift), index: $0) }
            for phase in phases {
                #expect(phase >= 0)
                #expect(phase <= 1.001)
            }
            #expect(Set(phases).count == 3)
        }
    }

    @Test("翻肚皮不动：这只猫已经不动了")
    func deadCatDoesNotMove() {
        let first = CatMotion.frame(for: CatMood.dead.motion, at: 0)
        let later = CatMotion.frame(for: CatMood.dead.motion, at: 7.3)
        #expect(first == later)
        #expect(first == .still(for: CatMood.dead))
    }

    @Test("睡觉不压扁，没有视线，只有尾巴和 ZZZ 在动")
    func sleepingOnlyBreathesAndFloats() {
        let frame = CatMotion.frame(for: CatMood.sleeping.motion, at: 1.1)
        #expect(frame.squash == 0)
        #expect(frame.stretch == 0)
        #expect(frame.shake == 0)
        #expect(frame.gazeX == 0)
        #expect(frame.gazeY == 0)
        #expect(frame.mouthX == 0)
        #expect(frame.mouthY == 0)
        #expect(frame.leftEarDegrees == 0)
        #expect(frame.rightEarDegrees == 0)
        #expect(frame.blink == 0)
    }

    @Test("吓到不眨眼也不东张西望")
    func shockedStares() {
        let frame = CatMotion.frame(for: .shocked, at: 0.1)
        #expect(frame.blink == 0)
        #expect(frame.gazeX == 0)
        #expect(frame.gazeY == 0)
        #expect(frame.mouthX == 0)
        #expect(frame.mouthY == 0)
        #expect(frame.leftEarDegrees == 0)
        #expect(frame.rightEarDegrees == 0)
        #expect(frame.stretch == 1)
    }

    @Test("吊眼的眉和眼珠是分开的")
    func alertEyesSplitFromBrows() {
        #expect(CatArtwork.eyeballShapes(for: .alert).count == 2)
        #expect(CatArtwork.eyeMarkShapes(for: .alert).count == 2)
        #expect(CatArtwork.eyeMarkShapes(for: .normal).isEmpty)
        #expect(CatArtwork.eyeballShapes(for: .normal).count == 2)
    }
}
