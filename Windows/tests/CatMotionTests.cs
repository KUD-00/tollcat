using TollCat;
using Xunit;

namespace TollCat.Tests;

public class CatMotionTests
{
    [Fact]
    public void IdleBlinkStaysInUnitInterval()
    {
        for (var t = 0.0; t < CatMotion.BLINK_CYCLE; t += 0.05)
        {
            var frame = CatMotion.Frame(CatMotionKind.Idle, t);
            Assert.InRange(frame.Blink, 0f, 1f);
            Assert.InRange(frame.GazeX, -CatMotion.GAZE_X_AMPLITUDE, CatMotion.GAZE_X_AMPLITUDE);
            Assert.InRange(frame.GazeY, -CatMotion.GAZE_Y_AMPLITUDE, CatMotion.GAZE_Y_AMPLITUDE);
        }
    }

    [Fact]
    public void TailIsDeterministic()
    {
        Assert.Equal(CatMotion.Tail(1.2), CatMotion.Tail(1.2));
    }
}
