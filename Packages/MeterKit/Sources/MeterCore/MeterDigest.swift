import Foundation

/// MD5 / SHA-1 / SHA-256 / SHA-384，纯 Swift。
///
/// **为什么不是 CryptoKit。** 十五家厂商的签名要摘要（AWS SigV4 系、腾讯 TC3、
/// 阿里 RPC、Akamai EdgeGrid…），而 `MeterProviders` 必须能为 Android 交叉编译——
/// `import CryptoKit` 在 Android SDK 上直接「no such module」，`.so` 编不出来，
/// 整个 Android 端跟着不存在。换 swift-crypto 会破「无第三方依赖」那条。
///
/// **这不是自己发明密码学。** 四个都是公开定死的摘要函数（RFC 1321 / RFC 3174 /
/// FIPS 180-4），没有密钥协商、没有随机数、没有填充选择——照着规范抄，
/// 用官方测试向量钉住（`MeterDigestTests`）。真正需要密钥学判断的地方
/// （迁移包的 AES-GCM + PBKDF2）仍然走各平台的系统实现，不在这里。
///
/// MD5 和 SHA-1 只为对上厂商的旧签名协议，**不要拿它们做新东西**。
public enum MeterDigest: Sendable {
    public static func md5(_ data: Data) -> Data {
        var a: UInt32 = 0x6745_2301
        var b: UInt32 = 0xefcd_ab89
        var c: UInt32 = 0x98ba_dcfe
        var d: UInt32 = 0x1032_5476
        for block in padded(data, bigEndianLength: false) {
            var words = [UInt32](repeating: 0, count: 16)
            for i in 0..<16 {
                words[i] = UInt32(littleEndianAt: block, offset: i * 4)
            }
            var (aa, bb, cc, dd) = (a, b, c, d)
            for i in 0..<64 {
                var f: UInt32
                var g: Int
                switch i {
                case 0..<16:
                    f = (bb & cc) | (~bb & dd)
                    g = i
                case 16..<32:
                    f = (dd & bb) | (~dd & cc)
                    g = (5 * i + 1) % 16
                case 32..<48:
                    f = bb ^ cc ^ dd
                    g = (3 * i + 5) % 16
                default:
                    f = cc ^ (bb | ~dd)
                    g = (7 * i) % 16
                }
                f = f &+ aa &+ md5K[i] &+ words[g]
                aa = dd
                dd = cc
                cc = bb
                bb = bb &+ rotateLeft(f, md5Shift[i])
            }
            a = a &+ aa
            b = b &+ bb
            c = c &+ cc
            d = d &+ dd
        }
        var out = Data()
        for word in [a, b, c, d] {
            out.append(contentsOf: [
                UInt8(truncatingIfNeeded: word),
                UInt8(truncatingIfNeeded: word >> 8),
                UInt8(truncatingIfNeeded: word >> 16),
                UInt8(truncatingIfNeeded: word >> 24),
            ])
        }
        return out
    }

    public static func sha1(_ data: Data) -> Data {
        var h: [UInt32] = [0x6745_2301, 0xefcd_ab89, 0x98ba_dcfe, 0x1032_5476, 0xc3d2_e1f0]
        for block in padded(data, bigEndianLength: true) {
            var w = [UInt32](repeating: 0, count: 80)
            for i in 0..<16 {
                w[i] = UInt32(bigEndianAt: block, offset: i * 4)
            }
            for i in 16..<80 {
                w[i] = rotateLeft(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1)
            }
            var (a, b, c, d, e) = (h[0], h[1], h[2], h[3], h[4])
            for i in 0..<80 {
                let f: UInt32
                let k: UInt32
                switch i {
                case 0..<20:
                    f = (b & c) | (~b & d)
                    k = 0x5a82_7999
                case 20..<40:
                    f = b ^ c ^ d
                    k = 0x6ed9_eba1
                case 40..<60:
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8f1b_bcdc
                default:
                    f = b ^ c ^ d
                    k = 0xca62_c1d6
                }
                let temp = rotateLeft(a, 5) &+ f &+ e &+ k &+ w[i]
                e = d
                d = c
                c = rotateLeft(b, 30)
                b = a
                a = temp
            }
            h[0] = h[0] &+ a
            h[1] = h[1] &+ b
            h[2] = h[2] &+ c
            h[3] = h[3] &+ d
            h[4] = h[4] &+ e
        }
        return bigEndianBytes(h)
    }

