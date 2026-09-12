namespace TollCat;

internal enum CatMood { Normal, Sleeping, Saved, Alert, Shocked, Awkward, Dead }

internal enum CatEyes { Normal, Closed, Sparkle, Alert, X }

internal enum CatMouth { None, Neutral, Smile, Flat, SmallO, O, Wave }

internal enum CatAccessory { None, Zzz, Bang, Skull }

internal enum CatMotionKind { Idle, Sleeping, Shocked, Still }

internal readonly record struct CatParts(
    CatEyes Eyes,
    CatMouth Mouth,
    CatAccessory Accessory,
    bool IsUpsideDown,
    bool WearsGlasses)
{
    public static CatParts For(CatMood mood) => mood switch
    {
        CatMood.Normal => new(CatEyes.Normal, CatMouth.Neutral, CatAccessory.None, false, false),
        CatMood.Sleeping => new(CatEyes.Closed, CatMouth.None, CatAccessory.Zzz, false, false),
        CatMood.Saved => new(CatEyes.Sparkle, CatMouth.SmallO, CatAccessory.None, false, false),
        CatMood.Alert => new(CatEyes.Alert, CatMouth.Flat, CatAccessory.None, false, false),
        CatMood.Shocked => new(CatEyes.Normal, CatMouth.O, CatAccessory.Bang, false, false),
        CatMood.Awkward => new(CatEyes.Normal, CatMouth.Wave, CatAccessory.None, false, false),
        CatMood.Dead => new(CatEyes.X, CatMouth.O, CatAccessory.Skull, true, false),
        _ => new(CatEyes.Normal, CatMouth.Neutral, CatAccessory.None, false, false),
    };
}

internal readonly record struct CatMotionFrame(
    float Squash = 0,
    float Blink = 0,
    float TailDegrees = 2f,
    float ZzzLift = 0.35f,
    float Shake = 0,
    float Stretch = 0,
    float GazeX = 0,
    float GazeY = 0,
    float MouthX = 0,
    float MouthY = 0,
    float LeftEarDegrees = 0,
    float RightEarDegrees = 0);

/// <summary>和 iOS MeterDesign.CatMotion / Android CatMotion 同一套常数与曲线。</summary>
internal static class CatMotion
{
    internal const double TAIL_PERIOD = 2.4;
    internal const double ZZZ_PERIOD = 2.1;
    internal const double SHOCK_PERIOD = 1.4;
    internal const float FLATTEN = 0.10f;
    internal const double TAIL_MIN_DEGREES = -5.0;
    internal const double TAIL_MAX_DEGREES = 8.0;
    internal const float SHOCKED_STRETCH_X = 0.94f;
    internal const float SHOCKED_STRETCH_Y = 1.12f;
    internal const float SHAKE_AMPLITUDE = 0.028f;
    internal const float CLOSED_LID_SCALE = 0.40f;
    internal const double BLINK_DURATION = 0.18;
    internal const double COVER_BLINK_DURATION = 0.20;
    internal const float GAZE_X_AMPLITUDE = 24f;
    internal const float GAZE_Y_AMPLITUDE = 12f;
    internal const float MOUTH_FOLLOW_X = 0.36f;
    internal const float MOUTH_FOLLOW_Y = 0.30f;
    internal const double MOUTH_LAG_X = 0.18;
    internal const double MOUTH_LAG_Y = 0.26;
    internal const double EAR_MIN_DEGREES = -8.0;
    internal const double EAR_MAX_DEGREES = 14.0;
    internal const double EAR_CYCLE = 53.7;
    internal const double EAR_FLICK_DURATION = 0.32;
    internal const double BLINK_CYCLE = 97.3;

    public static CatMotionKind Kind(CatMood mood) => mood switch
    {
        CatMood.Sleeping => CatMotionKind.Sleeping,
        CatMood.Shocked => CatMotionKind.Shocked,
        CatMood.Dead => CatMotionKind.Still,
        _ => CatMotionKind.Idle,
    };

    public static CatMood Parse(string raw) => raw.ToLowerInvariant() switch
    {
        "sleeping" => CatMood.Sleeping,
        "saved" => CatMood.Saved,
        "alert" => CatMood.Alert,
        "shocked" => CatMood.Shocked,
        "awkward" => CatMood.Awkward,
        "dead" => CatMood.Dead,
        _ => CatMood.Normal,
    };

