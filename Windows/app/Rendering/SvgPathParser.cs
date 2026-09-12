using Microsoft.UI.Xaml.Media;
using Windows.Foundation;

namespace TollCat;

internal static class SvgPathParser
{
    public static PathGeometry Parse(string data)
    {
        var geometry = new PathGeometry();
        PathFigure? figure = null;
        foreach (var command in SvgPathTokenizer.Parse(data))
        {
            switch (command.Verb)
            {
                case SvgPathVerb.Move:
                    figure = new PathFigure
                    {
                        StartPoint = new Point(command.To.X, command.To.Y),
                        IsFilled = true,
                        IsClosed = false,
                    };
                    geometry.Figures.Add(figure);
                    break;
                case SvgPathVerb.Line:
                    figure?.Segments.Add(new LineSegment { Point = new Point(command.To.X, command.To.Y) });
                    break;
                case SvgPathVerb.Cubic:
                    figure?.Segments.Add(new BezierSegment
                    {
                        Point1 = new Point(command.C1.X, command.C1.Y),
                        Point2 = new Point(command.C2.X, command.C2.Y),
                        Point3 = new Point(command.To.X, command.To.Y),
                    });
                    break;
                case SvgPathVerb.Close:
                    if (figure is not null) figure.IsClosed = true;
                    break;
            }
        }
        return geometry;
    }
}
