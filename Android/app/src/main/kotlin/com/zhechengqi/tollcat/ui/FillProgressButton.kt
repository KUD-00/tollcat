package com.zhechengqi.tollcat.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import com.zhechengqi.tollcat.R

/**
 * 测连接主按钮：系统绿从左铺过 tint，不转圈，也不把按钮洗成灰。
 * 进行中靠 `allowsHitTesting` 等价物——`enabled` 仍为 true，避免 M3 disabled 容器色。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun FillProgressButton(
    text: String,
    phase: FillProgressPhase,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    val reduceMotion = LocalReduceMotion.current
    val sheen = remember { Animatable(0f) }
    LaunchedEffect(phase, reduceMotion) {
        when (phase) {
            FillProgressPhase.Progressing -> {
                if (reduceMotion) {
                    sheen.snapTo(1f)
                } else {
                    sheen.snapTo(0f)
                    sheen.animateTo(0.9f, tween(1150, easing = EaseOut))
                }
            }
            FillProgressPhase.Completed -> {
                sheen.animateTo(1f, tween(if (reduceMotion) 120 else 280))
                sheen.animateTo(0f, tween(if (reduceMotion) 120 else 280))
            }
            FillProgressPhase.Idle -> sheen.animateTo(0f, tween(180))
        }
    }
    val canPress = enabled && phase != FillProgressPhase.Progressing
    val testing = stringResource(R.string.setup_testing)
    val height = ButtonDefaults.MediumContainerHeight
    val fill = Color(0xFF34C759)
    Box(modifier = modifier.heightIn(min = height)) {
        Button(
            onClick = { if (canPress) onClick() },
            // 测的时候不能把 enabled 关掉：系统会把整颗洗成灰，铺色就看不见了。
            enabled = enabled,
            modifier = Modifier
                .fillMaxWidth()
                .semantics {
                    if (phase == FillProgressPhase.Progressing) stateDescription = testing
                },
            shapes = ButtonDefaults.shapes(),
            contentPadding = ButtonDefaults.contentPaddingFor(height),
        ) {
            Text(text)
        }
        if (sheen.value > 0.01f) {
            Box(
                Modifier
                    .matchParentSize()
                    .clip(MaterialTheme.shapes.extraLarge)
                    .fillMaxHeight(),
            ) {
                Box(
                    Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(sheen.value)
                        .background(fill.copy(alpha = 0.85f)),
                )
            }
        }
    }
}
