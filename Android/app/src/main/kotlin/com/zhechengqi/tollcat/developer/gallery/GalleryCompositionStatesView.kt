package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.dashboard.CompositionModuleView
import com.zhechengqi.tollcat.developer.GalleryFixtures

@Composable
fun GalleryCompositionStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(title = stringResource(R.string.module_composition), onBack = onBack, modifier = modifier) {
        block(stringResource(R.string.dev_comp_1), GalleryFixtures.composition(listOf(Triple("aws", "AWS", "$100.00" to 100))))
        block(
            stringResource(R.string.dev_comp_2),
            GalleryFixtures.composition(
                listOf(
                    Triple("aws", "AWS", "$70.00" to 70),
                    Triple("cloudflare", "Cloudflare", "$30.00" to 30),
                ),
            ),
        )
        block(stringResource(R.string.dev_comp_5), GalleryFixtures.specComposition)
        block(stringResource(R.string.dev_comp_8), GalleryFixtures.eightProviderComposition)
        block(
            stringResource(R.string.dev_comp_100),
            GalleryFixtures.composition(listOf(Triple("openai", "OpenAI", "$100.00" to 100))),
        )
    }
}

@Composable
private fun block(title: String, rows: List<CompositionRow>) {
    Spacer(Modifier.height(12.dp))
    Text(title, style = MaterialTheme.typography.titleSmall)
    CompositionModuleView(rows = rows, onOpen = {})
}
