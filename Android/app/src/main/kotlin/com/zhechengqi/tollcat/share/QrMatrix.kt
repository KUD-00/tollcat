package com.zhechengqi.tollcat.share

/**
 * 字节模式 QR。不引第三方库。分享卡只编 `https://tollcat.app` 这种短 URL，
 * version 2–3 足够；纠错跟 iOS 一样优先走 H，转发、压缩、截图还能扫。
 *
 * `modules[y][x] == true` 是黑块。矩阵已含 4 格 quiet zone。
 */
class QrMatrix private constructor(val modules: Array<BooleanArray>) {
    val size: Int get() = modules.size

    fun dark(x: Int, y: Int): Boolean = modules[y][x]

    companion object {
        const val QUIET_ZONE = 4
        const val SHARE_URL = "https://tollcat.app"

        fun encode(payload: String = SHARE_URL): QrMatrix {
            val bytes = payload.toByteArray(Charsets.UTF_8)
            val (version, level) = pickVersion(bytes.size)
            val encoded = encodeBytes(bytes, version, level)
            val size = version.size
            val function = Array(size) { BooleanArray(size) }
            val data = Array(size) { BooleanArray(size) }
            placeFunction(data, function, version)
            placeData(data, function, encoded, size)
            val masked = chooseMask(data, function, version, level)
            return QrMatrix(withQuietZone(masked))
        }

        private fun pickVersion(byteCount: Int): Pair<Version, EcLevel> {
            val needed = byteModeLength(byteCount)
            for (version in Version.entries) {
                if (needed <= version.dataCodewords(EcLevel.H)) return version to EcLevel.H
            }
            for (version in Version.entries) {
                for (level in arrayOf(EcLevel.Q, EcLevel.M, EcLevel.L)) {
                    if (needed <= version.dataCodewords(level)) return version to level
                }
            }
            error("payload too long for QR version 1–3")
        }

        /** mode(4) + count(8) + data，再补齐到整字节（terminator 能塞进末字节就不另占）。 */
        private fun byteModeLength(byteCount: Int): Int = (4 + 8 + byteCount * 8 + 7) / 8
    }
}

private enum class EcLevel(val bits: Int) {
    L(1),
    M(0),
    Q(3),
    H(2),
}

private enum class Version(
    val number: Int,
    val remainderBits: Int,
    val alignment: Int,
    private val blocks: Map<EcLevel, BlockPlan>,
) {
    V1(
        1, 0, 0,
        mapOf(
            EcLevel.L to BlockPlan(7, 1, 19),
            EcLevel.M to BlockPlan(10, 1, 16),
            EcLevel.Q to BlockPlan(13, 1, 13),
            EcLevel.H to BlockPlan(17, 1, 9),
        ),
    ),
    V2(
        2, 7, 18,
        mapOf(
            EcLevel.L to BlockPlan(10, 1, 34),
            EcLevel.M to BlockPlan(16, 1, 28),
            EcLevel.Q to BlockPlan(22, 1, 22),
            EcLevel.H to BlockPlan(28, 1, 16),
        ),
    ),
    V3(
        3, 7, 22,
        mapOf(
            EcLevel.L to BlockPlan(15, 1, 55),
            EcLevel.M to BlockPlan(26, 1, 44),
            EcLevel.Q to BlockPlan(18, 2, 17),
            EcLevel.H to BlockPlan(22, 2, 13),
        ),
    ),
    ;

    val size: Int get() = 21 + 4 * (number - 1)

    fun plan(level: EcLevel): BlockPlan = blocks.getValue(level)

    fun dataCodewords(level: EcLevel): Int {
        val plan = plan(level)
        return plan.blockCount * plan.dataPerBlock
    }
}

private data class BlockPlan(
    val ecPerBlock: Int,
    val blockCount: Int,
    val dataPerBlock: Int,
)

private fun encodeBytes(data: ByteArray, version: Version, level: EcLevel): BooleanArray {
    val plan = version.plan(level)
    val dataCapacity = plan.blockCount * plan.dataPerBlock
    val bits = BitSink()
    bits.append(0b0100, 4)
    bits.append(data.size, 8)
    for (byte in data) bits.append(byte.toInt() and 0xFF, 8)
    val remaining = dataCapacity * 8 - bits.size
    bits.append(0, remaining.coerceAtMost(4))
    while (bits.size % 8 != 0) bits.append(0, 1)
    var padEc = true
    while (bits.size / 8 < dataCapacity) {
        bits.append(if (padEc) 0xEC else 0x11, 8)
        padEc = !padEc
    }
    val dataCodewords = bits.toBytes(dataCapacity)
    val blocks = Array(plan.blockCount) { index ->
        val start = index * plan.dataPerBlock
        val blockData = dataCodewords.copyOfRange(start, start + plan.dataPerBlock)
        blockData to rsRemainder(blockData, plan.ecPerBlock)
    }
    val interleaved = ArrayList<Int>(dataCapacity + plan.blockCount * plan.ecPerBlock)
    for (i in 0 until plan.dataPerBlock) {
        for (block in blocks) interleaved += block.first[i]
    }
    for (i in 0 until plan.ecPerBlock) {
        for (block in blocks) interleaved += block.second[i]
    }
    val out = BitSink()
    for (value in interleaved) out.append(value, 8)
    out.append(0, version.remainderBits)
    return out.toBits()
}

