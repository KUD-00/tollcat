using System.Runtime.InteropServices;

namespace TollCat;

/// <summary>
/// 和 Android <c>MeterCoreNative.kt</c> 同构：一个导出函数一个方法，
/// JSON 字符串进出，反序列化只在这一层之上。C# 侧零网络请求。
/// </summary>
internal static partial class MeterCoreNative
{
    private const string Lib = "MeterCoreCLR";

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial void tollcat_set_resource_root(string path);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_catalog(string localeTag);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_setup_guide(string providerId, string localeTag);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_format_usd(string raw, string currency, string localeTag);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_format_month_and_day(long millis, string localeTag);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_dashboard(
        string snapshotsJson,
        string subscriptionsJson,
        long nowMillis,
        string currency,
        string localeTag,
        string filterJson);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_history_chart(
        string providerId,
        string snapshotsJson,
        string range,
        long nowMillis);

    [LibraryImport(Lib)]
    private static partial nint tollcat_design_seed(long nowMillis);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_fetch(string providerId, string fieldsJson, long nowMillis);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_post_usage(string payloadJson);

    [LibraryImport(Lib, StringMarshalling = StringMarshalling.Utf8)]
    private static partial nint tollcat_post_feedback(string payloadJson);

    [LibraryImport(Lib)]
    private static partial void tollcat_free(nint ptr);

    public static void SetResourceRoot(string path) => tollcat_set_resource_root(path);

    public static string CatalogJson(string localeTag) => Take(tollcat_catalog(localeTag));

    public static string SetupGuideJson(string providerId, string localeTag) =>
        Take(tollcat_setup_guide(providerId, localeTag));

    public static string FormatUsd(string raw, string currency, string localeTag) =>
        Take(tollcat_format_usd(raw, currency, localeTag));

    public static string FormatMonthAndDay(long millis, string localeTag) =>
        Take(tollcat_format_month_and_day(millis, localeTag));

    public static string ComputeDashboardJson(
        string snapshotsJson,
        string subscriptionsJson,
        long nowMillis,
        string currency,
        string localeTag,
        string filterJson) =>
        Take(tollcat_dashboard(snapshotsJson, subscriptionsJson, nowMillis, currency, localeTag, filterJson));

    public static string HistoryChartJson(string providerId, string snapshotsJson, string range, long nowMillis) =>
        Take(tollcat_history_chart(providerId, snapshotsJson, range, nowMillis));

    public static string DesignSeedJson(long nowMillis) => Take(tollcat_design_seed(nowMillis));

    public static string FetchProviderJson(string providerId, string fieldsJson, long nowMillis) =>
        Take(tollcat_fetch(providerId, fieldsJson, nowMillis));

    public static string PostUsageJson(string payloadJson) => Take(tollcat_post_usage(payloadJson));

    public static string PostFeedbackJson(string payloadJson) => Take(tollcat_post_feedback(payloadJson));

    private static string Take(nint ptr)
    {
        if (ptr == nint.Zero) return "{}";
        try
        {
            return Marshal.PtrToStringUTF8(ptr) ?? "{}";
        }
        finally
        {
            tollcat_free(ptr);
        }
    }

}
