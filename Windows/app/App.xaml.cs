using Microsoft.UI.Xaml;

namespace TollCat;

public partial class App : Application
{
    internal static MainWindow? Main { get; private set; }
    private Window? _window;

    public App()
    {
        InitializeComponent();
        UnhandledException += (_, e) => e.Handled = true;
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        NativeBootstrap.Ensure();
        ToastService.Register();
        Main = new MainWindow();
        _window = Main;
        _window.Closed += (_, _) =>
        {
            // Flush 会同步等网络（最长 10 秒），别卡关窗；进程还活着（托盘在），后台送。
            _ = Task.Run(UsageAnalytics.Flush);
            // 关主窗不停进程：托盘还在。真正退出走托盘面板。
        };
        _window.Activate();
        TrayService.Attach(_window);
        UsageAnalytics.Record(UsageScreens.Dashboard);
    }

    internal static void ExitApp()
    {
        TrayService.Detach();
        // 尽力送最后一批计数，但退出不给网络卡：最多等 2 秒就放弃。
        Task.Run(UsageAnalytics.Flush).Wait(TimeSpan.FromSeconds(2));
        Current.Exit();
    }
}