    public static func sha256(_ data: Data) -> Data {
        var h: [UInt32] = [
            0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
            0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
        ]
        for block in padded(data, bigEndianLength: true) {
            var w = [UInt32](repeating: 0, count: 64)
            for i in 0..<16 {
                w[i] = UInt32(bigEndianAt: block, offset: i * 4)
            }
            for i in 16..<64 {
                let s0 = rotateRight(w[i - 15], 7) ^ rotateRight(w[i - 15], 18) ^ (w[i - 15] >> 3)
                let s1 = rotateRight(w[i - 2], 17) ^ rotateRight(w[i - 2], 19) ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }
            var (a, b, c, d, e, f, g, hh) = (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7])
            for i in 0..<64 {
                let s1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25)
                let ch = (e & f) ^ (~e & g)
                let temp1 = hh &+ s1 &+ ch &+ sha256K[i] &+ w[i]
                let s0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj
                hh = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }
            for (index, value) in [a, b, c, d, e, f, g, hh].enumerated() {
                h[index] = h[index] &+ value
            }
        }
        return bigEndianBytes(h)
    }

    /// SHA-384：SHA-512 换一组初值，取前 48 字节。
    public static func sha384(_ data: Data) -> Data {
        sha512Core(
            data,
            initial: [
                0xcbbb_9d5d_c105_9ed8, 0x629a_292a_367c_d507,
                0x9159_015a_3070_dd17, 0x152f_ecd8_f70e_5939,
                0x6733_2667_ffc0_0b31, 0x8eb4_4a87_6858_1511,
                0xdb0c_2e0d_64f9_8fa7, 0x47b5_481d_befa_4fa4,
            ],
            outputBytes: 48
        )
    }

    public static func sha512(_ data: Data) -> Data {
        sha512Core(
            data,
            initial: [
                0x6a09_e667_f3bc_c908, 0xbb67_ae85_84ca_a73b,
                0x3c6e_f372_fe94_f82b, 0xa54f_f53a_5f1d_36f1,
                0x510e_527f_ade6_82d1, 0x9b05_688c_2b3e_6c1f,
                0x1f83_d9ab_fb41_bd6b, 0x5be0_cd19_137e_2179,
            ],
            outputBytes: 64
        )
    }

    // MARK: - SHA-512 家族

    private static func sha512Core(_ data: Data, initial: [UInt64], outputBytes: Int) -> Data {
        var h = initial
        for block in padded512(data) {
            var w = [UInt64](repeating: 0, count: 80)
            for i in 0..<16 {
                w[i] = UInt64(bigEndianAt: block, offset: i * 8)
            }
            for i in 16..<80 {
                let s0 = rotateRight(w[i - 15], 1) ^ rotateRight(w[i - 15], 8) ^ (w[i - 15] >> 7)
                let s1 = rotateRight(w[i - 2], 19) ^ rotateRight(w[i - 2], 61) ^ (w[i - 2] >> 6)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }
            var (a, b, c, d, e, f, g, hh) = (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7])
            for i in 0..<80 {
                let s1 = rotateRight(e, 14) ^ rotateRight(e, 18) ^ rotateRight(e, 41)
                let ch = (e & f) ^ (~e & g)
                let temp1 = hh &+ s1 &+ ch &+ sha512K[i] &+ w[i]
                let s0 = rotateRight(a, 28) ^ rotateRight(a, 34) ^ rotateRight(a, 39)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj
                hh = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }
            for (index, value) in [a, b, c, d, e, f, g, hh].enumerated() {
                h[index] = h[index] &+ value
            }
        }
        var out = Data()
        for word in h {
            for shift in stride(from: 56, through: 0, by: -8) {
                out.append(UInt8(truncatingIfNeeded: word >> UInt64(shift)))
            }
        }
        return out.prefix(outputBytes)
    }

    // MARK: - 填充

    /// 64 字节一块。长度用 8 字节写在末尾，大端（SHA 系）或小端（MD5）。
    private static func padded(_ data: Data, bigEndianLength: Bool) -> [[UInt8]] {
        var bytes = [UInt8](data)
        let bitLength = UInt64(bytes.count) &* 8
        bytes.append(0x80)
        while bytes.count % 64 != 56 {
            bytes.append(0)
        }
        if bigEndianLength {
            for shift in stride(from: 56, through: 0, by: -8) {
                bytes.append(UInt8(truncatingIfNeeded: bitLength >> UInt64(shift)))
            }
        } else {
            for shift in stride(from: 0, through: 56, by: 8) {
                bytes.append(UInt8(truncatingIfNeeded: bitLength >> UInt64(shift)))
            }
        }
        return stride(from: 0, to: bytes.count, by: 64).map { Array(bytes[$0 ..< $0 + 64]) }
    }

    /// 128 字节一块，长度 16 字节大端（高 8 字节恒为 0：这里不会有 2^64 位的输入）。
    private static func padded512(_ data: Data) -> [[UInt8]] {
        var bytes = [UInt8](data)
        let bitLength = UInt64(bytes.count) &* 8
        bytes.append(0x80)
        while bytes.count % 128 != 112 {
            bytes.append(0)
        }
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 8))
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8(truncatingIfNeeded: bitLength >> UInt64(shift)))
        }
        return stride(from: 0, to: bytes.count, by: 128).map { Array(bytes[$0 ..< $0 + 128]) }
    }

    private static func bigEndianBytes(_ words: [UInt32]) -> Data {
        var out = Data()
        for word in words {
            out.append(contentsOf: [
                UInt8(truncatingIfNeeded: word >> 24),
                UInt8(truncatingIfNeeded: word >> 16),
                UInt8(truncatingIfNeeded: word >> 8),
                UInt8(truncatingIfNeeded: word),
            ])
        }
        return out
    }

    private static func rotateLeft(_ value: UInt32, _ amount: UInt32) -> UInt32 {
        (value << amount) | (value >> (32 - amount))
    }

    private static func rotateRight(_ value: UInt32, _ amount: UInt32) -> UInt32 {
        (value >> amount) | (value << (32 - amount))
    }

    private static func rotateRight(_ value: UInt64, _ amount: UInt64) -> UInt64 {
        (value >> amount) | (value << (64 - amount))
    }
}

