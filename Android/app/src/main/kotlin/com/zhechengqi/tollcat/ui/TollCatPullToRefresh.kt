package com.zhechengqi.tollcat.ui

import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Velocity
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop

/**
 * 全 App 唯一的下拉刷新。和 M3 默认的 `PullToRefreshBox` 有两处不同：
 *
 * 1. **只认从顶上开始的那一下拉。** M3 默认会把「内容滚到顶以后剩下的拖动」接着算成下拉——
 *    从页面中间往回一划，滚到顶那一刻起就开始攒刷新距离，常常一划就刷新了。这里同一次拖动里
 *    内容只要动过，剩下那截就不交给刷新。刷新会真去打各家账单接口（AWS 每次要花钱），
 *    误触不只是体验问题。
 * 2. **拉过阈值给一下触感。** `GestureThresholdActivate` 就是平台给「越过阈值、松手生效」
 *    这类手势准备的；拉回去再给一下 `Deactivate`。松手会不会刷新，手上就知道。
 *
 * 阈值保持 M3 默认（80dp，手指位移打五折，约 160dp）——实测在顶上直接拉 420px 不触发、520px 触发。
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TollCatPullToRefreshBox(
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    val state = rememberPullToRefreshState()
    val gate = remember { PullFromTopGate() }
    val haptics = LocalHapticFeedback.current
    val view = LocalView.current
    val refreshing by rememberUpdatedState(isRefreshing)
    LaunchedEffect(state) {
        snapshotFlow { state.distanceFraction >= 1f }
            .distinctUntilChanged()
            .drop(1)
            .collect { crossed ->
                // 刷新中指示器停在阈值位、刷新完收回去，都是动画，不是手在拉：不震。
                if (refreshing || state.isAnimating) return@collect
                if (crossed) {
                    haptics.performHapticFeedback(HapticFeedbackType.GestureThresholdActivate)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    // Compose 只封装了 Activate；拉回阈值以下那一下走平台常量（Android 14 起才有）。
                    view.performHapticFeedback(HapticFeedbackConstants.GESTURE_THRESHOLD_DEACTIVATE)
                }
            }
    }
    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = onRefresh,
        modifier = modifier,
        state = state,
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .pointerInput(gate) {
                    awaitEachGesture {
                        awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
                        gate.reset()
                    }
                }
                .nestedScroll(gate),
        ) {
            content()
        }
    }
}

/**
 * 夹在内容和下拉刷新之间的一道闸：这一次拖动里内容滚过，往下剩的位移就自己吃掉，
 * 不再往外交给刷新。手指按下时重置（[TollCatPullToRefreshBox] 里的 pointerInput），
 * 惯性滑完也重置。
 */
private class PullFromTopGate : NestedScrollConnection {
    private var contentScrolled = false

    fun reset() {
        contentScrolled = false
    }

    override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
        if (source != NestedScrollSource.UserInput) return Offset.Zero
        if (consumed.y != 0f) contentScrolled = true
        return if (contentScrolled && available.y > 0f) Offset(0f, available.y) else Offset.Zero
    }

    override suspend fun onPostFling(consumed: Velocity, available: Velocity): Velocity {
        contentScrolled = false
        return Velocity.Zero
    }
}
