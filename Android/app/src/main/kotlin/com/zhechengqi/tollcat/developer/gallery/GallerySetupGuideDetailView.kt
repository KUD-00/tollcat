package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.SetupGuideDoc
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.setup.SetupGuideStep
import com.zhechengqi.tollcat.setup.previewCatalogProvider

@Composable
fun GallerySetupGuideDetailView(
    provider: CatalogProvider,
    guide: SetupGuideDoc?,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = provider.displayName,
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SetupGuideStep(provider, guide)
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GallerySetupGuideDetailViewPreview() {
    TollCatTheme {
        GallerySetupGuideDetailView(
            provider = previewCatalogProvider(),
            guide = null,
            onBack = {},
        )
    }
}
