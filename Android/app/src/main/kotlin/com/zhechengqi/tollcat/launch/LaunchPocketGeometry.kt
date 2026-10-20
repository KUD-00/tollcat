// GENERATED — scripts/render-app-icon.py（猫的几何来自 shared/cat.json）。改脚本再跑，不要手改。
package com.zhechengqi.tollcat.launch

import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R

/**
 * 启动画面的几何（1024 见方的画面空间）。启动画面的方框：居中，边长 = min(屏宽, 屏高) × 0.5，最大 280，再往上提屏高的 0.04。故事板、两端覆盖层都按这条摆。
 * 圆牌顺序就是叠放顺序。
 */
internal object LaunchPocketGeometry {
    const val CANVAS = 1024f
    const val ART_FRACTION = 0.5f
    val MAX_ART = 280.dp
    const val LIFT = 0.04f
    /** 系统启动图标里，画面方框占那个 192dp 圆的比例（内容离圆心最远的点刚好落在圆里）。 */
    const val SPLASH_FIT = 0.7596f
    val tokens = listOf(
        LaunchPocketToken("database", 901.21f, 368.26f, 58.17f, R.drawable.launch_token_database),
        LaunchPocketToken("cloud", 192.43f, 158.32f, 93.41f, R.drawable.launch_token_cloud),
        LaunchPocketToken("ai", 820.32f, 148.69f, 86.67f, R.drawable.launch_token_ai),
    )
}
