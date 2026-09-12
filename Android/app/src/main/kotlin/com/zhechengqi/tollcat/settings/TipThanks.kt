package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.R

/**
 * 付款成功之后猫说的那两句。三档价钱差七倍，反应不能一模一样；
 * 回头客换一句招呼。文案和 iOS `TipThanks` 同一份中文源串。
 */
data class TipThanks(
    val headlineRes: Int,
    val noteRes: Int,
) {
    companion object {
        fun make(treat: TipProductID?, isRepeat: Boolean): TipThanks {
            return TipThanks(
                headlineRes = if (isRepeat) {
                    R.string.settings_tip_thanks_repeat
                } else {
                    headlineRes(treat)
                },
                noteRes = noteRes(treat),
            )
        }

        private fun headlineRes(treat: TipProductID?): Int = when (treat) {
            TipProductID.Small, null -> R.string.settings_tip_thanks_small
            TipProductID.Medium -> R.string.settings_tip_thanks_medium
            TipProductID.Large -> R.string.settings_tip_thanks_large
        }

        private fun noteRes(treat: TipProductID?): Int = when (treat) {
            TipProductID.Small -> R.string.settings_tip_note_small
            TipProductID.Medium -> R.string.settings_tip_note_medium
            TipProductID.Large -> R.string.settings_tip_note_large
            null -> R.string.settings_tip_note_unknown
        }
    }
}