private class BitSink {
    private val bits = ArrayList<Boolean>()
    val size: Int get() = bits.size

    fun append(value: Int, width: Int) {
        for (i in width - 1 downTo 0) {
            bits += (value ushr i) and 1 == 1
        }
    }

    fun toBytes(count: Int): IntArray {
        val out = IntArray(count)
        for (i in 0 until count) {
            var v = 0
            for (b in 0 until 8) {
                val index = i * 8 + b
                if (index < bits.size && bits[index]) v = v or (1 shl (7 - b))
            }
            out[i] = v
        }
        return out
    }

    fun toBits(): BooleanArray = BooleanArray(bits.size) { bits[it] }
}

private val GF_EXP = IntArray(512)
private val GF_LOG = IntArray(256)
private var gfReady = false

private fun initGalois() {
    if (gfReady) return
    var x = 1
    for (i in 0 until 255) {
        GF_EXP[i] = x
        GF_LOG[x] = i
        x = x shl 1
        if (x and 0x100 != 0) x = x xor 0x11D
    }
    for (i in 255 until 512) GF_EXP[i] = GF_EXP[i - 255]
    gfReady = true
}

private fun gfMul(a: Int, b: Int): Int {
    initGalois()
    if (a == 0 || b == 0) return 0
    return GF_EXP[GF_LOG[a] + GF_LOG[b]]
}

/** Nayuki 的 divisor：不含最高位 1，长度 = ecCount。 */
private fun rsDivisor(ecCount: Int): IntArray {
    val result = IntArray(ecCount)
    result[ecCount - 1] = 1
    var root = 1
    repeat(ecCount) {
        for (j in result.indices) {
            result[j] = gfMul(result[j], root)
            if (j + 1 < result.size) result[j] = result[j] xor result[j + 1]
        }
        root = gfMul(root, 2)
    }
    return result
}

private fun rsRemainder(data: IntArray, ecCount: Int): IntArray {
    val divisor = rsDivisor(ecCount)
    val result = IntArray(ecCount)
    for (value in data) {
        val factor = value xor result[0]
        for (i in 0 until ecCount - 1) result[i] = result[i + 1]
        result[ecCount - 1] = 0
        if (factor == 0) continue
        for (i in result.indices) {
            result[i] = result[i] xor gfMul(divisor[i], factor)
        }
    }
    return result
}

private fun placeFunction(
    grid: Array<BooleanArray>,
    function: Array<BooleanArray>,
    version: Version,
) {
    val size = version.size
    fun mark(x: Int, y: Int, dark: Boolean) {
        if (x !in 0 until size || y !in 0 until size) return
        grid[y][x] = dark
        function[y][x] = true
    }
    fun finder(left: Int, top: Int) {
        for (dy in -1..7) {
            for (dx in -1..7) {
                val inside = dx in 0..6 && dy in 0..6
                val dark = inside &&
                    (dx == 0 || dx == 6 || dy == 0 || dy == 6 || (dx in 2..4 && dy in 2..4))
                if (inside || (dx in -1..7 && dy in -1..7)) {
                    mark(left + dx, top + dy, if (inside) dark else false)
                }
            }
        }
    }
    finder(0, 0)
    finder(size - 7, 0)
    finder(0, size - 7)
    if (version.alignment > 0) {
        val c = version.alignment
        for (dy in -2..2) {
            for (dx in -2..2) {
                val dark = dx == -2 || dx == 2 || dy == -2 || dy == 2 || (dx == 0 && dy == 0)
                mark(c + dx, c + dy, dark)
            }
        }
    }
    for (i in 8 until size - 8) {
        val dark = i % 2 == 0
        mark(i, 6, dark)
        mark(6, i, dark)
    }
    mark(8, 4 * version.number + 9, true)
    for (i in 0..8) {
        if (i != 6) {
            function[i][8] = true
            function[8][i] = true
        }
    }
    for (i in 0..7) {
        function[8][size - 1 - i] = true
        function[size - 1 - i][8] = true
    }
}

private fun placeData(
    grid: Array<BooleanArray>,
    function: Array<BooleanArray>,
    bits: BooleanArray,
    size: Int,
) {
    var index = 0
    var right = size - 1
    while (right >= 1) {
        if (right == 6) right = 5
        val upward = (right + 1) and 2 == 0
        for (vert in 0 until size) {
            for (j in 0 until 2) {
                val x = right - j
                val y = if (upward) size - 1 - vert else vert
                if (function[y][x]) continue
                if (index < bits.size) {
                    grid[y][x] = bits[index]
                    index++
                }
            }
        }
        right -= 2
    }
}

