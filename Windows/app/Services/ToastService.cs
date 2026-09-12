using Microsoft.Windows.AppNotifications;
using Microsoft.Windows.AppNotifications.Builder;

namespace TollCat;

/// <summary>余额 / 异常告警。文案口径同 iOS 通知，不写金额进系统通知中心以外的地方。</summary>
internal static class ToastService
{
    private static bool _registered;

    public static void Register()
    {
        if (_registered) return;
        AppNotificationManager.Default.Register();
        _registered = true;
    }

    public static void NotifyBalanceAlerts(DashboardSnapshot dashboard)
    {
        if (dashboard.BalanceAlerts.Count == 0 && dashboard.Anomalies.Count == 0) return;
        try
        {
            Register();
            var lead = dashboard.BalanceAlerts.FirstOrDefault();
            var title = lead is not null ? Copy.Get("ToastBalanceTitle") : Copy.Get("ToastAnomalyTitle");
            var body = lead?.Caption ?? dashboard.Anomalies.FirstOrDefault()?.Caption ?? dashboard.CatSpeech;
            var notification = new AppNotificationBuilder()
                .AddText(title)
                .AddText(body)
                .BuildNotification();
            AppNotificationManager.Default.Show(notification);
        }
        catch
        {
            // 没注册成功就静默。托盘数字仍在。
        }
    }
}
