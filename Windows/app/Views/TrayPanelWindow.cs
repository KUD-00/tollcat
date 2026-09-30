using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace TollCat;

/// <summary>托盘点开面板。对照 Mac 菜单栏：数字、构成、近几个月、刷新 / 打开主窗 / 退出。</summary>
internal sealed class TrayPanelWindow : Window
{
    public TrayPanelWindow()
    {
        Title = Copy.Get("AppDisplayName");
        SystemBackdrop = new MicaBackdrop();
        // 面板和 Mac 菜单栏面板一样跟主窗口的取景框走，限定语随数字一起出现；
        // 托盘图标上的常驻数字才走小组件口径（TrayDashboard）。
        var dash = Session.Current.Dashboard;
        var stack = new StackPanel { Spacing = 10, Padding = new Thickness(16), Width = 320 };
        stack.Children.Add(new TextBlock
        {
            Text = dash.Empty ? Copy.Get("DashboardEmptyTitle") : dash.PeriodCaption,
            Opacity = 0.7,
        });
        stack.Children.Add(new TextBlock
        {
            Text = dash.Empty ? "—" : dash.FormattedTotal,
            FontSize = 28,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });
        if (dash.FilterNote is { } filterNote)
        {
            stack.Children.Add(new TextBlock { Text = filterNote, Opacity = 0.7 });
        }
        if (dash.Composition.Count > 0)
        {
            foreach (var row in dash.Composition)
            {
                stack.Children.Add(new TextBlock { Text = $"{row.DisplayName}  {row.Amount}" });
            }
        }
        if (dash.Trend.Count > 0)
        {
            stack.Children.Add(new TextBlock
            {
                Text = string.Join("  ", dash.Trend.Select(t => $"{t.Month} {t.Amount}")),
                TextWrapping = TextWrapping.Wrap,
                Opacity = 0.8,
            });
        }
        var refresh = new Button { Content = Copy.Get("ActionRefresh"), HorizontalAlignment = HorizontalAlignment.Stretch };
        refresh.Click += async (_, _) =>
        {
            await Session.Current.RefreshAllAsync();
            Close();
            App.Main?.Activate();
        };
        var open = new Button { Content = Copy.Get("TrayOpenMain"), HorizontalAlignment = HorizontalAlignment.Stretch };
        open.Click += (_, _) =>
        {
            App.Main?.Activate();
            Close();
        };
        var quit = new Button { Content = Copy.Get("TrayQuit"), HorizontalAlignment = HorizontalAlignment.Stretch };
        quit.Click += (_, _) => App.ExitApp();
        stack.Children.Add(refresh);
        stack.Children.Add(open);
        stack.Children.Add(quit);
        AppearanceTheme.ApplyTo(stack);
        Content = stack;
    }
}