private extension UInt32 {
    init(bigEndianAt bytes: [UInt8], offset: Int) {
        self = (UInt32(bytes[offset]) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
    }

    init(littleEndianAt bytes: [UInt8], offset: Int) {
        self = UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }
}

private extension UInt64 {
    init(bigEndianAt bytes: [UInt8], offset: Int) {
        var value: UInt64 = 0
        for i in 0..<8 {
            value = (value << 8) | UInt64(bytes[offset + i])
        }
        self = value
    }
}

private let md5Shift: [UInt32] = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
]

private let md5K: [UInt32] = [
    0xd76a_a478, 0xe8c7_b756, 0x2420_70db, 0xc1bd_ceee,
    0xf57c_0faf, 0x4787_c62a, 0xa830_4613, 0xfd46_9501,
    0x6980_98d8, 0x8b44_f7af, 0xffff_5bb1, 0x895c_d7be,
    0x6b90_1122, 0xfd98_7193, 0xa679_438e, 0x49b4_0821,
    0xf61e_2562, 0xc040_b340, 0x265e_5a51, 0xe9b6_c7aa,
    0xd62f_105d, 0x0244_1453, 0xd8a1_e681, 0xe7d3_fbc8,
    0x21e1_cde6, 0xc337_07d6, 0xf4d5_0d87, 0x455a_14ed,
    0xa9e3_e905, 0xfcef_a3f8, 0x676f_02d9, 0x8d2a_4c8a,
    0xfffa_3942, 0x8771_f681, 0x6d9d_6122, 0xfde5_380c,
    0xa4be_ea44, 0x4bde_cfa9, 0xf6bb_4b60, 0xbebf_bc70,
    0x289b_7ec6, 0xeaa1_27fa, 0xd4ef_3085, 0x0488_1d05,
    0xd9d4_d039, 0xe6db_99e5, 0x1fa2_7cf8, 0xc4ac_5665,
    0xf429_2244, 0x432a_ff97, 0xab94_23a7, 0xfc93_a039,
    0x655b_59c3, 0x8f0c_cc92, 0xffef_f47d, 0x8584_5dd1,
    0x6fa8_7e4f, 0xfe2c_e6e0, 0xa301_4314, 0x4e08_11a1,
    0xf753_7e82, 0xbd3a_f235, 0x2ad7_d2bb, 0xeb86_d391,
]

