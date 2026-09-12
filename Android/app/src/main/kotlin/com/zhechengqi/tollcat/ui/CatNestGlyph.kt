package com.zhechengqi.tollcat.ui

import android.content.res.Configuration
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatView

/**
 * 拱门当猫窝。仪表和服务两个整页空态共用，只换表情——
 * 两屏如果插画语言都不一样，用户会以为没跳成功。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun CatNestGlyph(
    mood: CatMood,
    modifier: Modifier = Modifier,
    spokenDescription: String? = null,
    nestSize: Dp = 168.dp,
    catSize: Dp = 116.dp,
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.BottomCenter,
    ) {
        Surface(
            shape = MaterialShapes.Arch.toShape(),
            color = MaterialTheme.colorScheme.secondaryContainer,
            modifier = Modifier.size(nestSize),
        ) {}
        val catModifier = Modifier.offset(y = catSize * 0.17f)
        CatView(
            mood = mood,
            size = catSize,
            modifier = if (spokenDescription == null) {
                catModifier
            } else {
                catModifier.semantics { contentDescription = spokenDescription }
            },
        )
    }
}

@Preview(name = "Sleeping Light", showBackground = true)
@Preview(name = "Sleeping Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CatNestGlyphSleepingPreview() {
    TollCatTheme {
        CatNestGlyph(mood = CatMood.Sleeping)
    }
}

@Preview(name = "Normal Light", showBackground = true)
@Preview(name = "Normal Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CatNestGlyphNormalPreview() {
    TollCatTheme {
        CatNestGlyph(mood = CatMood.Normal)
    }
}
