using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace TollCat;

internal sealed class SetupWizardPage : Page
{
    private readonly string _providerId;
    private readonly string _accountId;
    private readonly Dictionary<string, TextBox> _fields = new();
    private bool _guideDone;

    public SetupWizardPage(string providerId, string accountId)
    {
        _providerId = providerId;
        _accountId = accountId;
        Loaded += (_, _) => Rebuild();
    }

    private void Rebuild()
    {
        var session = Session.Current;
        var provider = session.Catalog.Provider(_providerId);
        var account = session.Accounts(_providerId).FirstOrDefault(a => a.AccountId == _accountId);
        if (provider is null || account is null)
        {
            Content = new TextBlock { Padding = new Thickness(24), Text = Copy.Get("ServicesSetupGuideMissing") };
            return;
        }
        var root = new ScrollViewer { Padding = new Thickness(24) };
        var stack = new StackPanel { Spacing = 16, MaxWidth = 640 };
        root.Content = stack;
        stack.Children.Add(new TextBlock
        {
            Text = Copy.Format("SetupTitle", provider.DisplayName),
            Style = (Style)Application.Current.Resources["TitleTextBlockStyle"],
        });

        if (!_guideDone)
        {
            var guide = session.SetupGuide(provider.Id);
            stack.Children.Add(new TextBlock
            {
                Text = guide.Missing ? Copy.Get("ServicesSetupGuideMissingBody") : Copy.Get("SetupIntro"),
                TextWrapping = TextWrapping.Wrap,
            });
            if (!string.IsNullOrEmpty(provider.CredentialSetupUrl))
            {
                var link = new HyperlinkButton { Content = Copy.Get("ServicesSetupOpenConsole") };
                link.Click += (_, _) => _ = Windows.System.Launcher.LaunchUriAsync(new Uri(provider.CredentialSetupUrl));
                stack.Children.Add(link);
            }
            var next = new Button { Content = Copy.Get("ServicesSetupHaveCredentials") };
            next.Click += (_, _) =>
            {
                _guideDone = true;
                Rebuild();
            };
            stack.Children.Add(next);
            Content = root;
            return;
        }

        stack.Children.Add(new TextBlock { Text = Copy.Get("SetupKeystoreNote"), TextWrapping = TextWrapping.Wrap, Opacity = 0.8 });
        var existing = session.LoadCredentialFields(account);
        foreach (var field in provider.Fields)
        {
            stack.Children.Add(new TextBlock { Text = field.Label });
            var box = new TextBox
            {
                PlaceholderText = field.Hint,
                Text = existing.TryGetValue(field.Key, out var v) ? v : "",
            };
            if (field.IsSecret)
            {
                var pw = new PasswordBox { PlaceholderText = field.Hint };
                if (!string.IsNullOrEmpty(box.Text)) pw.Password = box.Text;
                _fields[field.Key] = box;
                pw.PasswordChanged += (_, _) => box.Text = pw.Password;
                stack.Children.Add(pw);
            }
            else
            {
                _fields[field.Key] = box;
                stack.Children.Add(box);
            }
        }
        var status = new TextBlock { TextWrapping = TextWrapping.Wrap };
        var test = new Button { Content = Copy.Get("ActionTestConnection") };
        var save = new Button { Content = Copy.Get("ActionSaveCredentials") };
        var offersFeedback = provider.AccessStatus == "pendingVerification" && !provider.SupportsInbox;
        var feedback = new StackPanel { Spacing = 8, Visibility = Visibility.Collapsed };
        var feedbackLede = new TextBlock { TextWrapping = TextWrapping.Wrap, Opacity = 0.8 };
        var feedbackMessage = new TextBox
        {
            Header = Copy.Get("SettingsFeedback"),
            AcceptsReturn = true,
            Height = 96,
        };
        var feedbackContact = new TextBox { PlaceholderText = Copy.Get("SettingsFeedbackContactHint") };
        var feedbackSend = new Button { Content = Copy.Get("SettingsFeedbackSend") };
        var feedbackStatus = new TextBlock { TextWrapping = TextWrapping.Wrap };
        var feedbackPrivacy = new TextBlock
        {
            Text = Copy.Get("SetupFeedbackPrivacy"),
            TextWrapping = TextWrapping.Wrap,
            Opacity = 0.8,
        };
        feedback.Children.Add(feedbackLede);
        feedback.Children.Add(feedbackMessage);
        feedback.Children.Add(feedbackContact);
        feedback.Children.Add(feedbackSend);
        feedback.Children.Add(feedbackStatus);
        feedback.Children.Add(feedbackPrivacy);
        var lastTestOk = false;
        feedbackSend.Click += async (_, _) =>
        {
            var payload = new System.Text.Json.Nodes.JsonObject
            {
                ["id"] = Guid.NewGuid().ToString(),
                ["category"] = lastTestOk ? "other" : "bug",
                ["message"] = feedbackMessage.Text ?? "",
                ["appVersion"] = AppVersion.Caption,
                ["osVersion"] = Environment.OSVersion.VersionString,
                ["locale"] = LocaleTag.Current,
                ["deviceModel"] = "Windows",
                ["providers"] = new System.Text.Json.Nodes.JsonArray(
                    System.Text.Json.Nodes.JsonValue.Create(provider.DisplayName)),
            };
            if (!string.IsNullOrWhiteSpace(feedbackContact.Text)) payload["contact"] = feedbackContact.Text;
            feedbackSend.IsEnabled = false;
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
                feedbackStatus.Text = limited
                    ? Copy.Get("SettingsFeedbackRateLimited")
                    : ok ? Copy.Get("SettingsFeedbackSent") : Copy.Get("SettingsFeedbackFailed");
                if (ok && !limited)
                {
                    feedbackLede.Visibility = Visibility.Collapsed;
                    feedbackMessage.Visibility = Visibility.Collapsed;
                    feedbackContact.Visibility = Visibility.Collapsed;
                    feedbackSend.Visibility = Visibility.Collapsed;
                    feedbackPrivacy.Visibility = Visibility.Collapsed;
                }
            }
            catch
            {
                feedbackStatus.Text = Copy.Get("SettingsFeedbackFailed");
            }
            finally
            {
                feedbackSend.IsEnabled = true;
            }
        };
        // 桥的 fetch 会同步等网络返回，必须 Task.Run 挪下 UI 线程，否则整窗冻住。
        async Task RunTestAndSave(bool persist)
        {
            var values = _fields.ToDictionary(p => p.Key, p => p.Value.Text);
            test.IsEnabled = save.IsEnabled = false;
            try
            {
                var result = await Task.Run(() => session.TestAndSave(account, values, persist));
                status.Text = result.Ok ? Copy.Format("SetupSuccess", result.Spend ?? "") : (result.Error ?? "");
                lastTestOk = result.Ok;
                if (offersFeedback)
                {
                    feedback.Visibility = Visibility.Visible;
                    feedbackLede.Text = result.Ok
                        ? Copy.Get("SetupFeedbackSuccessLede")
                        : Copy.Get("SetupFeedbackFailureLede");
                    feedbackMessage.Text = result.Ok
                        ? Copy.Format("SetupFeedbackDraftOk", provider.DisplayName)
                        : Copy.Format("SetupFeedbackDraftUnknown", provider.DisplayName);
                    feedbackStatus.Text = "";
                }
                if (persist && result.Ok) App.Main?.Navigate("services", _providerId);
            }
            finally
            {
                test.IsEnabled = save.IsEnabled = true;
            }
        }
        test.Click += async (_, _) => await RunTestAndSave(persist: false);
        save.Click += async (_, _) => await RunTestAndSave(persist: true);
        stack.Children.Add(test);
        stack.Children.Add(save);
        stack.Children.Add(status);
        if (offersFeedback) stack.Children.Add(feedback);
        Content = root;
    }
}
