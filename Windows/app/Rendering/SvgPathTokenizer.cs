using System.Globalization;
using System.Numerics;

namespace TollCat;

internal enum SvgPathVerb { Move, Line, Cubic, Close }

internal readonly record struct SvgPathCommand(SvgPathVerb Verb, Vector2 To, Vector2 C1, Vector2 C2);

/// <summary>
/// SVG path `d` 的纯解析。WinUI 几何在 <see cref="SvgPathParser"/>。
/// 支持 M/L/H/V/C/S/Q/T/A/Z（含相对形式与隐式重复），全部归一成
/// Move/Line/Cubic/Close 四种命令：二次、弧线都转三次贝塞尔。
/// 数字按 SVG 规矩断词：第二个小数点开新数（".296.032" 是两个数），
/// 弧线的两个 flag 是单字符。遇到不认识的指令直接抛错——字形数据是
/// 生成的，静默跳过只会画出错形。
/// </summary>
internal static class SvgPathTokenizer
{
    public static List<SvgPathCommand> Parse(string data)
    {
        var commands = new List<SvgPathCommand>();
        var i = 0;
        var current = Vector2.Zero;
        var start = Vector2.Zero;
        Vector2? lastCubicControl = null;
        Vector2? lastQuadControl = null;
        char kind = '\0';
        while (i < data.Length)
        {
            Skip(data, ref i);
            if (i >= data.Length) break;
            if (char.IsLetter(data[i]))
            {
                kind = data[i];
                i++;
                Skip(data, ref i);
            }
            var relative = char.IsLower(kind);
            var upper = char.ToUpperInvariant(kind);
            switch (upper)
            {
                case 'M':
                    {
                        var p = ReadPoint(data, ref i, current, relative);
                        current = start = p;
                        commands.Add(new SvgPathCommand(SvgPathVerb.Move, current, default, default));
                        // 隐式重复的 moveto 坐标按 lineto 处理（SVG 规范）。
                        kind = relative ? 'l' : 'L';
                        break;
                    }
                case 'L':
                    {
                        current = ReadPoint(data, ref i, current, relative);
                        commands.Add(new SvgPathCommand(SvgPathVerb.Line, current, default, default));
                        break;
                    }
                case 'H':
                    {
                        var x = ReadNumber(data, ref i);
                        current = relative ? current with { X = current.X + x } : current with { X = x };
                        commands.Add(new SvgPathCommand(SvgPathVerb.Line, current, default, default));
                        break;
                    }
                case 'V':
                    {
                        var y = ReadNumber(data, ref i);
                        current = relative ? current with { Y = current.Y + y } : current with { Y = y };
                        commands.Add(new SvgPathCommand(SvgPathVerb.Line, current, default, default));
                        break;
                    }
                case 'C':
                    {
                        var c1 = ReadPoint(data, ref i, current, relative);
                        var c2 = ReadPoint(data, ref i, current, relative);
                        var to = ReadPoint(data, ref i, current, relative);
                        commands.Add(new SvgPathCommand(SvgPathVerb.Cubic, to, c1, c2));
                        current = to;
                        lastCubicControl = c2;
                        break;
                    }
                case 'S':
                    {
                        var c1 = lastCubicControl is { } lc ? current + (current - lc) : current;
                        var c2 = ReadPoint(data, ref i, current, relative);
                        var to = ReadPoint(data, ref i, current, relative);
                        commands.Add(new SvgPathCommand(SvgPathVerb.Cubic, to, c1, c2));
                        current = to;
                        lastCubicControl = c2;
                        break;
                    }
                case 'Q':
                    {
                        var q = ReadPoint(data, ref i, current, relative);
                        var to = ReadPoint(data, ref i, current, relative);
                        AddQuadratic(commands, current, q, to);
                        current = to;
                        lastQuadControl = q;
                        break;
                    }
                case 'T':
                    {
                        var q = lastQuadControl is { } lq ? current + (current - lq) : current;
                        var to = ReadPoint(data, ref i, current, relative);
                        AddQuadratic(commands, current, q, to);
                        current = to;
                        lastQuadControl = q;
                        break;
                    }
                case 'A':
                    {
                        var rx = ReadNumber(data, ref i);
                        var ry = ReadNumber(data, ref i);
                        var rotationDegrees = ReadNumber(data, ref i);
                        var largeArc = ReadFlag(data, ref i);
                        var sweep = ReadFlag(data, ref i);
                        var to = ReadPoint(data, ref i, current, relative);
                        AddArc(commands, current, rx, ry, rotationDegrees, largeArc, sweep, to);
                        current = to;
                        break;
                    }
                case 'Z':
                    commands.Add(new SvgPathCommand(SvgPathVerb.Close, start, default, default));
                    current = start;
                    break;
                default:
                    throw new FormatException(
                        $"SVG path 有不认识的指令 '{kind}'（位置 {i}）：{Snippet(data, i)}");
            }
            if (upper is not ('C' or 'S')) lastCubicControl = null;
            if (upper is not ('Q' or 'T')) lastQuadControl = null;
        }
        return commands;
    }

