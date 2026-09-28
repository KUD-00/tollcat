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
        // 是终端就必须真的关掉回显才读：关不掉还照读，凭据会明文显示在屏幕上。
        // TCSAFLUSH 丢掉关回显之前已经敲进来的内容，免得被当成凭据吞掉。
        var next = original
        next.c_lflag &= ~tcflag_t(ECHO)
        guard tcsetattr(fd, TCSAFLUSH, &next) == 0 else { return nil }
        var applied = termios()
        guard tcgetattr(fd, &applied) == 0, applied.c_lflag & tcflag_t(ECHO) == 0 else {
            _ = tcsetattr(fd, TCSANOW, &original)
            return nil
        }
        defer {
            _ = tcsetattr(fd, TCSANOW, &original)
            FileHandle.standardError.write(Data("\n".utf8))
        }
        return Swift.readLine()
    }
}
