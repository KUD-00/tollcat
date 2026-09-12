using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace TollCat;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Title = Copy.Get("AppDisplayName");
        ExtendsContentIntoTitleBar = true;
        NavDashboard.Content = Copy.Get("TabDashboard");
        NavServices.Content = Copy.Get("TabServices");
        NavSettings.Content = Copy.Get("TabSettings");
        Nav.SelectedItem = NavDashboard;
        AppearanceTheme.ApplyTo(Nav);
        ContentFrame.Content = new DashboardPage();
        Session.Current.Changed += () => DispatcherQueue.TryEnqueue(UpdateTitle);
        UpdateTitle();
    }

    internal void Navigate(string tag, object? parameter = null)
    {
        switch (tag)
        {
            case "dashboard":
                Nav.SelectedItem = NavDashboard;
                ContentFrame.Content = new DashboardPage();
                UsageAnalytics.Record(UsageScreens.Dashboard);
                break;
            case "services":
                Nav.SelectedItem = NavServices;
                ContentFrame.Content = parameter is string id
                    ? new ProviderDetailPage(id)
                    : new ServicesPage();
                UsageAnalytics.Record(parameter is string ? UsageScreens.ServicesDetail : UsageScreens.Services);
                break;
            case "add":
                Nav.SelectedItem = NavServices;
                ContentFrame.Content = new AddProviderPage();
                UsageAnalytics.Record(UsageScreens.ServicesAdd);
                break;
            case "setup":
                Nav.SelectedItem = NavServices;
                if (parameter is (string providerId, string accountId))
                {
                    ContentFrame.Content = new SetupWizardPage(providerId, accountId);
                    UsageAnalytics.Record(UsageScreens.ServicesSetup);
                }
                break;
            case "settings":
                Nav.SelectedItem = NavSettings;
                ContentFrame.Content = new SettingsPage();
                UsageAnalytics.Record(UsageScreens.Settings);
                break;
        }
    }

    private void OnNav(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is NavigationViewItem item && item.Tag is string tag)
        {
            Navigate(tag);
        }
    }

    private void UpdateTitle()
    {
        var dash = Session.Current.Dashboard;
        Title = dash.Empty
            ? Copy.Get("AppDisplayName")
            : $"{dash.FormattedVariable} · {Copy.Get("AppDisplayName")}";
    }
}
