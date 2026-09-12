package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing

/** 大数字旁的口径切换：合计 / 按量。订阅不算筛选。 */
@Composable
fun SubscriptionScopeControl(
    includesSubscriptions: Boolean,
    onChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val spoken = stringResource(R.string.dashboard_filter_include_subscriptions)
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceContainerHighest)
            .padding(MeterSpacing.xxs)
            .heightIn(min = MeterSpacing.minTap)
            .semantics(mergeDescendants = true) {
                role = Role.Switch
                toggleableState = if (includesSubscriptions) ToggleableState.On else ToggleableState.Off
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ScopeSegment(
            title = stringResource(R.string.dashboard_scope_total),
            selected = includesSubscriptions,
            onClick = { if (!includesSubscriptions) onChange(true) },
        )
        ScopeSegment(
            title = stringResource(R.string.dashboard_scope_variable),
            selected = !includesSubscriptions,
            onClick = { if (includesSubscriptions) onChange(false) },
        )
    }
}

@Composable
private fun ScopeSegment(
    title: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val shape = CircleShape
    Surface(
        color = if (selected) MaterialTheme.colorScheme.surface else MaterialTheme.colorScheme.surfaceContainerHighest,
        contentColor = if (selected) {
            MaterialTheme.colorScheme.onSurface
        } else {
            MaterialTheme.colorScheme.onSurfaceVariant
        },
        shape = shape,
        modifier = Modifier
            .clip(shape)
            .clickable(onClick = onClick)
            .padding(horizontal = MeterSpacing.sm, vertical = MeterSpacing.xxs),
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(title, style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SubscriptionScopeControlPreview() {
    TollCatTheme {
        SubscriptionScopeControl(includesSubscriptions = false, onChange = {})
    }
}
