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

    /// iPhone Duo（iOS 27.1）：外屏 466×678，compact 宽；内屏 669×951，两向都是 regular，
    /// 而且内屏不认竖屏锁，横过来就是 951×669。折叠、展开、转向都会在这几格之间跳，
    /// 换判据之前先看这一条。
    @Test("iPhone Duo：合上和打开竖拿走手机壳，打开横拿才是 iPad 壳")
    func iPhoneDuoPoses() {
        // 合上，外屏竖拿。竖屏锁对外屏有效。
        #expect(
            UsesPadChrome.shell(
                sizeClass: .compact,
                size: CGSize(width: 466, height: 678),
                platform: .phone
            ) == .phone
        )
        // 打开竖拿：regular 但竖着，和 iPad 竖屏同一条规则。合上 ↔ 打开不换壳，
        // 我们自己的视图树不拆（尺寸类只有 RootView 读）；系统那层是否保住推进去的页，
        // 要在 Device Hub 里看。
        #expect(
            UsesPadChrome.shell(
                sizeClass: .regular,
                size: CGSize(width: 669, height: 951),
                platform: .phone
            ) == .phone
        )
        // 打开横拿。
        #expect(
            UsesPadChrome.shell(
                sizeClass: .regular,
                size: CGSize(width: 951, height: 669),
                platform: .phone
            ) == .pad
        )
        // 内屏分屏：每边 compact，不管长宽都是手机壳。半屏的确切点数以 Device Hub 为准。
        #expect(
            UsesPadChrome.shell(
                sizeClass: .compact,
                size: CGSize(width: 475, height: 669),
                platform: .phone
            ) == .phone
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
