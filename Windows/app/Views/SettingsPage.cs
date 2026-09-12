using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace TollCat;

internal sealed class SettingsPage : Page
{
    public SettingsPage()
    {
        Loaded += (_, _) => Rebuild();
    }

    private void Rebuild()
    {
        var session = Session.Current;
        var root = new ScrollViewer { Padding = new Thickness(24) };
        var stack = new StackPanel { Spacing = 20, MaxWidth = 720 };
        root.Content = stack;

        stack.Children.Add(Header(Copy.Get("SettingsGeneral")));
        stack.Children.Add(CurrencyPicker(session));
        stack.Children.Add(AppearancePicker(session));

        var hideCat = new ToggleSwitch { Header = Copy.Get("SettingsHideCat"), IsOn = session.Preferences.HidesCat };
        hideCat.Toggled += (_, _) =>
        {
            session.Preferences.HidesCat = hideCat.IsOn;
            session.Recompute();
        };
        stack.Children.Add(hideCat);

        var refresh = new ToggleSwitch
        {
            Header = Copy.Get("SettingsRefreshTitle"),
            IsOn = session.Preferences.RefreshOnActivate,
        };
        refresh.Toggled += (_, _) => session.Preferences.RefreshOnActivate = refresh.IsOn;
        stack.Children.Add(refresh);
        stack.Children.Add(Note(Copy.Get("SettingsRefreshNote")));

        var startup = new ToggleSwitch { Header = Copy.Get("SettingsStartup") };
        _ = LoadStartup(startup);
        startup.Toggled += async (_, _) => await StartupTaskService.SetEnabledAsync(startup.IsOn);
        stack.Children.Add(startup);
        stack.Children.Add(Note(Copy.Get("SettingsStartupNote")));

        stack.Children.Add(Header(Copy.Get("SettingsGuide")));
        stack.Children.Add(Note(Copy.Get("KindUsageTitle") + " — " + Copy.Get("KindUsageBody")));
        stack.Children.Add(Note(Copy.Get("KindPrepaidTitle") + " — " + Copy.Get("KindPrepaidBody")));
        stack.Children.Add(Note(Copy.Get("KindSubscriptionTitle") + " — " + Copy.Get("KindSubscriptionBody")));
        stack.Children.Add(Note(Copy.Get("KindFreetierTitle") + " — " + Copy.Get("KindFreetierBody")));

        stack.Children.Add(Header(Copy.Get("SettingsFeedback")));
        stack.Children.Add(new FeedbackPanel());

        stack.Children.Add(Header(Copy.Get("SettingsAbout")));
        stack.Children.Add(Note(Copy.Get("SettingsAboutBody")));
        stack.Children.Add(Note(Copy.Format("SettingsVersion", AppVersion.Caption)));

        var clear = new Button { Content = Copy.Get("SettingsClear") };
        clear.Click += async (_, _) =>
        {
            var dialog = new ContentDialog
            {
                Title = Copy.Get("SettingsClearTitle"),
                Content = Copy.Get("SettingsClearBody"),
                PrimaryButtonText = Copy.Get("SettingsClearConfirm"),
                CloseButtonText = Copy.Get("ActionCancel"),
                XamlRoot = XamlRoot,
            };
            if (await dialog.ShowAsync() == ContentDialogResult.Primary)
            {
                session.ClearAll();
                Rebuild();
            }
        };
        stack.Children.Add(clear);
        Content = root;
    }

    private static async Task LoadStartup(ToggleSwitch toggle)
    {
        toggle.IsOn = await StartupTaskService.IsEnabledAsync();
    }

    private static UIElement CurrencyPicker(Session session)
    {
        var box = new ComboBox { Header = Copy.Get("SettingsCurrency") };
        foreach (var code in session.Catalog.Currencies)
        {
            box.Items.Add(code);
            if (code == session.DisplayCurrency) box.SelectedItem = code;
        }
        box.SelectionChanged += (_, _) =>
        {
            if (box.SelectedItem is string code) session.SetCurrency(code);
        };
        return box;
    }

