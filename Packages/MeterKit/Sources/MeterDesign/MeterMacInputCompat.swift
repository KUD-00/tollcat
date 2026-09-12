#if os(macOS)
import SwiftUI

/// Mac 没有软件键盘。这些 iOS 修饰符在调用点保持原样，这里变成空操作。
public enum TextInputAutocapitalization {
    case never
    case characters
    case words
    case sentences
}

public struct UIKeyboardType: Equatable, Sendable {
    public static let decimalPad = UIKeyboardType()
    public static let emailAddress = UIKeyboardType()
    public static let asciiCapable = UIKeyboardType()
    public static let `default` = UIKeyboardType()
}

public extension View {
    func textInputAutocapitalization(
        _ autocapitalization: TextInputAutocapitalization
    ) -> some View {
        self
    }

    func keyboardType(_ type: UIKeyboardType) -> some View {
        self
    }
}
#endif
