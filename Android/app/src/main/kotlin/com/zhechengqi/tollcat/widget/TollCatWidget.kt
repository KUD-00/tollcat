package com.zhechengqi.tollcat.widget

import android.content.Context
import androidx.compose.ui.unit.DpSize
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import com.zhechengqi.tollcat.WidgetSnapshot

/**
 * 主屏本月合计。三种尺寸结构不同，只读 [WidgetSnapshot]，
 * 不加载 JNI、不打账单接口。
 */
class TollCatWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Responsive(
        setOf(WidgetFamily.smallSize, WidgetFamily.mediumSize, WidgetFamily.largeSize),
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val payload = WidgetSnapshot.read(context)
        provideContent {
            MonthToDateWidgetContent(payload)
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        provideContent {
            MonthToDateWidgetContent(WidgetSnapshot.designSpec)
        }
    }

    companion object {
        val sizes: Set<DpSize> = setOf(
            WidgetFamily.smallSize,
            WidgetFamily.mediumSize,
            WidgetFamily.largeSize,
        )
    }
}
