// 用 Info.plist 里那把公钥核对 Sparkle 的 EdDSA 签名。不需要私钥，也不需要 Sparkle 工具链，
// 任何拿到 zip 和 appcast 的人都能跑；package-mac-release.sh 在签完之后也用它自检一次。
//
//   swift scripts/verify-sparkle-signature.swift <update.zip> <sparkle:edSignature> <SUPublicEDKey>
import CryptoKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    FileHandle.standardError.write(Data("usage: verify-sparkle-signature.swift <file> <edSignature> <publicKey>\n".utf8))
    exit(2)
}
let payload = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
guard let signature = Data(base64Encoded: arguments[2]),
      let publicKeyRaw = Data(base64Encoded: arguments[3]) else {
    FileHandle.standardError.write(Data("verify-sparkle-signature: signature or key is not base64\n".utf8))
    exit(1)
}
let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyRaw)
if publicKey.isValidSignature(signature, for: payload) {
    print("signature ok")
} else {
    FileHandle.standardError.write(Data("verify-sparkle-signature: BAD SIGNATURE\n".utf8))
    exit(1)
}
