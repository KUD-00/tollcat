// 从 Sparkle 的 EdDSA 私钥文件（generate_keys -x 导出）算出公钥，
// 供 package-mac-release.sh 在发版前和 Info.plist 里的 SUPublicEDKey 比对。
// 不走 Keychain：CI 上私钥只在文件里，generate_keys -p 读不到。
//
//   swift scripts/sparkle-public-key.swift <private-key-file>
import CryptoKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: sparkle-public-key.swift <private-key-file>\n".utf8))
    exit(2)
}
let text = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
guard let raw = Data(base64Encoded: text) else {
    FileHandle.standardError.write(Data("sparkle-public-key: key file is not base64\n".utf8))
    exit(1)
}
// Sparkle 2 新格式是 32 字节种子；旧格式是 64 字节私钥拼 32 字节公钥，前 32 字节同样是种子。
let seed = raw.count == 96 ? raw.prefix(32) : raw
let key = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
print(key.publicKey.rawRepresentation.base64EncodedString())
