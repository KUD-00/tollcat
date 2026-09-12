package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun GalleryRefreshView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var isRefreshing by remember { mutableStateOf(false) }
    var runID by remember { mutableIntStateOf(0) }
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val refreshLabel = stringResource(R.string.action_refresh)
    fun spin() {
        if (isRefreshing) return
        runID += 1
        val id = runID
        isRefreshing = true
        scope.launch {
            delay(1200)
            if (id != runID) return@launch
            isRefreshing = false
            haptic.performHapticFeedback(HapticFeedbackType.Confirm)
        }
    }
    GalleryScaffold(title = refreshLabel, onBack = onBack, modifier = modifier) {
        Text(refreshLabel, style = MaterialTheme.typography.titleSmall)
        IconButton(
            onClick = { spin() },
            enabled = !isRefreshing,
            shapes = IconButtonDefaults.shapes(),
        ) {
            GalleryRefreshGlyph(isRefreshing = isRefreshing, contentDescription = refreshLabel)
        }
        Spacer(Modifier.height(16.dp))
        Text(stringResource(R.string.hero_label), style = MaterialTheme.typography.titleSmall)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                stringResource(R.string.services_last_refresh, stringResource(R.string.services_just_now)),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f),
            )
            IconButton(
                onClick = { spin() },
                enabled = !isRefreshing,
                shapes = IconButtonDefaults.shapes(),
            ) {
                GalleryRefreshGlyph(isRefreshing = isRefreshing, contentDescription = refreshLabel)
            }
        }
        Spacer(Modifier.height(16.dp))
        PrimaryButton(
            onClick = { spin() },
            enabled = !isRefreshing,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(refreshLabel)
        }
    }
}

@Composable
private fun GalleryRefreshGlyph(
    isRefreshing: Boolean,
    contentDescription: String,
    modifier: Modifier = Modifier,
) {
    val reduceMotion = LocalReduceMotion.current
    val rotation = remember { Animatable(0f) }
    LaunchedEffect(isRefreshing, reduceMotion) {
        if (!isRefreshing) {
            rotation.snapTo(0f)
            return@LaunchedEffect
        }
        if (reduceMotion) return@LaunchedEffect
        while (true) {
            rotation.animateTo(rotation.value + 360f, tween(800, easing = LinearEasing))
        }
    }
    SymbolIcon(
        MaterialSymbol.Refresh,
        contentDescription = contentDescription,
        modifier = modifier.graphicsLayer { rotationZ = rotation.value },
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryRefreshViewPreview() {
    TollCatTheme {
        GalleryRefreshView(onBack = {})
    }
}
