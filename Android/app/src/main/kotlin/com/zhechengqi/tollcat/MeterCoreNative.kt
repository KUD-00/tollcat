package com.zhechengqi.tollcat

import android.content.Context
import java.io.File

/**
 * JNI 入口。库加载顺序按 DT_NEEDED 来：ART 不会按 LD_LIBRARY_PATH 解析 Swift runtime。
 */
object MeterCoreNative {
    @Volatile
    var loaded = false
        private set

    fun load(context: Context) {
        if (loaded) return
        synchronized(this) {
            if (loaded) return
            val dir = File(context.applicationInfo.nativeLibraryDir)
            val ordered = arrayOf(
                "libz.so",
                "libc++_shared.so",
                "libswiftCore.so",
                "libswiftSwiftOnoneSupport.so",
                "libswiftSynchronization.so",
                "libswift_Concurrency.so",
                "libswift_RegexParser.so",
                "libswift_StringProcessing.so",
                "libswiftRegexBuilder.so",
                "libswift_Builtin_float.so",
                "libswift_math.so",
                "libswift_Volatile.so",
                "libswift_Differentiation.so",
                "libBlocksRuntime.so",
                "libdispatch.so",
                "libswiftDispatch.so",
                "libswiftAndroid.so",
                "libswiftDistributed.so",
                "libswiftObservation.so",
                "libFoundationEssentials.so",
                "lib_FoundationICU.so",
                "libFoundationInternationalization.so",
                "libFoundation.so",
                "libFoundationNetworking.so",
                JNI_LIB,
            )
            for (name in ordered) {
                val file = File(dir, name)
                if (file.exists()) {
                    System.load(file.absolutePath)
                }
            }
            loaded = true
        }
    }

    @JvmStatic
    external fun setResourceRoot(path: String)

    @JvmStatic
    external fun formattedDesignSeed(): String

    @JvmStatic
    external fun designSeedMatches(): Boolean

    @JvmStatic
    external fun fixtureProofJson(): String

    @JvmStatic
    external fun stubFetchCloudflareJson(): String

    @JvmStatic
    external fun catalogJson(localeTag: String): String

    /** 向导整篇教程 + 行内深链解析表。目录里没有这家时返回 {"missing":true}。 */
    @JvmStatic
    external fun setupGuideJson(providerId: String, localeTag: String): String

    /** USD 十进制字符串 → 显示币种字符串。币种符号、位数、locale 都在 Swift 侧。 */
    @JvmStatic
    external fun formatUsd(raw: String, currency: String, localeTag: String): String

    /** 月日档日期（zh「8月20日」/ en "August 20"）。 */
    @JvmStatic
    external fun formatMonthAndDay(millis: Long, localeTag: String): String

    @JvmStatic
    external fun computeDashboardJson(
        snapshotsJson: String,
        subscriptionsJson: String,
        nowMillis: Long,
        currency: String,
        localeTag: String,
        filterJson: String,
    ): String

    /** 详情页历史图视图状态（点/窗口/桶序列/推断段/轴刻度值）。Kotlin 只渲染。 */
    @JvmStatic
    external fun historyChartJson(
        providerId: String,
        snapshotsJson: String,
        range: String,
        nowMillis: Long,
        offset: Int,
        spanLookback: Boolean,
    ): String

    @JvmStatic
    external fun spendBreakdownJson(
        linesJson: String,
        grouping: String,
        currency: String,
        localeTag: String,
    ): String

    @JvmStatic
    external fun postTipJson(payloadJson: String): String

    @JvmStatic
    external fun transferCodeGenerate(): String

    /** 用户敲的转移码规范化。不合法回空串。字母表只在 `MeterCore/TransferCode` 一份。 */
    @JvmStatic
    external fun transferCodeNormalize(input: String): String

    @JvmStatic
    external fun postUsageJson(payloadJson: String): String

    @JvmStatic
    external fun postFeedbackJson(payloadJson: String): String

    @JvmStatic
    external fun inboxCreateJson(): String

    @JvmStatic
    external fun inboxDeleteJson(readKey: String): String

    @JvmStatic
    external fun inboxReadingsJson(readKey: String): String

    @JvmStatic
    external fun inboxListKeysJson(readKey: String): String

    @JvmStatic
    external fun inboxMintKeyJson(readKey: String, label: String): String

    @JvmStatic
    external fun inboxRevokeKeyJson(readKey: String, keyID: String): String

    @JvmStatic
    external fun designSeedJson(nowMillis: Long): String

    @JvmStatic
    external fun fetchProviderJson(
        providerId: String,
        fieldsJson: String,
        nowMillis: Long,
    ): String

    private const val JNI_LIB = "libMeterCoreJNI.so"
}
