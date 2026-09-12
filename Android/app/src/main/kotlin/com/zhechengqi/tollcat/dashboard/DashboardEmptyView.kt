package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.CatNestGlyph
import com.zhechengqi.tollcat.ui.EmptyState
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.PersistenceNoticeList
import com.zhechengqi.tollcat.ui.PersistenceStatus
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.cat.CatMood

@Composable
fun DashboardEmptyView(
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
    didClearAllData: Boolean = false,
    persistenceStatus: PersistenceStatus = PersistenceStatus(),
    onDismissDemo: (() -> Unit)? = null,
) {
    val sleepingSpoken = stringResource(R.string.dashboard_cat_mood_sleeping)
    val addSpoken = stringResource(R.string.dashboard_empty_action)
    Box(
        modifier = modifier.testTag(UITestId.DASHBOARD_EMPTY),
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.CenterStart,
        ) {
            EmptyState(
                title = stringResource(
                    if (didClearAllData) {
                        R.string.dashboard_empty_cleared_title
                    } else {
                        R.string.dashboard_empty_title
                    },
                ),
                body = stringResource(
                    if (didClearAllData) {
                        R.string.dashboard_empty_cleared_body
                    } else {
                        R.string.dashboard_empty_body
                    },
                ),
                actionLabel = stringResource(R.string.dashboard_empty_action),
                onAction = onAdd,
                actionModifier = Modifier.semantics { contentDescription = addSpoken },
                glyph = {
                    CatNestGlyph(
                        mood = CatMood.Sleeping,
                        spokenDescription = sleepingSpoken,
                    )
                },
            )
        }
        PersistenceNoticeList(
            status = persistenceStatus,
            onDismissDemo = onDismissDemo,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(horizontal = MeterSpacing.pageHorizontal)
                .padding(top = MeterSpacing.md),
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardEmptyViewPreview() {
    TollCatTheme {
        DashboardEmptyView(onAdd = {}, modifier = Modifier.fillMaxSize())
    }
}

@Preview(name = "Cleared Light", showBackground = true)
@Preview(name = "Cleared Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardEmptyViewClearedPreview() {
    TollCatTheme {
        DashboardEmptyView(onAdd = {}, didClearAllData = true, modifier = Modifier.fillMaxSize())
    }
}

@Preview(name = "Demo Light", showBackground = true)
@Preview(name = "Demo Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardEmptyViewDemoPreview() {
    TollCatTheme {
        DashboardEmptyView(
            onAdd = {},
            persistenceStatus = PersistenceStatus(containsDemoData = true),
            onDismissDemo = {},
            modifier = Modifier.fillMaxSize(),
        )
    }
}
