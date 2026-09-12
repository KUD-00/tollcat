using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace TollCat;

internal sealed class ServicesPage : Page
{
    private string _query = "";

    private readonly Action _onChanged;

    public ServicesPage()
    {
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
        var root = new Grid { Padding = new Thickness(24), RowSpacing = 16 };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var toolbar = new Grid();
        toolbar.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        toolbar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var search = new AutoSuggestBox
        {
            PlaceholderText = Copy.Get("SearchProviders"),
            QueryIcon = new SymbolIcon(Symbol.Find),
            Text = _query,
        };
        search.TextChanged += (_, _) =>
        {
            _query = search.Text ?? "";
            Rebuild();
        };
        var add = new Button { Content = Copy.Get("ActionAddService"), Margin = new Thickness(12, 0, 0, 0) };
        add.Click += (_, _) => App.Main?.Navigate("add");
        Grid.SetColumn(add, 1);
        toolbar.Children.Add(search);
        toolbar.Children.Add(add);
        root.Children.Add(toolbar);

        var list = new ListView { SelectionMode = ListViewSelectionMode.Single };
        var memberships = session.Memberships();
        if (memberships.Count == 0)
        {
            root.Children.Add(new TextBlock
            {
                Text = Copy.Get("ServicesEmptyBody"),
                TextWrapping = TextWrapping.Wrap,
            });
            Grid.SetRow(root.Children[^1], 1);
            Content = root;
            return;
        }
        foreach (var membership in memberships)
        {
            var provider = session.Catalog.Provider(membership.ProviderId);
            if (provider is null) continue;
            if (!Matches(provider, _query)) continue;
            var snap = session.LatestSnapshot(membership.ProviderId);
            var amount = Amount(session, snap, provider);
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12, Padding = new Thickness(4) };
            row.Children.Add(new ProviderGlyphControl { ColorKey = provider.ColorKey });
            var text = new StackPanel();
            text.Children.Add(new TextBlock { Text = provider.DisplayName });
            text.Children.Add(new TextBlock { Text = amount, Opacity = 0.7, FontSize = 12 });
            row.Children.Add(text);
            var item = new ListViewItem { Content = row, Tag = provider.Id };
            list.Items.Add(item);
        }
        list.ItemClick += (_, e) =>
        {
            if (e.ClickedItem is ListViewItem item && item.Tag is string id)
            {
                App.Main?.Navigate("services", id);
            }
        };
        list.IsItemClickEnabled = true;
        Grid.SetRow(list, 1);
        root.Children.Add(list);
        Content = root;
    }

    private static bool Matches(CatalogProvider provider, string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return true;
        var q = query.Trim();
        if (provider.DisplayName.Contains(q, StringComparison.OrdinalIgnoreCase)) return true;
        return provider.SearchKeywords.Any(k => k.Contains(q, StringComparison.OrdinalIgnoreCase));
    }

    private static string Amount(Session session, SnapshotRow? snap, CatalogProvider provider)
    {
        if (snap is null) return Copy.Get("ServicesNoAmount");
        if (snap.CurrentSpendUsd is not null) return session.FormatUsd(snap.CurrentSpendUsd);
        if (snap.BalanceUsd is not null) return session.FormatUsd(snap.BalanceUsd);
        if (snap.FreeQuotaUsedRatio is double r) return Copy.Format("ServicesQuotaUsed", (int)Math.Round(r * 100));
        return provider.Summary;
    }
}
