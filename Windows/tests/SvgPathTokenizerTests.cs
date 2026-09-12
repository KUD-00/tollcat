using TollCat;
using Xunit;

namespace TollCat.Tests;

public class SvgPathTokenizerTests
{
    [Fact]
    public void ParsesMoveCubicClose()
    {
        var commands = SvgPathTokenizer.Parse("M0 0 C 1 2 3 4 5 6 Z");
        Assert.Equal(SvgPathVerb.Move, commands[0].Verb);
        Assert.Equal(SvgPathVerb.Cubic, commands[1].Verb);
        Assert.Equal(5, commands[1].To.X);
        Assert.Equal(6, commands[1].To.Y);
        Assert.Equal(SvgPathVerb.Close, commands[2].Verb);
    }

    [Fact]
    public void ParsesPackedDecimals()
    {
        // Simple Icons 的紧凑写法：第二个小数点开新数。
        var commands = SvgPathTokenizer.Parse("M0 0c0 .296.032.535.088.71");
        Assert.Equal(2, commands.Count);
        Assert.Equal(SvgPathVerb.Cubic, commands[1].Verb);
        Assert.Equal(0.088f, commands[1].To.X, 3);
        Assert.Equal(0.71f, commands[1].To.Y, 3);
    }

    [Fact]
    public void ParsesRealAwsPrefix()
    {
        // ProviderGlyphArtwork 里 AWS path 的真实开头，曾把 65 字符吞成一个数。
        // c 后面是 18 个数：三段三次曲线，加上 M 共四条命令。
        var commands = SvgPathTokenizer.Parse(
            "M6.763 10.036c0 .296.032.535.088.71.064.176.144.368.256.576.04.063.056.127.056.183");
        Assert.Equal(4, commands.Count);
        Assert.All(commands.GetRange(1, 3), c => Assert.Equal(SvgPathVerb.Cubic, c.Verb));
    }

    [Fact]
    public void ParsesPackedNegatives()
    {
        var commands = SvgPathTokenizer.Parse("M1 2l3-4-5.5.5Z");
        Assert.Equal(SvgPathVerb.Line, commands[1].Verb);
        Assert.Equal(4, commands[1].To.X);   // 1 + 3
        Assert.Equal(-2, commands[1].To.Y);  // 2 + -4
        Assert.Equal(SvgPathVerb.Line, commands[2].Verb);
        Assert.Equal(-1.5f, commands[2].To.X, 3); // 4 + -5.5
        Assert.Equal(-1.5f, commands[2].To.Y, 3); // -2 + .5
    }

    [Fact]
    public void ParsesHorizontalAndVertical()
    {
        var commands = SvgPathTokenizer.Parse("M1 1H4v2h-2V1Z");
        Assert.Equal(SvgPathVerb.Line, commands[1].Verb);
        Assert.Equal(4, commands[1].To.X);
        Assert.Equal(1, commands[1].To.Y);
        Assert.Equal(3, commands[2].To.Y); // v2
        Assert.Equal(2, commands[3].To.X); // h-2
        Assert.Equal(1, commands[4].To.Y); // V1
    }

    [Fact]
    public void SmoothCubicReflectsControlPoint()
    {
        var commands = SvgPathTokenizer.Parse("M0 0C1 2 3 4 5 6S9 10 11 12");
        Assert.Equal(SvgPathVerb.Cubic, commands[2].Verb);
        // S 的第一控制点 = 上一段 c2 (3,4) 对 (5,6) 的镜像 = (7,8)。
        Assert.Equal(7, commands[2].C1.X);
        Assert.Equal(8, commands[2].C1.Y);
    }

    [Fact]
    public void QuadraticBecomesCubic()
    {
        var commands = SvgPathTokenizer.Parse("M0 0Q3 6 6 0");
        Assert.Equal(2, commands.Count);
        Assert.Equal(SvgPathVerb.Cubic, commands[1].Verb);
        Assert.Equal(2, commands[1].C1.X, 3);
        Assert.Equal(4, commands[1].C1.Y, 3);
        Assert.Equal(6, commands[1].To.X);
        Assert.Equal(0, commands[1].To.Y);
    }

    [Fact]
    public void ArcWithPackedFlagsBecomesCubics()
    {
        // flag 是单字符，可与后续数字连写："a2.5 2.5 0 011.768.732"
        // = rx 2.5, ry 2.5, rot 0, largeArc 0, sweep 1, to (+1.768, +0.732)。
        var commands = SvgPathTokenizer.Parse("M0 0a2.5 2.5 0 011.768.732");
        Assert.True(commands.Count >= 2);
        Assert.All(commands.GetRange(1, commands.Count - 1), c => Assert.Equal(SvgPathVerb.Cubic, c.Verb));
        var last = commands[^1];
        Assert.Equal(1.768f, last.To.X, 3);
        Assert.Equal(0.732f, last.To.Y, 3);
    }

    [Fact]
    public void ImplicitMoveRepetitionIsLine()
    {
        var commands = SvgPathTokenizer.Parse("M0 0 1 2 3 4");
        Assert.Equal(SvgPathVerb.Move, commands[0].Verb);
        Assert.Equal(SvgPathVerb.Line, commands[1].Verb);
        Assert.Equal(SvgPathVerb.Line, commands[2].Verb);
    }

    [Fact]
    public void ZFollowedByMoveDoesNotEatTheLetter()
    {
        var commands = SvgPathTokenizer.Parse("M0 0L1 1ZM2 2L3 3Z");
        Assert.Equal(SvgPathVerb.Close, commands[2].Verb);
        Assert.Equal(SvgPathVerb.Move, commands[3].Verb);
        Assert.Equal(2, commands[3].To.X);
    }

    [Fact]
    public void UnknownVerbThrowsLoudly()
    {
        Assert.Throws<FormatException>(() => SvgPathTokenizer.Parse("M0 0X1 2"));
    }
}
