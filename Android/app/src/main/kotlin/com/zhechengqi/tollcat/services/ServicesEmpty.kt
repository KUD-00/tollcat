package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
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
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.cat.CatMood

@Composable
fun ServicesEmpty(onAdd: () -> Unit, modifier: Modifier = Modifier) {
    val catSpoken = stringResource(R.string.dashboard_cat_mood_normal)
    val addSpoken = stringResource(R.string.action_add_service)
    Box(
        modifier = modifier.testTag(UITestId.SERVICES_EMPTY),
        contentAlignment = Alignment.CenterStart,
    ) {
        EmptyState(
            title = stringResource(R.string.services_empty_title),
            body = stringResource(R.string.services_empty_body),
            actionLabel = stringResource(R.string.action_add_service),
            onAction = onAdd,
            actionModifier = Modifier
                .semantics { contentDescription = addSpoken }
                .testTag(UITestId.SERVICES_EMPTY_ADD),
            glyph = {
                CatNestGlyph(
                    mood = CatMood.Normal,
                    spokenDescription = catSpoken,
                )
            },
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ServicesEmptyPreview() {
    TollCatTheme {
        ServicesEmpty(onAdd = {}, modifier = Modifier.fillMaxSize())
    }
}
