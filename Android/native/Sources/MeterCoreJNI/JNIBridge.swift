#if os(Android)
import Android
import Foundation
import MeterBridge
import MeterCore
import MeterProviders

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_setResourceRoot")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_setResourceRoot(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    path: jstring
) {
    let root = URL(fileURLWithPath: JNISupport.string(env, path))
    ProviderResourceLocator.setOverrideDirectory(root)
    JNIResourceRoot.set(root)
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_formattedDesignSeed")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_formattedDesignSeed(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass
) -> jstring? {
    let formatted = (try? AndroidProof.compute())?.formattedTotal ?? "—"
    return JNISupport.newString(env, formatted)
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_designSeedMatches")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_designSeedMatches(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass
) -> jboolean {
    guard let result = try? AndroidProof.compute() else { return 0 }
    return AndroidProof.matches(result) ? 1 : 0
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_fixtureProofJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_fixtureProofJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass
) -> jstring? {
    JNISupport.newString(env, AndroidProof.fixtureProofJSON())
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_stubFetchCloudflareJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_stubFetchCloudflareJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass
) -> jstring? {
    JNISupport.newString(env, AndroidProof.stubFetchCloudflareJSON())
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_catalogJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_catalogJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    localeTag: jstring
) -> jstring? {
    JNISupport.newString(env, ProductCatalog.json(localeTag: JNISupport.string(env, localeTag)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_setupGuideJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_setupGuideJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    providerID: jstring,
    localeTag: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductCatalog.setupGuideJson(
            providerIDRaw: JNISupport.string(env, providerID),
            localeTag: JNISupport.string(env, localeTag)
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_formatUsd")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_formatUsd(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    raw: jstring,
    currency: jstring,
    localeTag: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductFormat.usd(
            JNISupport.string(env, raw),
            currency: JNISupport.string(env, currency),
            localeTag: JNISupport.string(env, localeTag)
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_formatMonthAndDay")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_formatMonthAndDay(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    millis: jlong,
    localeTag: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductFormat.monthAndDay(millis: millis, localeTag: JNISupport.string(env, localeTag))
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_computeDashboardJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_computeDashboardJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    snapshotsJSON: jstring,
    subscriptionsJSON: jstring,
    nowMillis: jlong,
    currency: jstring,
    localeTag: jstring,
    filterJSON: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductDashboard.json(
            snapshotsJSON: JNISupport.string(env, snapshotsJSON),
            subscriptionsJSON: JNISupport.string(env, subscriptionsJSON),
            nowMillis: nowMillis,
            currency: JNISupport.string(env, currency),
            localeTag: JNISupport.string(env, localeTag),
            filterJSON: JNISupport.string(env, filterJSON)
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_historyChartJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_historyChartJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    providerID: jstring,
    snapshotsJSON: jstring,
    rangeRaw: jstring,
    nowMillis: jlong,
    offset: jint,
    spanLookback: jboolean
) -> jstring? {
    JNISupport.newString(
        env,
        ProductHistoryChart.json(
            providerIDRaw: JNISupport.string(env, providerID),
            snapshotsJSON: JNISupport.string(env, snapshotsJSON),
            rangeRaw: JNISupport.string(env, rangeRaw),
            nowMillis: nowMillis,
            offset: Int(offset),
            spanLookback: spanLookback != 0
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_postUsageJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_postUsageJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    payload: jstring
) -> jstring? {
    JNISupport.newString(env, ProductWorker.usageJson(payloadJSON: JNISupport.string(env, payload)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_postFeedbackJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_postFeedbackJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    payload: jstring
) -> jstring? {
    JNISupport.newString(env, ProductWorker.feedbackJson(payloadJSON: JNISupport.string(env, payload)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_inboxCreateJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_inboxCreateJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass
) -> jstring? {
    JNISupport.newString(env, ProductInbox.createJson())
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_inboxDeleteJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_inboxDeleteJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    readKey: jstring
) -> jstring? {
    JNISupport.newString(env, ProductInbox.deleteJson(readKey: JNISupport.string(env, readKey)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_inboxReadingsJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_inboxReadingsJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    readKey: jstring
) -> jstring? {
    JNISupport.newString(env, ProductInbox.readingsJson(readKey: JNISupport.string(env, readKey)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_inboxListKeysJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_inboxListKeysJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    readKey: jstring
) -> jstring? {
    JNISupport.newString(env, ProductInbox.listKeysJson(readKey: JNISupport.string(env, readKey)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_inboxMintKeyJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_inboxMintKeyJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    readKey: jstring,
    label: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductInbox.mintKeyJson(
            readKey: JNISupport.string(env, readKey),
            label: JNISupport.string(env, label)
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_inboxRevokeKeyJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_inboxRevokeKeyJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    readKey: jstring,
    keyID: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductInbox.revokeKeyJson(
            readKey: JNISupport.string(env, readKey),
            keyID: JNISupport.string(env, keyID)
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_designSeedJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_designSeedJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    nowMillis: jlong
) -> jstring? {
    JNISupport.newString(env, ProductSeed.json(nowMillis: nowMillis))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_fetchProviderJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_fetchProviderJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    providerID: jstring,
    fieldsJSON: jstring,
    nowMillis: jlong
) -> jstring? {
    JNISupport.newString(
        env,
        ProductFetch.json(
            providerIDRaw: JNISupport.string(env, providerID),
            fieldsJSON: JNISupport.string(env, fieldsJSON),
            nowMillis: nowMillis
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_spendBreakdownJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_spendBreakdownJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    linesJSON: jstring,
    grouping: jstring,
    currency: jstring,
    localeTag: jstring
) -> jstring? {
    JNISupport.newString(
        env,
        ProductSpendBreakdown.json(
            linesJSON: JNISupport.string(env, linesJSON),
            groupingRaw: JNISupport.string(env, grouping),
            currency: JNISupport.string(env, currency),
            localeTag: JNISupport.string(env, localeTag)
        )
    )
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_postTipJson")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_postTipJson(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    payload: jstring
) -> jstring? {
    JNISupport.newString(env, ProductWorker.tipJson(payloadJSON: JNISupport.string(env, payload)))
}

@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_transferCodeGenerate")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_transferCodeGenerate(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass
) -> jstring? {
    JNISupport.newString(env, TransferCode.generate().rawValue)
}

/// 用户敲进来的转移码规范化。不合法回空串——字母表和「I/L→1、O→0」那套
/// 只有 `MeterCore/TransferCode` 一份，别在 Kotlin 里再写一遍。
@_cdecl("Java_com_zhechengqi_tollcat_MeterCoreNative_transferCodeNormalize")
public func Java_com_zhechengqi_tollcat_MeterCoreNative_transferCodeNormalize(
    env: UnsafeMutablePointer<JNIEnv?>,
    clazz: jclass,
    input: jstring
) -> jstring? {
    let raw = JNISupport.string(env, input)
    return JNISupport.newString(env, TransferCode(userInput: raw)?.rawValue ?? "")
}
#endif
