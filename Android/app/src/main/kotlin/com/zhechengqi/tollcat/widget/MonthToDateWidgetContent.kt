package com.zhechengqi.tollcat.widget

import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.color.ColorProviders
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.material3.ColorProviders as materialColorProviders
import androidx.glance.preview.ExperimentalGlancePreviewApi
import androidx.glance.preview.Preview
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.zhechengqi.tollcat.MainActivity
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.WidgetSnapshot
import com.zhechengqi.tollcat.dashboard.DashboardCatMood
import com.zhechengqi.tollcat.dashboard.art
import com.zhechengqi.tollcat.tollCatBrandScheme
import com.zhechengqi.tollcat.ui.ContrastTier
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatStillRenderer

@Composable
fun MonthToDateWidgetContent(payload: WidgetSnapshot.Payload) {
    val family = WidgetFamily.from(LocalSize.current)
    WidgetChrome {
        when {
            payload.empty -> EmptyWidgetBody(family)
            !payload.speaksCurrentMonth() -> StaleMonthBody(family, payload)
            else -> PopulatedWidgetBody(family, payload)
        }
    }
}

@Composable
private fun WidgetChrome(content: @Composable () -> Unit) {
    val context = LocalContext.current
    val colors = widgetColors(context)
    val open = actionStartActivity(
        Intent(Intent.ACTION_VIEW, android.net.Uri.parse("tollcat://dashboard"))
            .setClass(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
    )
    GlanceTheme(colors = colors) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.widgetBackground)
                .clickable(open)
                .padding(16.dp),
        ) {
            content()
        }
    }
}

@Composable
private fun PopulatedWidgetBody(family: WidgetFamily, payload: WidgetSnapshot.Payload) {
    val context = LocalContext.current
    val projected = projectedCaption(context, payload)
    val spoken = buildString {
        append(payload.monthTitle)
        append(' ')
        append(payload.formattedTotal)
        if (projected != null) {
            append(' ')
            append(projected)
        }
    }
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .semantics { contentDescription = spoken },
        verticalAlignment = Alignment.Top,
        horizontalAlignment = Alignment.Start,
    ) {
        MonthRow(payload.monthTitle, payload.catMood, family)
        Spacer(GlanceModifier.height(4.dp))
        Text(
            text = payload.formattedTotal,
            maxLines = 1,
            style = TextStyle(
                color = GlanceTheme.colors.onSurface,
                fontSize = if (family == WidgetFamily.Small) 26.sp else 32.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
        if (projected != null) {
            Spacer(GlanceModifier.height(2.dp))
            Text(
                text = projected,
                maxLines = 2,
                style = captionStyle(),
            )
        }
        if (family != WidgetFamily.Small) {
            Spacer(GlanceModifier.defaultWeight())
            if (payload.composition.isNotEmpty()) {
                CompositionBar(payload.composition)
                if (family == WidgetFamily.Large) {
                    Spacer(GlanceModifier.height(8.dp))
                    CompositionRows(payload.composition)
                }
                Spacer(GlanceModifier.height(6.dp))
            }
            payload.lastRefreshAtMillis?.let { fetchedAt ->
                Text(
                    text = WidgetRelativeTime.lastRefreshCaption(
                        context,
                        fetchedAt,
                        System.currentTimeMillis(),
                    ),
                    maxLines = 1,
                    style = captionStyle(),
                )
            }
        }
    }
}

@Composable
private fun EmptyWidgetBody(family: WidgetFamily) {
    val context = LocalContext.current
    val title = context.getString(R.string.dashboard_empty_title)
    val body = context.getString(R.string.widget_empty_body)
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .semantics { contentDescription = "$title。$body" },
        verticalAlignment = Alignment.Top,
        horizontalAlignment = Alignment.Start,
    ) {
        CatBadge(CatMood.Sleeping, family, context.getString(R.string.dashboard_cat_mood_sleeping))
        Spacer(GlanceModifier.height(8.dp))
        Text(
            text = title,
            maxLines = 2,
            style = TextStyle(
                color = GlanceTheme.colors.onSurface,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
        if (family != WidgetFamily.Small) {
            Spacer(GlanceModifier.height(4.dp))
            Text(text = body, maxLines = 3, style = captionStyle())
        }
    }
}

@Composable
private fun StaleMonthBody(family: WidgetFamily, payload: WidgetSnapshot.Payload) {
    val context = LocalContext.current
    val title = context.getString(R.string.widget_no_data)
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .semantics { contentDescription = title },
        verticalAlignment = Alignment.Top,
        horizontalAlignment = Alignment.Start,
    ) {
        MonthRow(payload.monthTitle.ifBlank { title }, payload.catMood, family)
        Spacer(GlanceModifier.height(8.dp))
        Text(
            text = title,
            maxLines = 2,
            style = TextStyle(
                color = GlanceTheme.colors.onSurface,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
    }
}

@Composable
private fun MonthRow(monthTitle: String, catMood: String, family: WidgetFamily) {
    val context = LocalContext.current
    val mood = catMoodOf(catMood)
    val moodLabel = context.getString(mood.labelRes)
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top,
    ) {
        Text(
            text = monthTitle,
            maxLines = 1,
            style = TextStyle(
                color = GlanceTheme.colors.onSurfaceVariant,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
            ),
            modifier = GlanceModifier.defaultWeight(),
        )
        CatBadge(mood.art, family, moodLabel)
    }
}

@Composable
private fun CatBadge(mood: CatMood, family: WidgetFamily, description: String) {
    val context = LocalContext.current
    val dark = isNight(context)
    val side = if (family == WidgetFamily.Small) 32.dp else 40.dp
    val px = (side.value * context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
    Image(
        provider = ImageProvider(CatStillRenderer.bitmap(mood, px, dark)),
        contentDescription = description,
        modifier = GlanceModifier.size(side),
        contentScale = ContentScale.Fit,
    )
}

@Composable
private fun CompositionBar(slices: List<WidgetComposition.Slice>) {
    val context = LocalContext.current
    val density = context.resources.displayMetrics.density
    val colors = slices.mapIndexed { index, slice ->
        compositionArgb(index, slice.isOther)
    }
    val bitmap = WidgetComposition.barBitmap(
        slices = slices,
        colors = colors,
        widthPx = (600 * density).toInt().coerceAtLeast(1),
        heightPx = (5 * density).toInt().coerceAtLeast(1),
        gapPx = (2 * density).toInt().coerceAtLeast(1),
    )
    Image(
        provider = ImageProvider(bitmap),
        contentDescription = null,
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(5.dp)
            .cornerRadius(2.dp),
        contentScale = ContentScale.FillBounds,
    )
}

@Composable
private fun CompositionRows(slices: List<WidgetComposition.Slice>) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        slices.forEachIndexed { index, slice ->
            if (index > 0) Spacer(GlanceModifier.height(4.dp))
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    modifier = GlanceModifier
                        .size(8.dp)
                        .cornerRadius(2.dp)
                        .background(ColorProvider(compositionArgb(index, slice.isOther))),
                ) {}
                Spacer(GlanceModifier.width(8.dp))
                Text(
                    text = slice.displayName,
                    maxLines = 1,
                    style = TextStyle(
                        color = GlanceTheme.colors.onSurface,
                        fontSize = 13.sp,
                    ),
                    modifier = GlanceModifier.defaultWeight(),
                )
                val trailing = slice.amount.ifBlank {
                    if (slice.percent > 0) "${slice.percent}%" else ""
                }
                if (trailing.isNotBlank()) {
                    Spacer(GlanceModifier.width(8.dp))
                    Text(
                        text = trailing,
                        maxLines = 1,
                        style = TextStyle(
                            color = GlanceTheme.colors.onSurfaceVariant,
                            fontSize = 13.sp,
                        ),
                    )
                }
            }
        }
    }
}

