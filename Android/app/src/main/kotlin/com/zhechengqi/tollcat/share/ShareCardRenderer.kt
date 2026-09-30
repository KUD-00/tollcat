package com.zhechengqi.tollcat.share

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.unit.Density
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.AppearanceMode
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.LocalStaticRender
import kotlinx.coroutines.android.awaitFrame
import kotlin.math.roundToInt

/**
 * 把一段 Compose 离屏渲成位图——分享卡用的是仪表盘上**同一批组件**，所以不能再用
 * Canvas 手画一张（那样仪表盘一改样子，图就和它对不上）。
 *
 * - 倍率钉死 2.5：432dp 的卡正好 1080 像素宽，和 iOS 分享卡同一个尺寸，不随手机密度变。
 * - 高度不封顶：先按内容量（高度不限），再按量出来的高度画。挂在窗口上时父布局只给一屏高，
 *   直接截会把下半张切掉。
 * - 浅色主题、静态渲染（收掉点得动的装饰、入场动画直接到位）：图只有一帧，
 *   深色底发到聊天里也不好看——和 iOS 渲图时压浅色 trait 同一个取舍。
 */
object ShareCardRenderer {
    private const val SCALE = 2.5f

    suspend fun render(activity: Activity, content: @Composable () -> Unit): Bitmap {
        val widthPx = (ShareCardWidth.value * SCALE).roundToInt()
        val root = activity.window.decorView as ViewGroup
        val view = ComposeView(activity).apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindow)
            // 挂在窗口上才能组合（要窗口的 lifecycle / saved-state owner），但不让人看见。
            visibility = View.INVISIBLE
            setContent {
                CompositionLocalProvider(LocalDensity provides Density(SCALE, fontScale = 1f)) {
                    TollCatTheme(appearance = AppearanceMode.Light) {
                        CompositionLocalProvider(
                            LocalStaticRender provides true,
                            LocalReduceMotion provides true,
                        ) {
                            content()
                        }
                    }
                }
            }
        }
        root.addView(view, FrameLayout.LayoutParams(widthPx, ViewGroup.LayoutParams.WRAP_CONTENT))
        try {
            // 两帧：第一帧组合，第二帧让 LaunchedEffect（入场动画的 snapTo）跑完。
            awaitFrame()
            awaitFrame()
            view.measure(
                View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY),
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
            )
            view.layout(0, 0, view.measuredWidth, view.measuredHeight)
            val bitmap = Bitmap.createBitmap(view.measuredWidth, view.measuredHeight, Bitmap.Config.ARGB_8888)
            view.draw(Canvas(bitmap))
            return bitmap
        } finally {
            root.removeView(view)
        }
    }
}
