import SwiftUI
import Testing
import MeterDesign
@testable import MeterFeatures

struct UsesPadChromeTests {
    @Test("壳是一个值：宽版式从它派生，只有一个出处")
    func shellDerivesWideChrome() {
        #expect(MeterShell.phone.usesWideChrome == false)
        #expect(MeterShell.pad.usesWideChrome)
        #expect(MeterShell.mac.usesWideChrome)
        // Mac 上尺寸类和横竖屏都不作数。
        #expect(
            UsesPadChrome.shell(
                sizeClass: .compact,
                size: CGSize(width: 390, height: 844),
                platform: .mac
            ) == .mac
        )
        // iOS 上横屏 regular 才是 iPad 壳。
        #expect(
            UsesPadChrome.shell(
                sizeClass: .regular,
                size: CGSize(width: 1194, height: 834),
                platform: .phone
            ) == .pad
        )
        #expect(
            UsesPadChrome.shell(
                sizeClass: .regular,
                size: CGSize(width: 834, height: 1194),
                platform: .phone
            ) == .phone
        )
    }

    @Test("Mac 上开场第 3 页那句话不提主屏和锁屏")
    func macOnboardingCopyDropsHomeScreen() {
        let mac = String(localized: OnboardingPage.widget.body(shell: .mac))
        let phone = String(localized: OnboardingPage.widget.body(shell: .phone))
        #expect(mac != phone)
        #expect(!mac.contains("锁屏"))
        #expect(phone.contains("锁屏"))
    }

    @Test("compact 一律走手机壳，和窗口长宽无关")
    func compactNeverUsesPadChrome() {
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .compact,
                size: CGSize(width: 1194, height: 834)
            ) == false
        )
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .compact,
                size: CGSize(width: 390, height: 844)
            ) == false
        )
    }

    @Test("regular 竖屏走手机壳")
    func regularPortraitUsesPhoneChrome() {
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .regular,
                size: CGSize(width: 834, height: 1194)
            ) == false
        )
    }

    @Test("regular 横屏才走 iPad 壳")
    func regularLandscapeUsesPadChrome() {
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .regular,
                size: CGSize(width: 1194, height: 834)
            )
        )
    }

    @Test("还没量到窗口时不要误开 iPad 壳")
    func zeroSizeStaysOnPhoneChrome() {
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .regular,
                size: .zero
            ) == false
        )
    }

    @Test("Mac 恒开宽壳，和尺寸、size class 无关")
    func macForcesWideChrome() {
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .compact,
                size: .zero,
                forcesWideChrome: true
            )
        )
        #expect(
            UsesPadChrome.isActive(
                sizeClass: .regular,
                size: CGSize(width: 600, height: 900),
                forcesWideChrome: true
            )
        )
    }
}
