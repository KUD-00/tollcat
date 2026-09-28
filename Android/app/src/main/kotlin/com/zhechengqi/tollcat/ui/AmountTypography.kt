package com.zhechengqi.tollcat.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.Typeface
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.em

/**
 * hero 金额：系统字 + 等宽数字。DESIGN-BAR 禁止另换字族；tnum 让位数滚动时不跳。
 */
@Composable
fun amountTextStyle(base: TextStyle): TextStyle {
    return base.copy(fontFeatureSettings = "tnum")
}

/**
 * 仪表盘顶栏的大数字：系统自带的 `sans-serif-condensed`（Roboto 窄体）加重到 800。
 * 仍是系统字族、不另打包字体；窄体是为了「到今天」和「月底大约」两个数能并排放在一行。
 */
@Composable
fun heroAmountTextStyle(fontSize: TextUnit): TextStyle {
    val family = remember {
        val condensed = android.graphics.Typeface.create("sans-serif-condensed", android.graphics.Typeface.NORMAL)
        FontFamily(Typeface(android.graphics.Typeface.create(condensed, 800, false)))
    }
    return TextStyle(
        fontFamily = family,
        fontSize = fontSize,
        lineHeight = 1.em,
        fontFeatureSettings = "tnum",
    )
}
