using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;

namespace TollCat;

internal sealed class ProviderGlyphControl : UserControl
{
    private readonly Grid _root = new();
    private readonly Path _path = new() { Stretch = Stretch.Uniform, Margin = new Microsoft.UI.Xaml.Thickness(6) };
    private readonly TextBlock _mono = new()
    {
        HorizontalAlignment = Microsoft.UI.Xaml.HorizontalAlignment.Center,
        VerticalAlignment = Microsoft.UI.Xaml.VerticalAlignment.Center,
        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
    };

    public ProviderGlyphControl()
    {
        Width = 28;
        Height = 28;
        _root.CornerRadius = new Microsoft.UI.Xaml.CornerRadius(6);
        _root.Children.Add(_path);
        _root.Children.Add(_mono);
        Content = _root;
        ActualThemeChanged += (_, _) => Apply();
        Apply();
    }

    public string ColorKey
    {
        get;
        set
        {
            field = value;
            Apply();
        }
    } = "";

    private void Apply()
    {
        var dark = ActualTheme == Microsoft.UI.Xaml.ElementTheme.Dark;
        var color = ProviderPalette.Of(ColorKey, dark);
        _root.Background = new SolidColorBrush(color);
        var on = ContrastInk(color);
        var data = ProviderGlyphArtwork.PathData(ColorKey);
        if (string.IsNullOrEmpty(data))
        {
            _path.Data = null;
            _path.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
            _mono.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
            _mono.Text = ProviderGlyphArtwork.MonogramLetter(ColorKey);
            _mono.Foreground = new SolidColorBrush(on);
        }
        else
        {
            _mono.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
            _path.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
            var geometry = SvgPathParser.Parse(data);
            if (ProviderGlyphArtwork.UsesEvenOddFill(ColorKey))
            {
                geometry.FillRule = FillRule.EvenOdd;
            }
            _path.Data = geometry;
            _path.Fill = new SolidColorBrush(on);
        }
    }

    private static Color ContrastInk(Color tile)
    {
        var luminance = (0.2126 * tile.R + 0.7152 * tile.G + 0.0722 * tile.B) / 255.0;
        return luminance > 0.55
            ? Color.FromArgb(255, 28, 24, 20)
            : Color.FromArgb(255, 255, 255, 255);
    }
}
