import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum SecretLine {
    static func read() -> String? {
        var original = termios()
        let fd = STDIN_FILENO
        guard tcgetattr(fd, &original) == 0 else {
            return Swift.readLine()
        }
        var next = original
        next.c_lflag &= ~tcflag_t(ECHO)
        _ = tcsetattr(fd, TCSANOW, &next)
        defer {
            _ = tcsetattr(fd, TCSANOW, &original)
            FileHandle.standardError.write(Data("\n".utf8))
        }
        return Swift.readLine()
    }
}
