enum TextWidth {
    static func displayWidth(_ text: String) -> Int {
        text.reduce(0) { partial, character in
            partial + (character.isASCII ? 1 : 2)
        }
    }

    static func pad(_ text: String, _ width: Int, alignRight: Bool = false) -> String {
        let extra = width - displayWidth(text)
        if extra <= 0 { return text }
        let spaces = String(repeating: " ", count: extra)
        return alignRight ? spaces + text : text + spaces
    }
}