@Composable
private fun captionStyle(): TextStyle = TextStyle(
    color = GlanceTheme.colors.onSurfaceVariant,
    fontSize = 12.sp,
)

@Composable
private fun compositionArgb(index: Int, isOther: Boolean): Int {
    val context = LocalContext.current
    if (isOther) return GlanceTheme.colors.outline.getColor(context).toArgb()
    val base = when (index % 5) {
        0 -> GlanceTheme.colors.primary
        1 -> GlanceTheme.colors.tertiary
        2 -> GlanceTheme.colors.secondary
        3 -> GlanceTheme.colors.primary
        else -> GlanceTheme.colors.tertiary
    }.getColor(context)
    val color = if (index % 5 >= 3) base.copy(alpha = 0.45f) else base
    return color.toArgb()
}

private fun projectedCaption(context: android.content.Context, payload: WidgetSnapshot.Payload): String? {
    if (payload.allowsProjection) {
        val amount = payload.formattedProjected
        if (amount.isNotBlank() && amount != "—") {
            return context.getString(R.string.projected_caption, amount)
        }
    }
    val period = payload.periodCaption
    if (period.isNotBlank() && period != payload.monthTitle) return period
    return null
}

private fun catMoodOf(raw: String): DashboardCatMood {
    return DashboardCatMood.entries.firstOrNull { it.raw.equals(raw, ignoreCase = true) }
        ?: DashboardCatMood.Normal
}

private fun isNight(context: android.content.Context): Boolean {
    val night = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
    return night == Configuration.UI_MODE_NIGHT_YES
}

private fun widgetColors(context: android.content.Context): ColorProviders {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        materialColorProviders(
            light = dynamicLightColorScheme(context),
            dark = dynamicDarkColorScheme(context),
        )
    } else {
        materialColorProviders(
            light = tollCatBrandScheme(dark = false, contrast = ContrastTier.Standard),
            dark = tollCatBrandScheme(dark = true, contrast = ContrastTier.Standard),
        )
    }
}

@OptIn(ExperimentalGlancePreviewApi::class)
@Preview(widthDp = 170, heightDp = 170)
@Composable
private fun MonthToDateWidgetSmallPreview() {
    MonthToDateWidgetContent(WidgetSnapshot.designSpec)
}

@OptIn(ExperimentalGlancePreviewApi::class)
@Preview(widthDp = 364, heightDp = 170)
@Composable
private fun MonthToDateWidgetMediumPreview() {
    MonthToDateWidgetContent(WidgetSnapshot.designSpec)
}

@OptIn(ExperimentalGlancePreviewApi::class)
@Preview(widthDp = 364, heightDp = 382)
@Composable
private fun MonthToDateWidgetLargePreview() {
    MonthToDateWidgetContent(WidgetSnapshot.designSpec)
}
