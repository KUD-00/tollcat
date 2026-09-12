using Microsoft.UI.Xaml;

namespace TollCat;

/// 设置「外观」三档落到 WinUI 的 RequestedTheme。默认暗色。
internal static class AppearanceTheme
{
    public static ElementTheme Of(string appearance) => appearance switch
    {
        "light" => ElementTheme.Light,
        "dark" => ElementTheme.Dark,
        _ => ElementTheme.Default,
    };

    public static void ApplyTo(FrameworkElement? root)
    {
        if (root is null) return;
        root.RequestedTheme = Of(Session.Current.Preferences.Appearance);
    }
}