    private static UIElement AppearancePicker(Session session)
    {
        var box = new ComboBox { Header = Copy.Get("SettingsAppearance") };
        var options = new (string key, string label)[]
        {
            ("system", Copy.Get("SettingsAppearanceSystem")),
            ("light", Copy.Get("SettingsAppearanceLight")),
            ("dark", Copy.Get("SettingsAppearanceDark")),
        };
        foreach (var (key, label) in options)
        {
            box.Items.Add(new ComboBoxItem { Content = label, Tag = key });
            if (key == session.Preferences.Appearance) box.SelectedItem = box.Items[^1];
        }
        box.SelectionChanged += (_, _) =>
        {
            if (box.SelectedItem is ComboBoxItem item && item.Tag is string key)
            {
                session.Preferences.Appearance = key;
            }
        };
        return box;
    }

    private static TextBlock Header(string text) => new()
    {
        Text = text,
        Style = (Style)Application.Current.Resources["SubtitleTextBlockStyle"],
    };

    private static TextBlock Note(string text) => new()
    {
        Text = text,
        TextWrapping = TextWrapping.Wrap,
        Opacity = 0.8,
    };
}

internal sealed class FeedbackPanel : StackPanel
{
    public FeedbackPanel()
    {
        Spacing = 8;
        var category = new ComboBox { Header = Copy.Get("SettingsFeedbackCategory") };
        foreach (var (id, label) in new[] { ("bug", "Bug"), ("idea", "Idea"), ("provider", "Provider"), ("other", "Other") })
        {
            category.Items.Add(new ComboBoxItem { Content = label, Tag = id });
        }
        category.SelectedIndex = 0;
        var message = new TextBox
        {
            Header = Copy.Get("SettingsFeedbackMessageLabel"),
            PlaceholderText = Copy.Get("SettingsFeedbackMessageHint"),
            AcceptsReturn = true,
            Height = 120,
        };
        var contact = new TextBox { Header = Copy.Get("SettingsFeedbackHint") };
        var status = new TextBlock { TextWrapping = TextWrapping.Wrap };
        var send = new Button { Content = Copy.Get("SettingsFeedbackSend") };
        send.Click += async (_, _) =>
        {
            var payload = new System.Text.Json.Nodes.JsonObject
            {
                ["id"] = Guid.NewGuid().ToString(),
                ["category"] = (category.SelectedItem as ComboBoxItem)?.Tag as string ?? "other",
                ["message"] = message.Text ?? "",
                ["appVersion"] = AppVersion.Caption,
                ["osVersion"] = Environment.OSVersion.VersionString,
                ["locale"] = LocaleTag.Current,
                ["deviceModel"] = "Windows",
            };
            if (!string.IsNullOrWhiteSpace(contact.Text)) payload["contact"] = contact.Text;
            // 桥的 post 会同步等网络（最长 20 秒），必须 Task.Run 挪下 UI 线程。
            send.IsEnabled = false;
            try
            {
                var (ok, limited) = await Task.Run(() =>
                {
                    var result = MeterCoreNative.PostFeedbackJson(payload.ToJsonString());
                    using var doc = System.Text.Json.JsonDocument.Parse(result);
                    return (
                        doc.RootElement.TryGetProperty("ok", out var o) && o.GetBoolean(),
                        doc.RootElement.TryGetProperty("rateLimited", out var r) && r.GetBoolean());
                });
                status.Text = limited
                    ? Copy.Get("SettingsFeedbackRateLimited")
                    : ok ? Copy.Get("SettingsFeedbackSent") : Copy.Get("SettingsFeedbackFailed");
            }
            catch
            {
                status.Text = Copy.Get("SettingsFeedbackFailed");
            }
            finally
            {
                send.IsEnabled = true;
            }
        };
        Children.Add(category);
        Children.Add(message);
        Children.Add(contact);
        Children.Add(send);
        Children.Add(status);
    }
}