    /// <summary>二次贝塞尔升三次：控制点取 1/3、2/3 处。</summary>
    private static void AddQuadratic(List<SvgPathCommand> commands, Vector2 from, Vector2 control, Vector2 to)
    {
        var c1 = from + (control - from) * (2f / 3f);
        var c2 = to + (control - to) * (2f / 3f);
        commands.Add(new SvgPathCommand(SvgPathVerb.Cubic, to, c1, c2));
    }

    /// <summary>SVG 弧线（F.6.5 端点参数化）拆成 ≤90° 的三次贝塞尔段。</summary>
    private static void AddArc(
        List<SvgPathCommand> commands,
        Vector2 from,
        float rxRaw,
        float ryRaw,
        float rotationDegrees,
        bool largeArc,
        bool sweep,
        Vector2 to)
    {
        if (from == to) return;
        double rx = Math.Abs(rxRaw);
        double ry = Math.Abs(ryRaw);
        if (rx == 0 || ry == 0)
        {
            commands.Add(new SvgPathCommand(SvgPathVerb.Line, to, default, default));
            return;
        }

        var phi = rotationDegrees * Math.PI / 180.0;
        var cosPhi = Math.Cos(phi);
        var sinPhi = Math.Sin(phi);
        var dx2 = (from.X - to.X) / 2.0;
        var dy2 = (from.Y - to.Y) / 2.0;
        var x1p = cosPhi * dx2 + sinPhi * dy2;
        var y1p = -sinPhi * dx2 + cosPhi * dy2;

        var lambda = x1p * x1p / (rx * rx) + y1p * y1p / (ry * ry);
        if (lambda > 1)
        {
            var scale = Math.Sqrt(lambda);
            rx *= scale;
            ry *= scale;
        }

        var rxSq = rx * rx;
        var rySq = ry * ry;
        var numerator = rxSq * rySq - rxSq * y1p * y1p - rySq * x1p * x1p;
        var denominator = rxSq * y1p * y1p + rySq * x1p * x1p;
        var factor = Math.Sqrt(Math.Max(0, numerator / denominator));
        if (largeArc == sweep) factor = -factor;
        var cxp = factor * rx * y1p / ry;
        var cyp = -factor * ry * x1p / rx;
        var cx = cosPhi * cxp - sinPhi * cyp + (from.X + to.X) / 2.0;
        var cy = sinPhi * cxp + cosPhi * cyp + (from.Y + to.Y) / 2.0;

        var theta1 = Math.Atan2((y1p - cyp) / ry, (x1p - cxp) / rx);
        var theta2 = Math.Atan2((-y1p - cyp) / ry, (-x1p - cxp) / rx);
        var delta = theta2 - theta1;
        if (!sweep && delta > 0) delta -= 2 * Math.PI;
        if (sweep && delta < 0) delta += 2 * Math.PI;

        var segments = (int)Math.Ceiling(Math.Abs(delta) / (Math.PI / 2));
        if (segments == 0) return;
        var step = delta / segments;
        var alpha = 4.0 / 3.0 * Math.Tan(step / 4.0);
        var theta = theta1;
        for (var s = 0; s < segments; s++)
        {
            var next = theta + step;
            var p1 = EllipsePoint(cx, cy, rx, ry, cosPhi, sinPhi, theta);
            var p2 = EllipsePoint(cx, cy, rx, ry, cosPhi, sinPhi, next);
            var d1 = EllipseDerivative(rx, ry, cosPhi, sinPhi, theta);
            var d2 = EllipseDerivative(rx, ry, cosPhi, sinPhi, next);
            var c1 = new Vector2((float)(p1.X + alpha * d1.X), (float)(p1.Y + alpha * d1.Y));
            var c2 = new Vector2((float)(p2.X - alpha * d2.X), (float)(p2.Y - alpha * d2.Y));
            // 末段终点用调用方的 to，避免浮点漂移。
            var end = s == segments - 1 ? to : new Vector2((float)p2.X, (float)p2.Y);
            commands.Add(new SvgPathCommand(SvgPathVerb.Cubic, end, c1, c2));
            theta = next;
        }
    }

