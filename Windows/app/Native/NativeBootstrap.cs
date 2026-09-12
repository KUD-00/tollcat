using Windows.ApplicationModel;
using Windows.Storage;

namespace TollCat;

internal static class NativeBootstrap
{
    private static readonly object Gate = new();
    private static bool _ready;

    public static void Ensure()
    {
        if (_ready) return;
        lock (Gate)
        {
            if (_ready) return;
            var root = LocateSwiftPm();
            MeterCoreNative.SetResourceRoot(root);
            _ready = true;
        }
    }

    private static string LocateSwiftPm()
    {
        foreach (var candidate in Candidates())
        {
            if (File.Exists(Path.Combine(candidate, "catalog.json"))
                || File.Exists(Path.Combine(candidate, "aws.json")))
            {
                return candidate;
            }
        }
        return AppContext.BaseDirectory;
    }

    private static IEnumerable<string> Candidates()
    {
        // CS1626：迭代器里 yield 不能写在带 catch 的 try 内，
        // 所以先经 TryGetRoot 把"未打包时抛 InvalidOperationException"包掉。
        var baseDir = AppContext.BaseDirectory;
        yield return Path.Combine(baseDir, "Assets", "swiftpm");
        yield return Path.Combine(baseDir, "swiftpm");
        if (TryGetRoot(static () => Package.Current.InstalledLocation.Path) is { } installed)
        {
            yield return Path.Combine(installed, "Assets", "swiftpm");
        }
        if (TryGetRoot(static () => ApplicationData.Current.LocalFolder.Path) is { } local)
        {
            yield return Path.Combine(local, "swiftpm");
        }
    }

    private static string? TryGetRoot(Func<string> resolve)
    {
        try
        {
            return resolve();
        }
        catch (InvalidOperationException)
        {
            // unpackaged
            return null;
        }
    }
}
