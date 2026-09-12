import CoreGraphics
import Testing
@testable import MeterDesign

struct SoftwareKeyboardTests {
    private let phone = CGRect(x: 0, y: 0, width: 393, height: 852)

    @Test("软件键盘盖住屏幕")
    func softwareKeyboardCoversTheScreen() {
        let keyboard = CGRect(x: 0, y: 520, width: 393, height: 332)
        #expect(SoftwareKeyboard.isCoveringScreen(endFrame: keyboard, screen: phone))
    }

    @Test("外接键盘只剩附件栏，不算盖住")
    func accessoryOnlyDoesNotCount() {
        let accessory = CGRect(x: 0, y: 768, width: 393, height: 84)
        #expect(!SoftwareKeyboard.isCoveringScreen(endFrame: accessory, screen: phone))
    }

    @Test("完全移出屏幕不算")
    func offscreenDoesNotCount() {
        let off = CGRect(x: 0, y: 852, width: 393, height: 332)
        #expect(!SoftwareKeyboard.isCoveringScreen(endFrame: off, screen: phone))
    }

    @Test("坐标系对不上时，仍凭高度和上沿判断")
    func tallFrameInsideScreenStillCounts() {
        let local = CGRect(x: 0, y: 400, width: 393, height: 280)
        #expect(SoftwareKeyboard.isCoveringScreen(endFrame: local, screen: phone))
    }

    @Test("容器 chrome 收导航栏和 Home Indicator")
    func acceptsContainerChrome() {
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 32, proposed: 90) == 90)
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 0, proposed: 90) == 90)
    }

    @Test("安全区跟着 sheet 抖几 pt 不能写进 detent")
    func ignoresChromeJitter() {
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 90, proposed: 84) == 90)
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 90, proposed: 94) == 90)
    }

    @Test("键盘灌进 bottom inset 不能写进 detent")
    func rejectsKeyboardSizedChrome() {
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 90, proposed: 420) == 90)
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 90, proposed: 0) == 90)
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 90, proposed: .nan) == 90)
        #expect(SoftwareKeyboard.acceptedChromeHeight(current: 90, proposed: .infinity) == 90)
    }
}
