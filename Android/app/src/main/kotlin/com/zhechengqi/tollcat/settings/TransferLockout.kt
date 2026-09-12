package com.zhechengqi.tollcat.settings

import kotlin.math.ceil
import kotlin.math.max

/**
 * 只挡这台设备上的乱试。挡不住已经拿到文件的人离线穷举。
 * 对齐 iOS `MeterPersistence.TransferLockout`。
 */
data class TransferLockout(
    val failureCount: Int = 0,
    val lockedUntilMillis: Long? = null,
) {
    val remainingFreeAttempts: Int
        get() = max(0, FREE_ATTEMPT_LIMIT - failureCount)

    fun registerFailure(nowMillis: Long): TransferLockout {
        val nextCount = failureCount + 1
        val delayMs = delayAfterFailureCount(nextCount)
        return copy(
            failureCount = nextCount,
            lockedUntilMillis = if (delayMs > 0) nowMillis + delayMs else lockedUntilMillis,
        )
    }

    fun registerSuccess(): TransferLockout = TransferLockout()

    fun isLocked(nowMillis: Long): Boolean {
        val until = lockedUntilMillis ?: return false
        return nowMillis < until
    }

    fun remainingSeconds(nowMillis: Long): Int {
        val until = lockedUntilMillis ?: return 0
        return max(0, ceil((until - nowMillis) / 1000.0).toInt())
    }

    companion object {
        const val FREE_ATTEMPT_LIMIT = 5

        /** 第 5 次起才锁，之后时间递增。这不是密码学保护。 */
        fun delayAfterFailureCount(count: Int): Long {
            val seconds = when {
                count <= 4 -> 0L
                count == 5 -> 15L
                count == 6 -> 30L
                count == 7 -> 60L
                count == 8 -> 120L
                count == 9 -> 300L
                else -> 900L
            }
            return seconds * 1000L
        }
    }
}
