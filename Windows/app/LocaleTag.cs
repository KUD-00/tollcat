using Windows.Globalization;

namespace TollCat;

internal static class LocaleTag
{
    public static string Current
    {
        get
        {
            var tag = ApplicationLanguages.Languages.FirstOrDefault() ?? "zh-Hans";
            if (tag.StartsWith("en", StringComparison.OrdinalIgnoreCase)) return "en";
            if (tag.StartsWith("ja", StringComparison.OrdinalIgnoreCase)) return "ja";
            return "zh-Hans";
        }
    }
}
