using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;

namespace TollCat;

/// <summary>历史图。分桶和刻度值来自桥；这里只画，浮签口径沿用 ChartCalloutLabel。</summary>
internal sealed class HistoryChartControl : UserControl
{
    private readonly Canvas _canvas = new() { Height = 160 };
    private readonly TextBlock _callout = new() { Visibility = Visibility.Collapsed };
    private HistoryChartState _state = HistoryChartState.None.Instance;
    private string _currency = "USD";

    public HistoryChartControl()
    {
        var root = new Grid();
        root.Children.Add(_canvas);
        root.Children.Add(_callout);
        Content = root;
        _canvas.PointerMoved += OnMoved;
        _canvas.PointerExited += (_, _) => _callout.Visibility = Visibility.Collapsed;
        SizeChanged += (_, _) => Redraw();
    }

    public void Bind(HistoryChartState state, string currency)
    {
        _state = state;
        _currency = currency;
        Redraw();
    }

    private void Redraw()
    {
        _canvas.Children.Clear();
        var width = Math.Max(ActualWidth, 240);
        var height = _canvas.Height;
        _canvas.Width = width;
        switch (_state)
        {
            case HistoryChartState.Spend spend:
                DrawSpend(spend, width, height);
                break;
            case HistoryChartState.Balance balance:
                DrawBalance(balance, width, height);
                break;
        }
    }

    private void DrawSpend(HistoryChartState.Spend spend, double width, double height)
    {
        var max = spend.AxisMarks.DefaultIfEmpty(1).Max();
        if (max <= 0) max = 1;
        var buckets = spend.Buckets;
        if (buckets.Count == 0) return;
        var gap = 2;
        var barW = Math.Max(2, (width - gap * buckets.Count) / buckets.Count);
        var byBucket = spend.Points.ToDictionary(p => p.BucketMillis, p => p.Amount);
        for (var i = 0; i < buckets.Count; i++)
        {
            byBucket.TryGetValue(buckets[i], out var amount);
            var h = amount / max * (height - 16);
            var rect = new Rectangle
            {
                Width = barW,
                Height = Math.Max(h, amount > 0 ? 2 : 0),
                Fill = (Brush)Application.Current.Resources["AccentFillColorDefaultBrush"],
                RadiusX = 2,
                RadiusY = 2,
                Tag = (buckets[i], amount),
            };
            Canvas.SetLeft(rect, i * (barW + gap));
            Canvas.SetTop(rect, height - rect.Height);
            _canvas.Children.Add(rect);
        }
    }

    private void DrawBalance(HistoryChartState.Balance balance, double width, double height)
    {
        var max = balance.AxisMarks.DefaultIfEmpty(1).Max();
        if (max <= 0) max = 1;
        var points = balance.Points;
        if (points.Count == 0) return;
        var start = balance.StartMillis;
        var span = Math.Max(1, balance.EndMillis - start);
        var geo = new PathGeometry();
        var figure = new PathFigure { IsFilled = false };
        for (var i = 0; i < points.Count; i++)
        {
            var x = (points[i].BucketMillis - start) / (double)span * width;
            var y = height - points[i].Amount / max * (height - 16);
            var pt = new Point(x, y);
            if (i == 0) figure.StartPoint = pt;
            else figure.Segments.Add(new LineSegment { Point = pt });
        }
        geo.Figures.Add(figure);
        _canvas.Children.Add(new Path
        {
            Data = geo,
            Stroke = (Brush)Application.Current.Resources["AccentFillColorDefaultBrush"],
            StrokeThickness = 2,
        });
    }

    private void OnMoved(object sender, PointerRoutedEventArgs e)
    {
        var pos = e.GetCurrentPoint(_canvas).Position;
        foreach (var child in _canvas.Children.OfType<Rectangle>())
        {
            if (child.Tag is not (long bucket, double amount)) continue;
            var left = Canvas.GetLeft(child);
            if (pos.X < left || pos.X > left + child.Width) continue;
            var formatted = Session.Current.FormatUsd(amount.ToString("0.##"));
            var when = DateTimeOffset.FromUnixTimeMilliseconds(bucket).ToLocalTime();
            _callout.Text = $"{when:MMM d}  {formatted}";
            _callout.Visibility = Visibility.Visible;
            Canvas.SetLeft(_callout, Math.Clamp(left, 0, Math.Max(0, _canvas.Width - 120)));
            Canvas.SetTop(_callout, 4);
            return;
        }
    }
}
