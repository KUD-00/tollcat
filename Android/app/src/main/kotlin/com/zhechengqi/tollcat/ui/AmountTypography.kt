package com.zhechengqi.tollcat.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle

/**
 * hero 金额：系统字 + 等宽数字。DESIGN-BAR 禁止另换字族；tnum 让位数滚动时不跳。
 */
@Composable
fun amountTextStyle(base: TextStyle): TextStyle {
    return base.copy(fontFeatureSettings = "tnum")
}