    public static CatMotionFrame Frame(CatMotionKind motion, double time) => motion switch
    {
        CatMotionKind.Still => default,
        CatMotionKind.Shocked => new CatMotionFrame(Shake: Shake(time), Stretch: 1f),
        CatMotionKind.Sleeping => new CatMotionFrame(TailDegrees: Tail(time), ZzzLift: ZzzLift(time)),
        _ => new CatMotionFrame(
            Blink: Blink(time),
            TailDegrees: Tail(time),
            GazeX: GazeX(time),
            GazeY: GazeY(time),
            MouthX: MouthX(time),
            MouthY: MouthY(time)),
    };

    public static float Tail(double time)
    {
        var phase = Cyclic(time, TAIL_PERIOD) / TAIL_PERIOD;
        var wave = 0.5 - 0.5 * Math.Cos(2 * Math.PI * phase);
        return (float)(TAIL_MIN_DEGREES + (TAIL_MAX_DEGREES - TAIL_MIN_DEGREES) * wave);
    }

    public static float ZzzLift(double time)
    {
        var phase = Cyclic(time, ZZZ_PERIOD) / ZZZ_PERIOD;
        return (float)(0.15 + 0.85 * (0.5 - 0.5 * Math.Cos(2 * Math.PI * phase)));
    }

    public static float Shake(double time)
    {
        var phase = Cyclic(time, SHOCK_PERIOD);
        if (phase >= 0.32) return 0f;
        var decay = 1 - phase / 0.32;
        return (float)(Math.Sin(2 * Math.PI * phase / 0.08) * decay);
    }

    public static float Blink(double time)
    {
        var local = Cyclic(time, BLINK_CYCLE);
        float peak = 0;
        foreach (var start in BlinkStarts)
        {
            peak = Math.Max(peak, LidAt(local, start));
            peak = Math.Max(peak, LidAt(local + BLINK_CYCLE, start));
        }
        return peak;
    }

    public static float GazeX(double time) =>
        Wave(time, 11.3, 0.4) * 18f + Wave(time, 3.7, 2.1) * 6f;

    public static float GazeY(double time) =>
        Wave(time, 9.1, 1.3) * 9f + Wave(time, 4.3, 0.7) * 3f;

    public static float MouthX(double time) => Lagged(GazeX, time, MOUTH_LAG_X) * MOUTH_FOLLOW_X;

    public static float MouthY(double time) => Lagged(GazeY, time, MOUTH_LAG_Y) * MOUTH_FOLLOW_Y;

    private static readonly List<double> BlinkStarts = BuildBlinkStarts();

    private static List<double> BuildBlinkStarts()
    {
        var starts = new List<double>();
        var rng = new BlinkRng(0x5EED);
        var t = 1.4;
        while (t < BLINK_CYCLE - BLINK_DURATION)
        {
            starts.Add(t);
            t += 1.9 + rng.Unit() * 2.7;
            if (rng.Unit() < 0.18)
            {
                if (t < BLINK_CYCLE - BLINK_DURATION) starts.Add(t);
                t += 0.24;
            }
        }
        return starts;
    }

    private static float LidAt(double time, double start)
    {
        var k = (time - start) / BLINK_DURATION;
        if (k is < 0 or > 1) return 0f;
        return LidEnvelope((float)k);
    }

    public static float LidEnvelope(float k)
    {
        var clamped = Math.Clamp(k, 0f, 1f);
        if (clamped < 0.45f) return Ease(clamped / 0.45f);
        return 1f - Ease((clamped - 0.45f) / 0.55f);
    }

    private static float Wave(double time, double period, double phase) =>
        (float)Math.Sin((time + phase) * 2 * Math.PI / period);

    private static float Lagged(Func<double, float> sample, double time, double lag) =>
        0.7f * sample(time - lag) + 0.3f * sample(time - lag * 2.2);

    private static double Cyclic(double time, double period)
    {
        var remainder = time % period;
        return remainder < 0 ? remainder + period : remainder;
    }

    private static float Ease(float t)
    {
        var clamped = Math.Clamp(t, 0f, 1f);
        return clamped * clamped * (3 - 2 * clamped);
    }

    private sealed class BlinkRng
    {
        private long _state;
        public BlinkRng(int seed) => _state = (seed == 0 ? 1 : seed) & 0xFFFFFFFFL;
        public double Unit()
        {
            _state = (_state * 1_664_525L + 1_013_904_223L) & 0xFFFFFFFFL;
            return _state / 4_294_967_295.0;
        }
    }
}
