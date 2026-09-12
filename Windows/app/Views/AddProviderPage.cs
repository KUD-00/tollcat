using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace TollCat;

internal sealed class AddProviderPage : Page
{
    private string _query = "";
    private bool _showingMore;

    public AddProviderPage()
    {
        Loaded += (_, _) => Rebuild();
    }

    private void Rebuild()
    {
        var session = Session.Current;
        var root = new Grid { Padding = new Thickness(24), RowSpacing = 16 };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
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
        root.Children.Add(search);

        var list = new ListView { IsItemClickEnabled = true };
        var existing = session.Memberships().Select(m => m.ProviderId).ToHashSet();
        var needle = _query.Trim();
        var matched = session.Catalog.Offered
            .Where(provider => !existing.Contains(provider.Id))
            .Where(provider => Matches(provider, needle))
            .ToList();
        IEnumerable<CatalogProvider> visible = needle.Length > 0
            ? matched
            : _showingMore
                ? matched.Where(provider => !IsFeatured(provider))
                : matched.Where(IsFeatured);
        foreach (var group in visible.GroupBy(provider => provider.Category))
        {
            foreach (var provider in group.OrderBy(p => p.DisplayName, StringComparer.CurrentCultureIgnoreCase))
            {
                list.Items.Add(ProviderRow(provider));
            }
        }
        if (!_showingMore && needle.Length == 0 && matched.Any(provider => !IsFeatured(provider)))
        {
            var more = new ListViewItem
            {
                Content = new TextBlock { Text = Copy.Get("MoreServices"), Padding = new Thickness(4) },
                Tag = "__more__",
            };
            list.Items.Add(more);
        }
        list.ItemClick += (_, e) =>
        {
            if (e.ClickedItem is not ListViewItem item || item.Tag is not string id) return;
            if (id == "__more__")
            {
                _showingMore = true;
                Rebuild();
                return;
            }
            session.AddProvider(id);
            var account = session.Accounts(id).FirstOrDefault();
            if (account is not null) App.Main?.Navigate("setup", (id, account.AccountId));
            else App.Main?.Navigate("services", id);
        };
        Grid.SetRow(list, 1);
        root.Children.Add(list);
        Content = root;
    }

    /// <summary>常见服务：市占档 1、2，刨去只支持读数信箱的。和 iOS AddProviderSearch.isFeatured 同一口径。</summary>
    private static bool IsFeatured(CatalogProvider provider) =>
        (provider.Tier == 1 || provider.Tier == 2) && !provider.SupportsInbox;

    private static bool Matches(CatalogProvider provider, string needle)
    {
        if (string.IsNullOrWhiteSpace(needle)) return true;
        return provider.DisplayName.Contains(needle, StringComparison.OrdinalIgnoreCase)
            || provider.SearchKeywords.Any(k => k.Contains(needle, StringComparison.OrdinalIgnoreCase));
    }

    private static ListViewItem ProviderRow(CatalogProvider provider)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12, Padding = new Thickness(4) };
        row.Children.Add(new ProviderGlyphControl { ColorKey = provider.ColorKey });
        var text = new StackPanel();
        text.Children.Add(new TextBlock { Text = provider.DisplayName });
        text.Children.Add(new TextBlock { Text = provider.Summary, Opacity = 0.7, FontSize = 12 });
        row.Children.Add(text);
        return new ListViewItem { Content = row, Tag = provider.Id };
    }
}
