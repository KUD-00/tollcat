package com.zhechengqi.tollcat.launch

import androidx.annotation.DrawableRes

/**
 * 启动画面里的一枚服务圆牌：[kind] 和共享层 `LaunchTokenKind` 的 rawValue 一致，
 * 位置在 1024 见方的画面空间里，[drawable] 是这一枚单独的分层图。
 */
internal data class LaunchPocketToken(
    val kind: String,
    val x: Float,
    val y: Float,
    val radius: Float,
    @param:DrawableRes val drawable: Int,
)
