using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace TollCat;

internal sealed class ProviderDetailPage : Page
{
    private readonly string _providerId;
    private string _range = "days30";

    private readonly Action _onChanged;

    public ProviderDetailPage(string providerId)
    {
        _providerId = providerId;
        // 只在挂树期间订阅，防止死页面滞留（见 DashboardPage 注释）。
        _onChanged = () => DispatcherQueue.TryEnqueue(Rebuild);
        Loaded += (_, _) =>
        {
            Session.Current.Changed += _onChanged;
            Rebuild();
        };
        Unloaded += (_, _) => Session.Current.Changed -= _onChanged;
    }

    private void Rebuild()
    {
        var session = Session.Current;
        var provider = session.Catalog.Provider(_providerId);
        if (provider is null)
        {
            Content = new TextBlock { Text = Copy.Get("ServicesEmptyTitle"), Padding = new Thickness(24) };
            return;
        }
        var root = new ScrollViewer { Padding = new Thickness(24) };
        var stack = new StackPanel { Spacing = 16, MaxWidth = 720 };
        root.Content = stack;

        var head = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
        head.Children.Add(new ProviderGlyphControl { ColorKey = provider.ColorKey, Width = 40, Height = 40 });
        var titles = new StackPanel();
        titles.Children.Add(new TextBlock { Text = provider.DisplayName, Style = (Style)Application.Current.Resources["TitleTextBlockStyle"] });
        titles.Children.Add(new TextBlock { Text = provider.Summary, Opacity = 0.75 });
        head.Children.Add(titles);
        stack.Children.Add(head);

        var accounts = session.Accounts(_providerId);
        if (accounts.Count == 0)
        {
            stack.Children.Add(new TextBlock { Text = Copy.Get("DetailUsageEmpty"), TextWrapping = TextWrapping.Wrap });
        }
        foreach (var account in accounts)
        {
            var snap = session.LatestSnapshot(_providerId);
            var card = new StackPanel { Spacing = 8 };
            card.Children.Add(new TextBlock { Text = Copy.Format("ServicesAccountN", accounts.ToList().IndexOf(account) + 1) });
            if (snap is not null)
            {
                var amount = snap.CurrentSpendUsd ?? snap.BalanceUsd;
                if (amount is not null)
                {
                    card.Children.Add(new TextBlock
                    {
                        Text = session.FormatUsd(amount),
                        FontSize = 28,
                        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                    });
                }
            }
            else
            {
                card.Children.Add(new TextBlock { Text = Copy.Get("ServicesNoReading") });
            }
            var connect = new Button
            {
                Content = session.HasCredentials(account)
                    ? Copy.Get("ActionManageCredentials")
                    : Copy.Format("ActionConnectUsage", provider.DisplayName),
            };
            connect.Click += (_, _) => App.Main?.Navigate("setup", (provider.Id, account.AccountId));
            card.Children.Add(connect);
            stack.Children.Add(Card(card));
        }

        if (provider.HasLiveFetch)
        {
            var chart = new HistoryChartControl();
            chart.Bind(session.HistoryChart(_providerId, _range), session.DisplayCurrency);
            var ranges = new ComboBox { Header = Copy.Get("ServicesHistoryRange") };
            foreach (var (tag, label) in new[] { ("days7", "ServicesHistory7"), ("days30", "ServicesHistory30"), ("months12", "ServicesHistory12") })
            {
                var item = new ComboBoxItem { Content = Copy.Get(label), Tag = tag };
                ranges.Items.Add(item);
                if (tag == _range) ranges.SelectedItem = item;
            }
            ranges.SelectionChanged += (_, _) =>
            {
                if (ranges.SelectedItem is ComboBoxItem item && item.Tag is string tag && tag != _range)
                {
                    _range = tag;
                    Rebuild();
                }
            };
            stack.Children.Add(new TextBlock { Text = Copy.Get("ServicesHistory"), FontWeight = Microsoft.UI.Text.FontWeights.SemiBold });
            stack.Children.Add(ranges);
            stack.Children.Add(chart);
        }
        else if (provider.SupportsInbox)
        {
            stack.Children.Add(new TextBlock { Text = Copy.Get("DetailInboxHint"), TextWrapping = TextWrapping.Wrap });
        }

        var remove = new Button { Content = Copy.Format("ActionClearProvider", provider.DisplayName) };
        remove.Click += async (_, _) =>
        {
            var dialog = new ContentDialog
            {
                Title = Copy.Format("ServicesRemoveTitle", provider.DisplayName),
                Content = Copy.Get("ServicesRemoveBody"),
                PrimaryButtonText = Copy.Get("ServicesRemoveConfirm"),
                CloseButtonText = Copy.Get("ActionCancel"),
                XamlRoot = XamlRoot,
            };
            if (await dialog.ShowAsync() == ContentDialogResult.Primary)
            {
                session.RemoveProvider(_providerId);
                App.Main?.Navigate("services");
            }
        };
        stack.Children.Add(remove);
        Content = root;
    }

    private static Border Card(UIElement child) => new()
    {
        Padding = new Thickness(16),
        CornerRadius = new CornerRadius(8),
        Background = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["CardBackgroundFillColorDefaultBrush"],
        Child = child,
    };
}
