// GENERATED — scripts/render-app-icon.py（猫的几何来自 shared/cat.json）。改脚本再跑，不要手改。
package com.zhechengqi.tollcat.launch

import com.zhechengqi.tollcat.R

/** 启动画面里三枚服务圆牌的位置（1024 见方，画面贴底、和屏幕一样宽）。顺序就是叠放顺序。 */
internal object LaunchPocketGeometry {
    const val CANVAS = 1024f
    val tokens = listOf(
        LaunchPocketToken("database", 926.0f, 475.8f, 75.9f, R.drawable.launch_token_database),
        LaunchPocketToken("cloud", 125.6f, 531.0f, 115.0f, R.drawable.launch_token_cloud),
        LaunchPocketToken("ai", 893.8f, 531.0f, 103.5f, R.drawable.launch_token_ai),
    )
}
