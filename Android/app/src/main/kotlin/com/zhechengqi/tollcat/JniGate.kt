package com.zhechengqi.tollcat

import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference

/**
 * Swift runtime 和账单 JSON 都走这一条后台线程。
 * 主线程上 load .so / fetch 会把只有 1 核的模拟器 System UI 一起卡死。
 */
object JniGate {
    private val main = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "tollcat-jni").apply { isDaemon = true }
    }

    fun run(block: () -> Unit) {
        executor.execute {
            try {
                block()
            } catch (error: Throwable) {
                android.util.Log.e("TollCat", "jni", error)
            }
        }
    }

    fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            main.post(block)
        }
    }

    /** 把 JNI 调用排进同一条线程。反馈 / 匿名计数也走这里，避免和账单 JSON 抢 Swift runtime。 */
    fun <T> blocking(block: () -> T): T {
        if (Thread.currentThread().name == "tollcat-jni") return block()
        val latch = CountDownLatch(1)
        val holder = AtomicReference<Result<T>>()
        run {
            holder.set(runCatching(block))
            latch.countDown()
        }
        latch.await()
        return holder.get().getOrThrow()
    }
}
