using System.Runtime.InteropServices;

namespace TollCat;

/// <summary>16 / 24px 托盘位图。亮暗两套底，数字用系统字体画进 HICON。</summary>
internal static class TrayGlyph
{
    public static nint Create(string text, bool dark)
    {
        var size = 24;
        var hdc = CreateCompatibleDC(nint.Zero);
        var dib = CreateDib(size, size, out var bits);
        var old = SelectObject(hdc, dib);
        // COLORREF 是 0x00BBGGRR：品牌色 #221F1C / #F4EFE6 要按 B,G,R 排字节。
        var bg = dark ? 0x001C1F22 : 0x00E6EFF4;
        var fg = dark ? 0x00E6EFF4 : 0x001C1F22;
        Fill(hdc, size, bg);
        var rect = new RECT { left = 1, top = 4, right = size - 1, bottom = size - 1 };
        SetBkMode(hdc, 1);
        SetTextColor(hdc, fg);
        DrawTextW(hdc, text, -1, ref rect, 0x00000001 | 0x00000020 | 0x00000100);
        SelectObject(hdc, old);
        // GDI 的 FillRect / DrawTextW 不写 alpha 字节：全 0 的 alpha 会让
        // 托盘按逐像素透明把整个图标画没。冲掉 GDI 批处理后手工置为不透明。
        GdiFlush();
        for (var p = 0; p < size * size; p++)
        {
            Marshal.WriteByte(bits, p * 4 + 3, 0xFF);
        }
        // mask 必须是独立的 1bpp 位图（全 0 = 不透明），不能拿彩色位图凑数。
        var mask = CreateBitmap(size, size, 1, 1, nint.Zero);
        var iconInfo = new ICONINFO
        {
            fIcon = true,
            hbmColor = dib,
            hbmMask = mask,
        };
        var icon = CreateIconIndirect(ref iconInfo);
        DeleteObject(mask);
        DeleteObject(dib);
        DeleteDC(hdc);
        return icon;
    }

    private static void Fill(nint hdc, int size, int color)
    {
        var brush = CreateSolidBrush(color);
        var rect = new RECT { left = 0, top = 0, right = size, bottom = size };
        FillRect(hdc, ref rect, brush);
        DeleteObject(brush);
    }

    private static nint CreateDib(int w, int h, out nint bits)
    {
        var bmi = new BITMAPINFO
        {
            bmiHeader = new BITMAPINFOHEADER
            {
                biSize = (uint)Marshal.SizeOf<BITMAPINFOHEADER>(),
                biWidth = w,
                biHeight = -h,
                biPlanes = 1,
                biBitCount = 32,
                biCompression = 0,
            },
        };
        return CreateDIBSection(nint.Zero, ref bmi, 0, out bits, nint.Zero, 0);
    }

    [DllImport("gdi32.dll")]
    private static extern nint CreateCompatibleDC(nint hdc);

    [DllImport("gdi32.dll")]
    private static extern bool DeleteDC(nint hdc);

    [DllImport("gdi32.dll")]
    private static extern nint SelectObject(nint hdc, nint obj);

    [DllImport("gdi32.dll")]
    private static extern bool DeleteObject(nint obj);

    [DllImport("gdi32.dll")]
    private static extern nint CreateSolidBrush(int color);

    [DllImport("gdi32.dll")]
    private static extern nint CreateDIBSection(nint hdc, ref BITMAPINFO bmi, uint usage, out nint bits, nint section, uint offset);

    [DllImport("gdi32.dll")]
    private static extern bool GdiFlush();

    [DllImport("gdi32.dll")]
    private static extern nint CreateBitmap(int width, int height, uint planes, uint bitCount, nint bits);

    [DllImport("user32.dll")]
    private static extern int FillRect(nint hdc, ref RECT lprc, nint hbr);

    [DllImport("gdi32.dll")]
    private static extern int SetBkMode(nint hdc, int mode);

    [DllImport("gdi32.dll")]
    private static extern int SetTextColor(nint hdc, int color);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int DrawTextW(nint hdc, string lpchText, int cchText, ref RECT lprc, uint format);

    [DllImport("user32.dll")]
    private static extern nint CreateIconIndirect(ref ICONINFO piconinfo);

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT { public int left, top, right, bottom; }

    [StructLayout(LayoutKind.Sequential)]
    private struct ICONINFO
    {
        public bool fIcon;
        public int xHotspot;
        public int yHotspot;
        public nint hbmMask;
        public nint hbmColor;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BITMAPINFOHEADER
    {
        public uint biSize;
        public int biWidth;
        public int biHeight;
        public ushort biPlanes;
        public ushort biBitCount;
        public uint biCompression;
        public uint biSizeImage;
        public int biXPelsPerMeter;
        public int biYPelsPerMeter;
        public uint biClrUsed;
        public uint biClrImportant;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BITMAPINFO
    {
        public BITMAPINFOHEADER bmiHeader;
        public uint bmiColors;
    }
}
