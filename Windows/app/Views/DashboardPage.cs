using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace TollCat;

internal sealed class DashboardPage : Page
{
    private readonly Action _onChanged;

    public DashboardPage()
    {
        // 只在挂树期间订阅：MainWindow 每次导航都 new 新页面，
        // 订阅留在进程级单例 Session 上不解绑等于永久泄漏死页面。
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
        var dash = session.Dashboard;
        var root = new ScrollViewer { Padding = new Thickness(24) };
        var stack = new StackPanel { Spacing = 16, MaxWidth = 880 };
        root.Content = stack;

        var header = new Grid();
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var title = new TextBlock
        {
            Text = dash.Empty ? Copy.Get("DashboardEmptyTitle") : dash.MonthTitle,
            Style = (Style)Application.Current.Resources["TitleTextBlockStyle"],
        };
        var refresh = new Button
        {
            Content = session.IsRefreshing ? Copy.Get("DashboardLoading") : Copy.Get("ActionRefresh"),
            IsEnabled = !session.IsRefreshing,
        };
        refresh.Click += async (_, _) => await session.RefreshAllAsync();
        Grid.SetColumn(refresh, 1);
        header.Children.Add(title);
        header.Children.Add(refresh);
        stack.Children.Add(header);

        if (dash.Empty)
        {
            stack.Children.Add(new TextBlock
            {
                Text = Copy.Get("DashboardEmptyBody"),
                TextWrapping = TextWrapping.Wrap,
                Opacity = 0.8,
            });
            var add = new Button { Content = Copy.Get("DashboardEmptyAction") };
            add.Click += (_, _) => App.Main?.Navigate("add");
            stack.Children.Add(add);
            if (!session.Preferences.HidesCat)
            {
                stack.Children.Add(new CatView { Mood = CatMood.Sleeping, HorizontalAlignment = HorizontalAlignment.Left });
            }
            Content = root;
            return;
        }

        var hero = new StackPanel { Spacing = 4 };
        hero.Children.Add(new TextBlock { Text = Copy.Get("HeroLabel"), Opacity = 0.7 });
        hero.Children.Add(new TextBlock
        {
            Text = dash.FormattedVariable,
            FontSize = 42,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            FontFamily = new FontFamily("Cascadia Mono, Consolas"),
        });
        if (dash.AllowsProjection)
        {
            hero.Children.Add(new TextBlock
            {
                Text = Copy.Format("ProjectedCaption", dash.FormattedProjected),
                Opacity = 0.75,
            });
        }
        if (dash.SubscriptionFormatted is not null)
        {
            hero.Children.Add(new TextBlock { Text = Copy.Format("SubscriptionCaption", dash.SubscriptionFormatted) });
        }
        if (dash.CurrencyNote is not null)
        {
            hero.Children.Add(new TextBlock { Text = dash.CurrencyNote, Opacity = 0.7 });
        }
        stack.Children.Add(hero);

        if (!session.Preferences.HidesCat)
        {
            var catRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 16 };
            catRow.Children.Add(new CatView { Mood = CatMotion.Parse(dash.CatMood) });
            catRow.Children.Add(new TextBlock
            {
                Text = dash.CatSpeech,
                TextWrapping = TextWrapping.Wrap,
                MaxWidth = 360,
                VerticalAlignment = VerticalAlignment.Center,
            });
            stack.Children.Add(catRow);
        }