private fun maskAt(mask: Int, x: Int, y: Int): Boolean = when (mask) {
    0 -> (x + y) % 2 == 0
    1 -> y % 2 == 0
    2 -> x % 3 == 0
    3 -> (x + y) % 3 == 0
    4 -> (y / 2 + x / 3) % 2 == 0
    5 -> (x * y) % 2 + (x * y) % 3 == 0
    6 -> ((x * y) % 2 + (x * y) % 3) % 2 == 0
    else -> ((x + y) % 2 + (x * y) % 3) % 2 == 0
}

private fun chooseMask(
    data: Array<BooleanArray>,
    function: Array<BooleanArray>,
    version: Version,
    level: EcLevel,
): Array<BooleanArray> {
    val size = version.size
    var bestScore = Int.MAX_VALUE
    var bestGrid = data
    for (mask in 0..7) {
        val grid = Array(size) { y -> BooleanArray(size) { x -> data[y][x] } }
        for (y in 0 until size) {
            for (x in 0 until size) {
                if (!function[y][x] && maskAt(mask, x, y)) {
                    grid[y][x] = !grid[y][x]
                }
            }
        }
        placeFormat(grid, level.bits, mask, size)
        val score = penalty(grid)
        if (score < bestScore) {
            bestScore = score
            bestGrid = grid
        }
    }
    return bestGrid
}

private fun penalty(grid: Array<BooleanArray>): Int {
    val size = grid.size
    var score = 0
    fun runPenalty(run: Int) {
        if (run >= 5) score += 3 + (run - 5)
    }
    for (y in 0 until size) {
        var run = 1
        for (x in 1 until size) {
            if (grid[y][x] == grid[y][x - 1]) run++ else {
                runPenalty(run)
                run = 1
            }
        }
        runPenalty(run)
    }
    for (x in 0 until size) {
        var run = 1
        for (y in 1 until size) {
            if (grid[y][x] == grid[y - 1][x]) run++ else {
                runPenalty(run)
                run = 1
            }
        }
        runPenalty(run)
    }
    for (y in 0 until size - 1) {
        for (x in 0 until size - 1) {
            val v = grid[y][x]
            if (v == grid[y][x + 1] && v == grid[y + 1][x] && v == grid[y + 1][x + 1]) score += 3
        }
    }
    val finderZeros = booleanArrayOf(false, false, false, false)
    val finderCore = booleanArrayOf(true, false, true, true, true, false, true)
    fun finderLike(row: BooleanArray) {
        val n = row.size
        if (n < 11) return
        for (i in 0..n - 11) {
            var zerosLeft = true
            var core = true
            var zerosRight = true
            var coreAlt = true
            for (k in 0 until 4) {
                if (row[i + k] != finderZeros[k]) zerosLeft = false
                if (row[i + 7 + k] != finderZeros[k]) zerosRight = false
            }
            for (k in 0 until 7) {
                if (row[i + 4 + k] != finderCore[k]) core = false
                if (row[i + k] != finderCore[k]) coreAlt = false
            }
            if ((zerosLeft && core) || (coreAlt && zerosRight)) score += 40
        }
    }
    for (y in 0 until size) finderLike(grid[y])
    for (x in 0 until size) {
        finderLike(BooleanArray(size) { y -> grid[y][x] })
    }
    var dark = 0
    for (row in grid) for (cell in row) if (cell) dark++
    val percent = dark * 100 / (size * size)
    score += kotlin.math.abs(percent - 50) / 5 * 10
    return score
}

private fun formatBits(ecBits: Int, mask: Int): Int {
    val data = (ecBits shl 3) or mask
    var rem = data
    repeat(10) {
        rem = (rem shl 1) xor ((rem ushr 9) * 0x537)
    }
    return ((data shl 10) or (rem and 0x3FF)) xor 0x5412
}

private fun bitAt(bits: Int, index: Int): Boolean = (bits ushr index) and 1 == 1

/** setModule(x, y) 对齐 Nayuki：grid[y][x]。 */
private fun placeFormat(grid: Array<BooleanArray>, ecBits: Int, mask: Int, size: Int) {
    val bits = formatBits(ecBits, mask)
    for (i in 0..5) grid[i][8] = bitAt(bits, i)
    grid[7][8] = bitAt(bits, 6)
    grid[8][8] = bitAt(bits, 7)
    grid[8][7] = bitAt(bits, 8)
    for (i in 9 until 15) grid[8][14 - i] = bitAt(bits, i)
    for (i in 0 until 8) grid[8][size - 1 - i] = bitAt(bits, i)
    for (i in 8 until 15) grid[size - 15 + i][8] = bitAt(bits, i)
    grid[size - 8][8] = true
}

private fun withQuietZone(grid: Array<BooleanArray>): Array<BooleanArray> {
    val q = QrMatrix.QUIET_ZONE
    val n = grid.size
    val out = Array(n + q * 2) { BooleanArray(n + q * 2) }
    for (y in 0 until n) {
        for (x in 0 until n) {
            out[y + q][x + q] = grid[y][x]
        }
    }
    return out
}
