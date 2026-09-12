using Microsoft.Windows.ApplicationModel.Resources;

namespace TollCat;

/// <summary>zh-Hans 源串在 resw；en / ja 是生成物。运行时按系统语言取。</summary>
internal static class Copy
{
    private static readonly ResourceLoader Loader = new();

    public static string Get(string key)
    {
        try
        {
            var value = Loader.GetString(key);
            return string.IsNullOrEmpty(value) ? key : value;
        }
        catch (Exception)
        {
            return key;
        }
    }

    public static string Format(string key, params object[] args)
    {
        var pattern = Get(key);
        try
        {
            return string.Format(pattern, args);
        }
        catch (FormatException)
        {
            return pattern;
        }
    }
}
