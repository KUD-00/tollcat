using Windows.Foundation.Collections;
using Windows.Storage;

namespace TollCat;

internal sealed class PreferencesStore
{
    private readonly IPropertySet _values;

    public PreferencesStore()
    {
        _values = ApplicationData.Current.LocalSettings.Values;
    }

    public string DisplayCurrency
    {
        get => Get("currency", "USD");
        set => _values["currency"] = value;
    }

    public string Appearance
    {
        get => Get("appearance", "dark");
        set => _values["appearance"] = value;
    }

    public bool RefreshOnActivate
    {
        get => GetBool("refreshOnActivate", false);
        set => _values["refreshOnActivate"] = value;
    }

    public bool HidesCat
    {
        get => GetBool("hidesCat", true);
        set => _values["hidesCat"] = value;
    }

    public bool OnboardingDone
    {
        get => GetBool("onboardingDone", false);
        set => _values["onboardingDone"] = value;
    }

    public string LastVisitDay
    {
        get => Get("lastVisitDay", "");
        set => _values["lastVisitDay"] = value;
    }

    public void Clear()
    {
        _values.Clear();
    }

    private string Get(string key, string fallback) =>
        _values[key] as string ?? fallback;

    private bool GetBool(string key, bool fallback) =>
        _values[key] is bool value ? value : fallback;
}
