import Foundation
import MeterBridge
import MeterProviders

/// C ABI 皮。每个桥函数一个 `@_cdecl("tollcat_…")` 导出，UTF-8 `char*` 进出。
/// 返回字符串由 Swift 堆分配，C# 侧调 `tollcat_free` 释放。

@_cdecl("tollcat_set_resource_root")
public func tollcat_set_resource_root(_ path: UnsafePointer<CChar>?) {
    guard let path else {
        JNIResourceRoot.set(nil)
        return
    }
    let url = URL(fileURLWithPath: String(cString: path), isDirectory: true)
    JNIResourceRoot.set(url)
    ProviderResourceLocator.setOverrideDirectory(url)
}

@_cdecl("tollcat_catalog")
public func tollcat_catalog(_ localeTag: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    heapString(ProductCatalog.json(localeTag: csharpString(localeTag)))
}

@_cdecl("tollcat_setup_guide")
public func tollcat_setup_guide(
    _ providerID: UnsafePointer<CChar>?,
    _ localeTag: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    heapString(
        ProductCatalog.setupGuideJson(
            providerIDRaw: csharpString(providerID),
            localeTag: csharpString(localeTag)
        )
    )
}

@_cdecl("tollcat_format_usd")
public func tollcat_format_usd(
    _ raw: UnsafePointer<CChar>?,
    _ currency: UnsafePointer<CChar>?,
    _ localeTag: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    heapString(
        ProductFormat.usd(
            csharpString(raw),
            currency: csharpString(currency),
            localeTag: csharpString(localeTag)
        )
    )
}

@_cdecl("tollcat_format_month_and_day")
public func tollcat_format_month_and_day(
    _ millis: Int64,
    _ localeTag: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    heapString(ProductFormat.monthAndDay(millis: millis, localeTag: csharpString(localeTag)))
}

@_cdecl("tollcat_dashboard")
public func tollcat_dashboard(
    _ snapshotsJSON: UnsafePointer<CChar>?,
    _ subscriptionsJSON: UnsafePointer<CChar>?,
    _ nowMillis: Int64,
    _ currency: UnsafePointer<CChar>?,
    _ localeTag: UnsafePointer<CChar>?,
    _ filterJSON: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    heapString(
        ProductDashboard.json(
            snapshotsJSON: csharpString(snapshotsJSON),
            subscriptionsJSON: csharpString(subscriptionsJSON),
            nowMillis: nowMillis,
            currency: csharpString(currency),
            localeTag: csharpString(localeTag),
            filterJSON: csharpString(filterJSON)
        )
    )
}

@_cdecl("tollcat_history_chart")
public func tollcat_history_chart(
    _ providerID: UnsafePointer<CChar>?,
    _ snapshotsJSON: UnsafePointer<CChar>?,
    _ rangeRaw: UnsafePointer<CChar>?,
    _ nowMillis: Int64
) -> UnsafeMutablePointer<CChar>? {
    heapString(
        ProductHistoryChart.json(
            providerIDRaw: csharpString(providerID),
            snapshotsJSON: csharpString(snapshotsJSON),
            rangeRaw: csharpString(rangeRaw),
            nowMillis: nowMillis
        )
    )
}

@_cdecl("tollcat_design_seed")
public func tollcat_design_seed(_ nowMillis: Int64) -> UnsafeMutablePointer<CChar>? {
    heapString(ProductSeed.json(nowMillis: nowMillis))
}

@_cdecl("tollcat_fetch")
public func tollcat_fetch(
    _ providerID: UnsafePointer<CChar>?,
    _ fieldsJSON: UnsafePointer<CChar>?,
    _ nowMillis: Int64
) -> UnsafeMutablePointer<CChar>? {
    heapString(
        ProductFetch.json(
            providerIDRaw: csharpString(providerID),
            fieldsJSON: csharpString(fieldsJSON),
            nowMillis: nowMillis
        )
    )
}

@_cdecl("tollcat_post_usage")
public func tollcat_post_usage(_ payloadJSON: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    heapString(ProductWorker.usageJson(payloadJSON: csharpString(payloadJSON)))
}

@_cdecl("tollcat_post_feedback")
public func tollcat_post_feedback(_ payloadJSON: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    heapString(ProductWorker.feedbackJson(payloadJSON: csharpString(payloadJSON)))
}

@_cdecl("tollcat_free")
public func tollcat_free(_ ptr: UnsafeMutablePointer<CChar>?) {
    ptr?.deallocate()
}

private func csharpString(_ ptr: UnsafePointer<CChar>?) -> String {
    guard let ptr else { return "" }
    return String(cString: ptr)
}

/// 和 `tollcat_free` 成对：Swift 堆上分配，C# 用同一套释放。
/// 不用 `strdup`：Windows 上要另 import ucrt，和 Apple / Android 对不齐。
private func heapString(_ value: String) -> UnsafeMutablePointer<CChar>? {
    value.withCString { src in
        var count = 0
        while src[count] != 0 { count += 1 }
        count += 1
        let dst = UnsafeMutablePointer<CChar>.allocate(capacity: count)
        dst.initialize(from: src, count: count)
        return dst
    }
}