    private static (double X, double Y) EllipsePoint(
        double cx, double cy, double rx, double ry, double cosPhi, double sinPhi, double theta)
    {
        var cosTheta = Math.Cos(theta);
        var sinTheta = Math.Sin(theta);
        return (
            cx + rx * cosPhi * cosTheta - ry * sinPhi * sinTheta,
            cy + rx * sinPhi * cosTheta + ry * cosPhi * sinTheta);
    }

    private static (double X, double Y) EllipseDerivative(
        double rx, double ry, double cosPhi, double sinPhi, double theta)
    {
        var cosTheta = Math.Cos(theta);
        var sinTheta = Math.Sin(theta);
        return (
            -rx * cosPhi * sinTheta - ry * sinPhi * cosTheta,
            -rx * sinPhi * sinTheta + ry * cosPhi * cosTheta);
    }

    private static Vector2 ReadPoint(string data, ref int i, Vector2 origin, bool relative)
    {
        var x = ReadNumber(data, ref i);
        var y = ReadNumber(data, ref i);
        var point = new Vector2(x, y);
        return relative ? origin + point : point;
    }

    private static float ReadNumber(string data, ref int i)
    {
        Skip(data, ref i);
        var start = i;
        if (i < data.Length && data[i] is '+' or '-') i++;
        var seenDot = false;
        while (i < data.Length)
        {
            var c = data[i];
            if (char.IsDigit(c))
            {
                i++;
            }
            else if (c == '.' && !seenDot)
            {
                // 第二个小数点属于下一个数（SVG 紧凑写法 ".296.032"）。
                seenDot = true;
                i++;
            }
            else
            {
                break;
            }
        }
        // 指数部分（生成数据里目前没有，防御性支持）。
        if (i < data.Length && data[i] is 'e' or 'E')
        {
            var mark = i;
            i++;
            if (i < data.Length && data[i] is '+' or '-') i++;
            if (i < data.Length && char.IsDigit(data[i]))
            {
                while (i < data.Length && char.IsDigit(data[i])) i++;
            }
            else
            {
                i = mark; // 不是指数，回退。
            }
        }
        var slice = data[start..i];
        if (slice.Length == 0 || slice is "+" or "-")
        {
            throw new FormatException($"SVG path 在位置 {start} 缺数字：{Snippet(data, start)}");
        }
        return float.Parse(slice, CultureInfo.InvariantCulture);
    }

    /// <summary>弧线的 large-arc / sweep flag 是单字符 0 或 1，可以和后续数字连写。</summary>
    private static bool ReadFlag(string data, ref int i)
    {
        Skip(data, ref i);
        if (i >= data.Length || data[i] is not ('0' or '1'))
        {
            throw new FormatException($"SVG path 在位置 {i} 缺 flag：{Snippet(data, i)}");
        }
        var value = data[i] == '1';
        i++;
        return value;
    }

    private static string Snippet(string data, int i)
    {
        var from = Math.Max(0, i - 12);
        var to = Math.Min(data.Length, i + 12);
        return $"…{data[from..to]}…";
    }

    private static void Skip(string data, ref int i)
    {
        while (i < data.Length && (char.IsWhiteSpace(data[i]) || data[i] == ',')) i++;
    }
}
