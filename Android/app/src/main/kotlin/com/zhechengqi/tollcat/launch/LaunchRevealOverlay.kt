package com.zhechengqi.tollcat.launch

import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.lerp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import kotlin.math.min
import kotlin.math.roundToInt
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * 冷启动过渡，和 iOS `LaunchRevealOverlay` 同一段时间线（SPEC「启动画面与过渡」）。
 *
 * Android 12 起系统启动画面只能是底色 + 居中图标。系统启动图标画的就是这只完整口袋（缩进
 * 192dp 的圆里），这层从那枚图标的位置起步、放大到和 iOS 故事板一样的位置和大小（相当于
 * iOS 从主屏图标放大那一下），再让圆牌飞到构成卡片条头的服务小块上，猫和口袋沉下去，底色淡掉。
 *
 * 方框的摆法（居中、短边比例、封顶、上提）只在 [LaunchPocketGeometry] 一处，和 iOS 同一组数。
 */
@Composable
internal fun LaunchRevealOverlay(
    /** 系统启动图标（iconView）在窗口里的位置，交接回调里量到的。还没量到就按 [systemSplash] 推定。 */
    iconBounds: Rect?,
    /**
     * 这次启动有系统启动画面（Android 12+）。系统图标总在窗口正中、[SPLASH_ICON] 见方，交接回调来之前
     * 就按这个位置画：系统等太久会自己撤掉启动画面、回调晚到甚至不来，这层露出来时也和系统画面重合。
     * false（Android 11 及以下）：没有图标可接，口袋直接在终点起步。
     */
    systemSplash: Boolean,
    /** 系统画面已经交给 App。之前这层被系统画面盖着，停在起点不动。 */
    handedOver: Boolean,
    /** 圆牌 kind → 图例段 id，共享层算好（`launchTargets`）。 */
    targets: Map<String, String>,
    registry: LaunchSwatchRegistry,
    /** 仪表盘在台前而且有数。不是（开场引导、别的 tab、还没服务）就只淡出。 */
    showsDashboard: () -> Boolean,
    onFinished: () -> Unit,
    /** Preview 里停在静帧上看构图。 */
    animates: Boolean = true,
) {
    val reduceMotion = LocalReduceMotion.current
    val latestTargets by rememberUpdatedState(targets)
    val latestShowsDashboard by rememberUpdatedState(showsDashboard)
    val density = LocalDensity.current
    val lift = with(density) { LIFT.toPx() }

    // 第一次组合时系统还没交接：停在系统图标的位置（grow = 0），交接后放大。
    val grow = remember { Animatable(0f) }
    val sink = remember { Animatable(0f) }
    val background = remember { Animatable(1f) }
    val whole = remember { Animatable(1f) }
    val flights = remember { mutableStateMapOf<String, Rect>() }
    val flightProgress = remember { mutableStateMapOf<String, TokenFlight>() }
    var ended by remember { mutableStateOf(false) }
    var size by remember { mutableStateOf(IntSize.Zero) }

    LaunchedEffect(handedOver, animates) {
        if (!handedOver || !animates) return@LaunchedEffect
        if (reduceMotion) {
            grow.snapTo(1f)
            whole.animateTo(0f, tween(250))
            onFinished()
            return@LaunchedEffect
        }
        if (systemSplash) {
            grow.animateTo(1f, tween(320, easing = STANDARD))
            delay(120)
        } else {
            grow.snapTo(1f)
            delay(250)
        }
        // 等仪表盘的数和构成卡片到位：有一块落点报上来就说明卡片排好了，再等一帧让其余的也报完。
        // 滚到屏幕外的那几段在懒加载列表里可能根本不排，不能等它们。最多等 500 ms。
        var waited = 0L
        while (waited < 500 && !(latestShowsDashboard() &&
                (latestTargets.isEmpty() || latestTargets.values.any { it in registry.targets }))
        ) {
            delay(30)
            waited += 30
        }
        delay(32)
        if (!latestShowsDashboard()) {
            whole.animateTo(0f, tween(250))
            onFinished()
            return@LaunchedEffect
        }
        // 落点得在屏幕里：滚到下面去的那一段量出来是被裁成零的框，飞过去没有意义，跟着口袋沉下去。
        val screen = Rect(0f, 0f, size.width.toFloat(), size.height.toFloat())
        latestTargets.forEach { (kind, id) ->
            registry.targets[id]?.takeIf { it.width > 0f && it.height > 0f && screen.contains(it.center) }
                ?.let { flights[kind] = it }
        }
        flights.keys.forEach { kind -> latestTargets[kind]?.let { registry.alpha[it] = 0f } }
        coroutineScope {
            launch { sink.animateTo(1f, tween(320, easing = ACCELERATE)) }
            launch {
                delay(110)
                background.animateTo(0f, tween(360, easing = DECELERATE))
            }
            LaunchPocketGeometry.tokens.filter { it.kind in flights }.forEachIndexed { index, token ->
                launch {
                    delay(50L * index)
                    val flight = TokenFlight()
                    flightProgress[token.kind] = flight
                    flight.lift.animateTo(1f, tween(124, easing = DECELERATE))
                    flight.fly.animateTo(1f, tween(496, easing = EMPHASIZED)) {
                        // 最后三成里圆牌淡掉、服务小块露出来：落上去的是它，不是一个凭空消失的点。
                        val fade = ((value - 0.7f) / 0.3f).coerceIn(0f, 1f)
                        latestTargets[token.kind]?.let { registry.alpha[it] = fade }
                    }
                    latestTargets[token.kind]?.let { registry.alpha.remove(it) }
                }
            }
        }
        ended = true
        onFinished()
    }
    if (ended) return

    BoxWithConstraints(
        Modifier
            .fillMaxSize()
            .onSizeChanged { size = it }
            .graphicsLayer { alpha = whole.value },
    ) {
        val width = constraints.maxWidth.toFloat()
        val height = constraints.maxHeight.toFloat()
        val art = min(
            min(width, height) * LaunchPocketGeometry.ART_FRACTION,
            with(density) { LaunchPocketGeometry.MAX_ART.toPx() },
        )
        val left = (width - art) / 2f
        val top = height / 2f - height * LaunchPocketGeometry.LIFT - art / 2f
        val unit = art / LaunchPocketGeometry.CANVAS
        // 起点：系统把启动图标画在 iconView 里，看得见的那个圆正好是 iconView 的边界（192dp），
        // 画面方框在圆里按 SPLASH_FIT 缩过（整只口袋落在圆里）。
        val splashIcon = iconBounds ?: if (systemSplash) {
            val side = with(density) { SPLASH_ICON.toPx() }
            Rect(Offset(width / 2f, height / 2f) - Offset(side / 2f, side / 2f), Size(side, side))
        } else {
            null
        }
        val restScale = splashIcon?.let { it.width * LaunchPocketGeometry.SPLASH_FIT / art } ?: 1f
        val restShift = splashIcon?.let { it.center - Offset(left + art / 2f, top + art / 2f) } ?: Offset.Zero
        val g = grow.value
        val artDp = with(density) { art.toDp() }

        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer { alpha = background.value }
                .background(colorResource(R.color.launch_background)),
        )
        Box(
            Modifier
                .offset { IntOffset(left.roundToInt(), top.roundToInt()) }
                .size(artDp)
                .graphicsLayer {
                    val scale = lerp(restScale, 1f, g)
                    scaleX = scale
                    scaleY = scale
                    translationX = lerp(restShift.x, 0f, g)
                    translationY = lerp(restShift.y, 0f, g)
                },
        ) {
            LaunchPocketGeometry.tokens.forEach { token ->
                val target = flights[token.kind]
                val flight = flightProgress[token.kind]
                val rest = Offset(token.x * unit, token.y * unit)
                val restSize = token.radius * 2f * unit
                val lifted = flight?.lift?.value ?: 0f
                val fly = flight?.fly?.value ?: 0f
                val from = rest - Offset(0f, lift * lifted)
                val fromSize = restSize * (1f + 0.08f * lifted)
                val center: Offset
                val size: Float
                if (target != null) {
                    center = Offset(
                        lerp(from.x, target.center.x - left, fly),
                        lerp(from.y, target.center.y - top, fly),
                    )
                    size = lerp(fromSize, target.width, fly)
                } else {
                    center = rest + Offset(0f, art * SINK * sink.value)
                    size = restSize
                }
                val alpha = if (target != null) 1f - ((fly - 0.7f) / 0.3f).coerceIn(0f, 1f) else 1f - sink.value
                Image(
                    painter = painterResource(token.drawable),
                    contentDescription = null,
                    contentScale = ContentScale.FillBounds,
                    modifier = Modifier
                        .offset { IntOffset((center.x - size / 2f).roundToInt(), (center.y - size / 2f).roundToInt()) }
                        .size(with(density) { size.toDp() })
                        .graphicsLayer { this.alpha = alpha },
                )
            }
            listOf(R.drawable.launch_pocket_cat, R.drawable.launch_pocket_front).forEach { layer ->
                Image(
                    painter = painterResource(layer),
                    contentDescription = null,
                    contentScale = ContentScale.FillBounds,
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer {
                            translationY = art * SINK * sink.value
                            alpha = 1f - sink.value
                        },
                )
            }
        }
    }
}

/** 一枚圆牌的两段：弹出口袋，再飞到落点。 */
private class TokenFlight {
    val lift = Animatable(0f)
    val fly = Animatable(0f)
}

private val LIFT = 14.dp
/** Android 12+ 系统启动图标看得见的那个圆（iconView 的边界），平台规定的尺寸。 */
private val SPLASH_ICON = 192.dp
private const val SINK = 0.28f
private val STANDARD = CubicBezierEasing(0.2f, 0f, 0f, 1f)
private val DECELERATE = CubicBezierEasing(0.05f, 0.7f, 0.1f, 1f)
private val ACCELERATE = CubicBezierEasing(0.3f, 0f, 0.8f, 0.15f)
private val EMPHASIZED = CubicBezierEasing(0.32f, 0.72f, 0f, 1f)

@Preview(name = "Launch Light", showSystemUi = true)
@Preview(name = "Launch Dark", showSystemUi = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun LaunchRevealOverlayPreview() {
    LaunchRevealOverlay(
        iconBounds = null,
        systemSplash = false,
        handedOver = true,
        targets = emptyMap(),
        registry = remember { LaunchSwatchRegistry() },
        showsDashboard = { false },
        onFinished = {},
        animates = false,
    )
}