private let sha256K: [UInt32] = [
    0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5,
    0x3956_c25b, 0x59f1_11f1, 0x923f_82a4, 0xab1c_5ed5,
    0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3,
    0x72be_5d74, 0x80de_b1fe, 0x9bdc_06a7, 0xc19b_f174,
    0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc,
    0x2de9_2c6f, 0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da,
    0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7,
    0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967,
    0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc, 0x5338_0d13,
    0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85,
    0xa2bf_e8a1, 0xa81a_664b, 0xc24b_8b70, 0xc76c_51a3,
    0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070,
    0x19a4_c116, 0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5,
    0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
    0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208,
    0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7, 0xc671_78f2,
]

private let sha512K: [UInt64] = [
    0x428a_2f98_d728_ae22, 0x7137_4491_23ef_65cd, 0xb5c0_fbcf_ec4d_3b2f, 0xe9b5_dba5_8189_dbbc,
    0x3956_c25b_f348_b538, 0x59f1_11f1_b605_d019, 0x923f_82a4_af19_4f9b, 0xab1c_5ed5_da6d_8118,
    0xd807_aa98_a303_0242, 0x1283_5b01_4570_6fbe, 0x2431_85be_4ee4_b28c, 0x550c_7dc3_d5ff_b4e2,
    0x72be_5d74_f27b_896f, 0x80de_b1fe_3b16_96b1, 0x9bdc_06a7_25c7_1235, 0xc19b_f174_cf69_2694,
    0xe49b_69c1_9ef1_4ad2, 0xefbe_4786_384f_25e3, 0x0fc1_9dc6_8b8c_d5b5, 0x240c_a1cc_77ac_9c65,
    0x2de9_2c6f_592b_0275, 0x4a74_84aa_6ea6_e483, 0x5cb0_a9dc_bd41_fbd4, 0x76f9_88da_8311_53b5,
    0x983e_5152_ee66_dfab, 0xa831_c66d_2db4_3210, 0xb003_27c8_98fb_213f, 0xbf59_7fc7_beef_0ee4,
    0xc6e0_0bf3_3da8_8fc2, 0xd5a7_9147_930a_a725, 0x06ca_6351_e003_826f, 0x1429_2967_0a0e_6e70,
    0x27b7_0a85_46d2_2ffc, 0x2e1b_2138_5c26_c926, 0x4d2c_6dfc_5ac4_2aed, 0x5338_0d13_9d95_b3df,
    0x650a_7354_8baf_63de, 0x766a_0abb_3c77_b2a8, 0x81c2_c92e_47ed_aee6, 0x9272_2c85_1482_353b,
    0xa2bf_e8a1_4cf1_0364, 0xa81a_664b_bc42_3001, 0xc24b_8b70_d0f8_9791, 0xc76c_51a3_0654_be30,
    0xd192_e819_d6ef_5218, 0xd699_0624_5565_a910, 0xf40e_3585_5771_202a, 0x106a_a070_32bb_d1b8,
    0x19a4_c116_b8d2_d0c8, 0x1e37_6c08_5141_ab53, 0x2748_774c_df8e_eb99, 0x34b0_bcb5_e19b_48a8,
    0x391c_0cb3_c5c9_5a63, 0x4ed8_aa4a_e341_8acb, 0x5b9c_ca4f_7763_e373, 0x682e_6ff3_d6b2_b8a3,
    0x748f_82ee_5def_b2fc, 0x78a5_636f_4317_2f60, 0x84c8_7814_a1f0_ab72, 0x8cc7_0208_1a64_39ec,
    0x90be_fffa_2363_1e28, 0xa450_6ceb_de82_bde9, 0xbef9_a3f7_b2c6_7915, 0xc671_78f2_e372_532b,
    0xca27_3ece_ea26_619c, 0xd186_b8c7_21c0_c207, 0xeada_7dd6_cde0_eb1e, 0xf57d_4f7f_ee6e_d178,
    0x06f0_67aa_7217_6fba, 0x0a63_7dc5_a2c8_98a6, 0x113f_9804_bef9_0dae, 0x1b71_0b35_131c_471b,
    0x28db_77f5_2304_7d84, 0x32ca_ab7b_40c7_2493, 0x3c9e_be0a_15c9_bebc, 0x431d_67c4_9c10_0d4c,
    0x4cc5_d4be_cb3e_42b6, 0x597f_299c_fc65_7e2a, 0x5fcb_6fab_3ad6_faec, 0x6c44_198c_4a47_5817,
]
