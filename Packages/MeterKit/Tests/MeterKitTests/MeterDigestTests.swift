import Foundation
import Testing
@testable import MeterCore

/// 官方测试向量。摘要是照着规范抄的，所以这里钉的是**规范给的答案**，
/// 而不是「跑一遍记下来的答案」——后者只能证明代码没变过，证明不了它是对的。
struct MeterDigestTests {
    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - RFC 1321 附录 A.5

    @Test func md5Empty() {
        #expect(hex(MeterDigest.md5(Data())) == "d41d8cd98f00b204e9800998ecf8427e")
    }

    @Test func md5abc() {
        #expect(hex(MeterDigest.md5(Data("abc".utf8))) == "900150983cd24fb0d6963f7d28e17f72")
    }

    /// 80 字节：跨块 + 长度字段小端，两处一起验。
    @Test func md5AcrossBlocks() {
        let input = String(repeating: "1234567890", count: 8)
        #expect(hex(MeterDigest.md5(Data(input.utf8))) == "57edf4a22be3c955ac49da2e2107b67a")
    }

    // MARK: - RFC 3174 / FIPS 180-4

    @Test func sha1Empty() {
        #expect(hex(MeterDigest.sha1(Data())) == "da39a3ee5e6b4b0d3255bfef95601890afd80709")
    }

    @Test func sha1abc() {
        #expect(hex(MeterDigest.sha1(Data("abc".utf8))) == "a9993e364706816aba3e25717850c26c9cd0d89d")
    }

    @Test func sha1AcrossBlocks() {
        let input = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        #expect(hex(MeterDigest.sha1(Data(input.utf8))) == "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
    }

    @Test func sha256Empty() {
        #expect(
            hex(MeterDigest.sha256(Data()))
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }

    @Test func sha256abc() {
        #expect(
            hex(MeterDigest.sha256(Data("abc".utf8)))
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    @Test func sha256AcrossBlocks() {
        let input = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        #expect(
            hex(MeterDigest.sha256(Data(input.utf8)))
                == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
        )
    }

    @Test func sha384abc() {
        #expect(
            hex(MeterDigest.sha384(Data("abc".utf8)))
                == "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed"
                    + "8086072ba1e7cc2358baeca134c825a7"
        )
    }

    /// 112 字节：SHA-512 家族的块是 128 字节，这条落在补位的边界上。
    @Test func sha384AcrossBlocks() {
        let input = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn"
            + "hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
        #expect(
            hex(MeterDigest.sha384(Data(input.utf8)))
                == "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712"
                    + "fcc7c71a557e2db966c3e9fa91746039"
        )
    }

    @Test func sha512abc() {
        #expect(
            hex(MeterDigest.sha512(Data("abc".utf8)))
                == "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
                    + "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
        )
    }

    // MARK: - RFC 4231 / RFC 2202

    @Test func hmacSha256Case1() {
        #expect(
            hex(MeterHMAC.sha256(key: Data(repeating: 0x0b, count: 20), message: Data("Hi There".utf8)))
                == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"
        )
    }

    @Test func hmacSha256Case2() {
        #expect(
            hex(MeterHMAC.sha256(
                key: Data("Jefe".utf8),
                message: Data("what do ya want for nothing?".utf8)
            )) == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"
        )
    }

    /// key 比块长时要先摘要再补零。写错这一步只在长 secret 上错，线上很难发现。
    @Test func hmacSha256LongKey() {
        #expect(
            hex(MeterHMAC.sha256(
                key: Data(repeating: 0xaa, count: 131),
                message: Data("Test Using Larger Than Block-Size Key - Hash Key First".utf8)
            )) == "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54"
        )
    }

    /// SHA-384 的块长是 128 不是 64。这条向量正是用来钉住那个数字的。
    @Test func hmacSha384Case2() {
        #expect(
            hex(MeterHMAC.sha384(
                key: Data("Jefe".utf8),
                message: Data("what do ya want for nothing?".utf8)
            )) == "af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e"
                + "8e2240ca5e69e2c78b3239ecfab21649"
        )
    }

    @Test func hmacSha1Case2() {
        #expect(
            hex(MeterHMAC.sha1(
                key: Data("Jefe".utf8),
                message: Data("what do ya want for nothing?".utf8)
            )) == "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79"
        )
    }
}
