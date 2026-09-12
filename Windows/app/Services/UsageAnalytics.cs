using System.Text.Json.Nodes;

namespace TollCat;

/// <summary>
/// 匿名页面计数。载荷在这边攒，HTTP 经 Swift 桥发出，平台字段 windows。
/// </summary>
internal static class UsageAnalytics
{
    private static readonly object Gate = new();
    private static readonly Dictionary<string, int> Counts = new();
    private static string? _lastScreen;
    private static CancellationTokenSource? _debounce;

    public static void Record(string screen)
    {
        if (!UsageScreens.All.Contains(screen)) return;
        lock (Gate)
        {
            if (_lastScreen == screen) return;
            _lastScreen = screen;
            Counts[screen] = Math.Min((Counts.TryGetValue(screen, out var n) ? n : 0) + 1, UsageFieldLimits.Count);
            _debounce?.Cancel();
            _debounce = new CancellationTokenSource();
            var token = _debounce.Token;
            _ = Task.Run(async () =>
            {
                try
                {
                    await Task.Delay(2000, token);
                    Flush();
                }
                catch (TaskCanceledException)
                {
                }
            }, token);
        }
    }

    public static void Flush()
    {
        JsonObject? payload;
        lock (Gate)
        {
            var day = DateTime.UtcNow.ToString("yyyy-MM-dd");
            var newVisit = Session.Current.Preferences.LastVisitDay != day;
            if (!newVisit && Counts.Count == 0) return;
            var screens = new JsonArray();
            foreach (var (id, n) in Counts.Take(UsageFieldLimits.Screens))
            {
                screens.Add(new JsonObject { ["id"] = id, ["n"] = n });
            }
            Counts.Clear();
            payload = new JsonObject
            {
                ["platform"] = "windows",
                ["appVersion"] = AppVersion.Caption,
                ["newVisit"] = newVisit,
                ["screens"] = screens,
            };
            if (newVisit) Session.Current.Preferences.LastVisitDay = day;
        }
        try
        {
            MeterCoreNative.PostUsageJson(payload.ToJsonString());
        }
        catch
        {
            // 失败丢掉这一批，宁可少计。
        }
    }
}

internal static class AppVersion
{
    public static string Caption
    {
        get
        {
            try
            {
                var v = Windows.ApplicationModel.Package.Current.Id.Version;
                return $"{v.Major}.{v.Minor}.{v.Build}";
            }
            catch
            {
                return "1.0.0";
            }
        }
    }
}
