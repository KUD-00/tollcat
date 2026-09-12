package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.zhechengqi.tollcat.dashboard.DashboardCatMood

/** 画廊里拧猫。预设换脸；尺寸单独拧。没有 iOS 高级页那么全。 */
class GalleryCatStudio {
    var mood by mutableStateOf(DashboardCatMood.Normal)
    var sizeDp by mutableFloatStateOf(180f)

    fun apply(mood: DashboardCatMood) {
        this.mood = mood
    }
}
