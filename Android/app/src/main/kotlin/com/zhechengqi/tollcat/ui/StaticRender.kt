package com.zhechengqi.tollcat.ui

import androidx.compose.runtime.staticCompositionLocalOf

/**
 * 这一趟组合是在渲成图（分享卡），不是给人点的。和 iOS 的 `meterStaticRender` 同一个用意：
 *
 * - 点得动才有意义的装饰收掉（卡头的箭头钮、横幅的圆形箭头）——图上点不了，留着是误导；
 * - 横滑的一排改成换行排——图只有一帧，屏幕外的那几张不会被画出来；
 * - 入场动画直接到位：渲图的同时还提供 [LocalReduceMotion] = true。
 */
val LocalStaticRender = staticCompositionLocalOf { false }
