using System.Runtime.InteropServices;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Dispatching;
using WinRT.Interop;

namespace TollCat;

/// <summary>
/// Shell_NotifyIcon。托盘位图 16/24px 画当月数字；点开面板只读主窗落的数。
/// </summary>
internal static class TrayService
{
    private const uint NimAdd = 0;
    private const uint NimModify = 1;
    private const uint NimDelete = 2;
    private const uint NifMessage = 0x1;
    private const uint NifIcon = 0x2;
    private const uint NifTip = 0x4;
    private const uint WmAppTray = 0x8001;
    private const uint WmLButtonUp = 0x0202;
    private const uint WmRButtonUp = 0x0205;
    private const uint WmDestroy = 0x0002;

    private static NOTIFYICONDATAW _data;
    private static nint _hwnd;
    private static nint _icon;
    private static Window? _main;
    private static Window? _panel;
    private static DispatcherQueueTimer? _timer;
    private static WndProc? _proc;

    public static void Attach(Window main)
    {
        _main = main;
        _proc = WndProcImpl;
        var wc = new WNDCLASSEXW
        {
            cbSize = (uint)Marshal.SizeOf<WNDCLASSEXW>(),
            lpfnWndProc = Marshal.GetFunctionPointerForDelegate(_proc),
            hInstance = GetModuleHandleW(null),
            lpszClassName = "TollCatTray",
        };
        RegisterClassExW(ref wc);
        _hwnd = CreateWindowExW(0, "TollCatTray", "", 0, 0, 0, 0, 0, new nint(-3), nint.Zero, wc.hInstance, nint.Zero);
        _data = new NOTIFYICONDATAW
        {
            cbSize = (uint)Marshal.SizeOf<NOTIFYICONDATAW>(),
            hWnd = _hwnd,
            uID = 1,
            uFlags = NifMessage | NifIcon | NifTip,
            uCallbackMessage = WmAppTray,
            szTip = Copy.Get("AppDisplayName"),
        };
        UpdateIcon();
        Shell_NotifyIconW(NimAdd, ref _data);

        var queue = main.DispatcherQueue;
        _timer = queue.CreateTimer();
        _timer.Interval = TimeSpan.FromMinutes(30);
        _timer.Tick += async (_, _) =>
        {
            if (_main is null) return;
            await Session.Current.RefreshAllAsync();
            UpdateIcon();
        };
        _timer.Start();
        Session.Current.Changed += () => queue.TryEnqueue(UpdateIcon);
    }

    public static void Detach()
    {
        _timer?.Stop();
        if (_hwnd != nint.Zero)
        {
            Shell_NotifyIconW(NimDelete, ref _data);
            DestroyWindow(_hwnd);
            _hwnd = nint.Zero;
        }
        if (_icon != nint.Zero)
        {
            DestroyIcon(_icon);
            _icon = nint.Zero;
        }
    }

    public static void UpdateIcon()
    {
        var amount = Session.Current.Dashboard.Empty
            ? "—"
            : Compact(Session.Current.Dashboard.FormattedVariable);
        var dark = Application.Current.RequestedTheme == ApplicationTheme.Dark;
        var next = TrayGlyph.Create(amount, dark);
        _data.hIcon = next;
        _data.szTip = amount + " · " + Copy.Get("AppDisplayName");
        Shell_NotifyIconW(NimModify, ref _data);
        if (_icon != nint.Zero && _icon != next) DestroyIcon(_icon);
        _icon = next;
    }

    private static string Compact(string amount)
    {
        var trimmed = amount.Replace(" ", "");
        return trimmed.Length <= 6 ? trimmed : trimmed[..6];
    }

    private static nint WndProcImpl(nint hWnd, uint msg, nint wParam, nint lParam)
    {
        if (msg == WmAppTray)
        {
            var mouse = (uint)lParam & 0xFFFF;
            if (mouse is WmLButtonUp or WmRButtonUp)
            {
                ShowPanel();
                return nint.Zero;
            }
        }
        if (msg == WmDestroy) return nint.Zero;
        return DefWindowProcW(hWnd, msg, wParam, lParam);
    }

    private static void ShowPanel()
    {
        if (_main is null) return;
        _main.DispatcherQueue.TryEnqueue(() =>
        {
            _panel?.Close();
            _panel = new TrayPanelWindow();
            _panel.Activate();
        });
    }

    private delegate nint WndProc(nint hWnd, uint msg, nint wParam, nint lParam);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern bool Shell_NotifyIconW(uint dwMessage, ref NOTIFYICONDATAW lpData);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern ushort RegisterClassExW(ref WNDCLASSEXW lpwcx);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern nint CreateWindowExW(
        uint dwExStyle, string lpClassName, string lpWindowName, uint dwStyle,
        int x, int y, int nWidth, int nHeight, nint hWndParent, nint hMenu, nint hInstance, nint lpParam);

    [DllImport("user32.dll")]
    private static extern bool DestroyWindow(nint hWnd);

    [DllImport("user32.dll")]
    private static extern bool DestroyIcon(nint hIcon);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern nint DefWindowProcW(nint hWnd, uint msg, nint wParam, nint lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern nint GetModuleHandleW(string? lpModuleName);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct NOTIFYICONDATAW
    {
        public uint cbSize;
        public nint hWnd;
        public uint uID;
        public uint uFlags;
        public uint uCallbackMessage;
        public nint hIcon;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string szTip;
        public uint dwState;
        public uint dwStateMask;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string szInfo;
        public uint uVersion;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string szInfoTitle;
        public uint dwInfoFlags;
        public Guid guidItem;
        public nint hBalloonIcon;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct WNDCLASSEXW
    {
        public uint cbSize;
        public uint style;
        public nint lpfnWndProc;
        public int cbClsExtra;
        public int cbWndExtra;
        public nint hInstance;
        public nint hIcon;
        public nint hCursor;
        public nint hbrBackground;
        public string? lpszMenuName;
        public string lpszClassName;
        public nint hIconSm;
    }
}