        if (dash.ComparisonCaption is not null)
        {
            stack.Children.Add(Module(Copy.Get("ModuleComparison"), dash.ComparisonCaption + "  " + (dash.ComparisonPercentText ?? "")));
        }
        if (dash.Composition.Count > 0)
        {
            stack.Children.Add(CompositionCard(dash));
        }
        if (dash.Upcoming.Count > 0)
        {
            var panel = new StackPanel { Spacing = 8 };
            foreach (var row in dash.Upcoming)
            {
                panel.Children.Add(Line(row.Name, row.Amount + " · " + row.DateCaption, row.ColorKey));
            }
            stack.Children.Add(Module(Copy.Get("ModuleUpcoming"), child: panel));
        }
        if (dash.FreeQuota.Count > 0)
        {
            var panel = new StackPanel { Spacing = 8 };
            foreach (var row in dash.FreeQuota)
            {
                panel.Children.Add(Line(row.DisplayName, row.Caption, row.ColorKey));
            }
            stack.Children.Add(Module(Copy.Get("ModuleQuota"), child: panel));
        }
        if (dash.Anomalies.Count > 0)
        {
            var panel = new StackPanel { Spacing = 8 };
            foreach (var row in dash.Anomalies)
            {
                panel.Children.Add(Line(row.DisplayName, row.SignedPercent + " · " + row.Caption, ""));
            }
            stack.Children.Add(Module(Copy.Get("ModuleAnomaly"), child: panel));
        }
        if (dash.BalanceAlerts.Count > 0)
        {
            var panel = new StackPanel { Spacing = 8 };
            foreach (var row in dash.BalanceAlerts)
            {
                panel.Children.Add(Line(row.DisplayName, row.Caption, ""));
            }
            stack.Children.Add(Module(Copy.Get("ModuleBalance"), child: panel));
        }
        if (dash.Trend.Count > 0)
        {
            stack.Children.Add(TrendCard(dash));
        }

        Content = root;
    }

    private static UIElement CompositionCard(DashboardSnapshot dash)
    {
        var bar = new Grid { Height = 12 };
        var col = 0;
        var total = dash.Composition.Sum(r => r.Fraction);
        foreach (var row in dash.Composition)
        {
            bar.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(Math.Max(row.Fraction, 0.01), GridUnitType.Star) });
            var cell = new Border
            {
                Background = new SolidColorBrush(ProviderPalette.Of(row.ColorKey, Application.Current.RequestedTheme == ApplicationTheme.Dark)),
                Margin = new Thickness(col == 0 ? 0 : 2, 0, 0, 0),
                CornerRadius = new CornerRadius(col == 0 ? 4 : 0, col == dash.Composition.Count - 1 ? 4 : 0, col == dash.Composition.Count - 1 ? 4 : 0, col == 0 ? 4 : 0),
            };
            Grid.SetColumn(cell, col);
            bar.Children.Add(cell);
            col++;
        }
        _ = total;
        var list = new StackPanel { Spacing = 8 };
        list.Children.Add(bar);
        foreach (var row in dash.Composition)
        {
            var line = Line(row.DisplayName, $"{row.Amount} · {row.Percent}%", row.ColorKey);
            line.Tapped += (_, _) => App.Main?.Navigate("services", row.ProviderId);
            list.Children.Add(line);
        }
        return Module(Copy.Get("ModuleComposition"), child: list);
    }

    private static UIElement TrendCard(DashboardSnapshot dash)
    {
        var bars = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, Height = 80 };
        foreach (var row in dash.Trend)
        {
            var col = new StackPanel { Width = 36, VerticalAlignment = VerticalAlignment.Bottom };
            col.Children.Add(new Border
            {
                Height = Math.Max(4, row.Fraction * 64),
                Background = (Brush)Application.Current.Resources["AccentFillColorDefaultBrush"],
                CornerRadius = new CornerRadius(2),
            });
            col.Children.Add(new TextBlock { Text = row.Month, FontSize = 11, HorizontalAlignment = HorizontalAlignment.Center });
            bars.Children.Add(col);
        }
        return Module(Copy.Get("ModuleTrend"), child: bars);
    }

    private static StackPanel Line(string title, string subtitle, string colorKey)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        if (!string.IsNullOrEmpty(colorKey))
        {
            row.Children.Add(new ProviderGlyphControl { ColorKey = colorKey });
        }
        var text = new StackPanel();
        text.Children.Add(new TextBlock { Text = title });
        text.Children.Add(new TextBlock { Text = subtitle, Opacity = 0.7, FontSize = 12 });
        row.Children.Add(text);
        return row;
    }

    private static Border Module(string title, string? body = null, UIElement? child = null)
    {
        var stack = new StackPanel { Spacing = 8 };
        stack.Children.Add(new TextBlock { Text = title, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold });
        if (body is not null) stack.Children.Add(new TextBlock { Text = body, TextWrapping = TextWrapping.Wrap });
        if (child is not null) stack.Children.Add(child);
        return new Border
        {
            Padding = new Thickness(16),
            CornerRadius = new CornerRadius(8),
            Background = (Brush)Application.Current.Resources["CardBackgroundFillColorDefaultBrush"],
            Child = stack,
        };
    }
}
