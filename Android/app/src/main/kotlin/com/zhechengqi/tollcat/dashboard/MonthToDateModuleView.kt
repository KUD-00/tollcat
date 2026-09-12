package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.AmountText
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.UITestId

@OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalLayoutApi::class)
@Composable
fun MonthToDateModuleView(
    amountText: String,
    monthTitle: String,
    projectedCaption: String?,
    subscriptionCaption: String?,
    currencyNote: String?,
    filterNote: String?,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
    includesSubscriptions: Boolean = false,
    onToggleSubscriptions: ((Boolean) -> Unit)? = null,
    onSelectSubscription: (() -> Unit)? = null,
    staleCaption: String? = null,
) {
    val spoken = stringResource(R.string.dashboard_month_to_date_a11y, amountText)
    val toggleSubscriptions = onToggleSubscriptions
    Surface(
        color = MaterialTheme.colorScheme.primaryContainer,
        contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
        shape = shape,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(horizontal = MeterSpacing.xl, vertical = MeterSpacing.xl),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        ) {
            if (monthTitle.isNotBlank()) {
                Text(
                    text = monthTitle,
                    style = MaterialTheme.typography.titleMediumEmphasized,
                )
            }
            if (toggleSubscriptions != null && !subscriptionCaption.isNullOrBlank()) {
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
                    verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
                    itemVerticalAlignment = Alignment.CenterVertically,
                ) {
                    AmountText(
                        text = amountText,
                        style = MaterialTheme.typography.displayLargeEmphasized,
                        modifier = Modifier
                            .semantics { contentDescription = spoken }
                            .testTag(UITestId.DASHBOARD_TOTAL),
                    )
                    SubscriptionScopeControl(
                        includesSubscriptions = includesSubscriptions,
                        onChange = toggleSubscriptions,
                    )
                }
            } else {
                AmountText(
                    text = amountText,
                    style = MaterialTheme.typography.displayLargeEmphasized,
                    modifier = Modifier
                        .semantics { contentDescription = spoken }
                        .testTag(UITestId.DASHBOARD_TOTAL),
                )
            }
            projectedCaption?.let { caption ->
                Text(caption, style = MaterialTheme.typography.bodyLarge)
            }
            subscriptionCaption?.let { caption ->
                if (onSelectSubscription != null) {
                    Text(
                        text = caption,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = MeterSpacing.minTap)
                            .clickable(onClick = onSelectSubscription)
                            .semantics { role = Role.Button },
                    )
                } else {
                    Text(caption, style = MaterialTheme.typography.bodyMedium)
                }
            }
            currencyNote?.let { note ->
                Text(
                    note,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            filterNote?.let { note ->
                val spokenNote = stringResource(R.string.dashboard_filter_active, note)
                Text(
                    text = note,
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.semantics { contentDescription = spokenNote },
                )
            }
            staleCaption?.let { caption ->
                Text(
                    caption,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                )
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun MonthToDateModuleViewPreview() {
    TollCatTheme {
        MonthToDateModuleView(
            amountText = "$47.20",
            monthTitle = "",
            projectedCaption = "预计月底 $87.70",
            subscriptionCaption = "本月订阅 $4.00 · 已计入",
            currencyNote = null,
            filterNote = null,
            includesSubscriptions = true,
            onToggleSubscriptions = {},
            onSelectSubscription = {},
        )
    }
}

@Preview(name = "Stale Light", showBackground = true)
@Preview(name = "Stale Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun MonthToDateModuleViewStalePreview() {
    TollCatTheme {
        MonthToDateModuleView(
            amountText = "$47.20",
            monthTitle = "",
            projectedCaption = "预计月底 $87.70",
            subscriptionCaption = null,
            currencyNote = null,
            filterNote = "排除 AWS",
            staleCaption = "部分数据陈旧，仍显示上次成功的数字",
        )
    }
}
