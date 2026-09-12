using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;

namespace TollCat;

internal sealed class CatView : UserControl
{
    private readonly Canvas _canvas = new();
    private CatMood _mood = CatMood.Sleeping;
    private readonly DispatcherTimer _timer = new() { Interval = TimeSpan.FromMilliseconds(32) };
    private readonly DateTimeOffset _origin = DateTimeOffset.UtcNow;

    public CatView()
    {
        Content = _canvas;
        Width = 220;
        Height = 220;
        _timer.Tick += (_, _) => Redraw();
        Loaded += (_, _) => _timer.Start();
        Unloaded += (_, _) => _timer.Stop();
        ActualThemeChanged += (_, _) => Redraw();
    }

    public CatMood Mood
    {
        get => _mood;
        set
        {
            _mood = value;
            Redraw();
        }
    }

    private void Redraw()
    {
        _canvas.Children.Clear();
        var size = Math.Min(ActualWidth, ActualHeight);
        if (size <= 0) size = 220;
        _canvas.Width = size;
        _canvas.Height = size;
        var scale = size / CatArtwork.ViewBox;
        var elapsed = (DateTimeOffset.UtcNow - _origin).TotalSeconds;
        var kind = CatMotion.Kind(_mood);
        var frame = CatMotion.Frame(kind, elapsed);
        var parts = CatParts.For(_mood);
        var dark = ActualTheme == ElementTheme.Dark;
        var body = dark ? Color.FromArgb(255, 232, 220, 196) : Color.FromArgb(255, 44, 36, 28);
        var ink = dark ? Color.FromArgb(255, 28, 24, 20) : Color.FromArgb(255, 244, 239, 230);

        var bodyTransform = new CompositeTransform
        {
            ScaleX = scale * (1 + frame.Stretch * (CatMotion.SHOCKED_STRETCH_X - 1)),
            ScaleY = scale * (1 + frame.Stretch * (CatMotion.SHOCKED_STRETCH_Y - 1)),
            TranslateX = frame.Shake * CatMotion.SHAKE_AMPLITUDE * size,
        };

        AddPath(CatArtwork.SilhouettePathAt(frame.LeftEarDegrees, frame.RightEarDegrees), body, bodyTransform);
        var tail = new CompositeTransform
        {
            ScaleX = scale,
            ScaleY = scale,
            Rotation = frame.TailDegrees,
            CenterX = CatArtwork.TailPivot.X * scale,
            CenterY = CatArtwork.TailPivot.Y * scale,
        };
        AddPath(CatArtwork.TailPath, body, tail);

        var face = new CompositeTransform
        {
            ScaleX = scale,
            ScaleY = scale,
            TranslateX = frame.GazeX * scale,
            TranslateY = frame.GazeY * scale,
        };
        foreach (var eye in CatArtwork.EyeballShapes(parts.Eyes))
        {
            var lid = 1f - frame.Blink * (1f - CatMotion.CLOSED_LID_SCALE);
            var eyeTransform = new CompositeTransform
            {
                ScaleX = scale,
                ScaleY = scale * lid,
                TranslateX = frame.GazeX * scale,
                TranslateY = frame.GazeY * scale,
                CenterY = 556 * scale,
            };
            AddPath(eye, ink, eyeTransform);
        }
        foreach (var mark in CatArtwork.EyeMarkShapes(parts.Eyes)) AddPath(mark, ink, face);
        var mouth = CatArtwork.MouthShape(parts.Mouth);
        if (mouth is not null)
        {
            var mouthTransform = new CompositeTransform
            {
                ScaleX = scale,
                ScaleY = scale,
                TranslateX = frame.MouthX * scale,
                TranslateY = frame.MouthY * scale,
            };
            AddPath(mouth, ink, mouthTransform);
        }

        if (parts.Accessory == CatAccessory.Zzz)
        {
            foreach (var mark in CatArtwork.ZzzMarks)
            {
                var lift = CatMotion.ZzzLift(elapsed);
                var transform = new CompositeTransform
                {
                    ScaleX = scale * (mark.Size / CatArtwork.ZzzWidth),
                    ScaleY = scale * (mark.Size / CatArtwork.ZzzHeight),
                    TranslateY = -lift * 24 * scale,
                };
                AddPath(CatArtwork.ZzzPath, ink, transform);
            }
        }
        if (parts.Accessory == CatAccessory.Bang)
        {
            foreach (var bang in CatArtwork.BangPaths) AddPath(bang, ink, bodyTransform);
        }
        if (parts.Accessory == CatAccessory.Skull)
        {
            AddPath(CatArtwork.SkullHeadPath, ink, bodyTransform);
            foreach (var eye in CatArtwork.SkullEyePaths) AddPath(eye, body, bodyTransform);
        }
    }

    private void AddPath(PathGeometry geometry, Color color, Transform transform)
    {
        var path = new Path
        {
            Data = geometry,
            Fill = new SolidColorBrush(color),
            RenderTransform = transform,
        };
        _canvas.Children.Add(path);
    }
}
