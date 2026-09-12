package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.zhechengqi.tollcat.settings.TipDestination

@Composable
fun GalleryTipStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    TipDestination(onBack = onBack, modifier = modifier)
}
