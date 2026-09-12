package com.zhechengqi.tollcat.ui.cat

/** 猫的命名表情。和 iOS MeterDesign.CatMood 一一对应，本包不认识账单。 */
enum class CatMood {
    Normal,
    Sleeping,
    Saved,
    Alert,
    Shocked,
    Awkward,
    Dead,
    ;

    val parts: CatParts
        get() = CatParts(this)

    val motion: CatMotionKind
        get() = when (this) {
            Normal, Saved, Alert, Awkward -> CatMotionKind.Idle
            Sleeping -> CatMotionKind.Sleeping
            Shocked -> CatMotionKind.Shocked
            Dead -> CatMotionKind.Still
        }
}

/** 眼睛图层。生产界面由命名表情选用，画廊可以单独拧。 */
enum class CatEyes {
    Normal,
    Closed,
    Sparkle,
    Alert,
    X,
    ;

    val canBlink: Boolean
        get() = when (this) {
            Normal, Sparkle, Alert -> true
            Closed, X -> false
        }
}

/** 嘴图层。`SmallO` 是省到了那只小圆嘴，`O` 是吓到 / 翻肚皮的大张嘴。 */
enum class CatMouth { None, Neutral, Smile, Flat, SmallO, O, Wave }

/** 身体以外的挂件。和眼镜无关——眼镜是脸上的一层，可以跟挂件叠。 */
enum class CatAccessory { None, Zzz, Bang, Skull }

/** 动效循环。和图层无关：睡觉的身体也可以播吓到那一套。 */
enum class CatMotionKind {
    /** 眨眼、视线、带着惯性的嘴、摆尾。身体不压扁。 */
    Idle,

    /** 摆尾、ZZZ 上浮。 */
    Sleeping,

    /** 绷直、颤抖。 */
    Shocked,

    /** 完全不动。 */
    Still,
}

/** 一只猫的图层组合。命名表情是它的预设；画廊可以拆开拧。 */
data class CatParts(
    val eyes: CatEyes = CatEyes.Normal,
    val mouth: CatMouth = CatMouth.Neutral,
    val accessory: CatAccessory = CatAccessory.None,
    val isUpsideDown: Boolean = false,
    val wearsGlasses: Boolean = false,
) {
    companion object {
        operator fun invoke(mood: CatMood): CatParts = when (mood) {
            CatMood.Normal -> CatParts(eyes = CatEyes.Normal, mouth = CatMouth.Neutral)
            CatMood.Sleeping -> CatParts(eyes = CatEyes.Closed, mouth = CatMouth.None, accessory = CatAccessory.Zzz)
            CatMood.Saved -> CatParts(eyes = CatEyes.Sparkle, mouth = CatMouth.SmallO)
            CatMood.Alert -> CatParts(eyes = CatEyes.Alert, mouth = CatMouth.Flat)
            CatMood.Shocked -> CatParts(eyes = CatEyes.Normal, mouth = CatMouth.O, accessory = CatAccessory.Bang)
            CatMood.Awkward -> CatParts(eyes = CatEyes.Normal, mouth = CatMouth.Wave)
            CatMood.Dead -> CatParts(
                eyes = CatEyes.X,
                mouth = CatMouth.O,
                accessory = CatAccessory.Skull,
                isUpsideDown = true,
            )
        }
    }
}
