using Windows.ApplicationModel;

namespace TollCat;

/// <summary>
/// MSIX StartupTask。系统设置是唯一真相源，不落盘——同 Mac LoginItem。
/// </summary>
internal static class StartupTaskService
{
    public const string TaskId = "TollCatStartup";

    public static async Task<bool> IsEnabledAsync()
    {
        try
        {
            var task = await StartupTask.GetAsync(TaskId);
            return task.State is StartupTaskState.Enabled or StartupTaskState.EnabledByPolicy;
        }
        catch
        {
            return false;
        }
    }

    public static async Task<bool> SetEnabledAsync(bool enabled)
    {
        try
        {
            var task = await StartupTask.GetAsync(TaskId);
            if (enabled)
            {
                var state = await task.RequestEnableAsync();
                return state is StartupTaskState.Enabled or StartupTaskState.EnabledByPolicy;
            }
            task.Disable();
            return false;
        }
        catch
        {
            return false;
        }
    }
}
