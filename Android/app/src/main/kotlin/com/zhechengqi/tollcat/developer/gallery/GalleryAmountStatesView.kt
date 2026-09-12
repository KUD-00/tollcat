package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.CompositionDonut
import com.zhechengqi.tollcat.dashboard.MonthToDateModuleView
import com.zhechengqi.tollcat.developer.GalleryFixtures
import com.zhechengqi.tollcat.ui.PrimaryButton
import kotlinx.coroutines.delay

@Composable
fun GalleryAmountStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var amountIndex by remember { mutableIntStateOf(0) }
    var compositionReveal by remember { mutableIntStateOf(0) }
    var autoCycles by remember { mutableStateOf(false) }
    val amounts = listOf("$9.99", "$67.20", "$1,234.56", "$1,234,567.89", "$0.00", "-$12.34")
    val projected = listOf("$20.00", "$94.00", "$2,400.00", "$2,000,000.00", "$0.00", "-$20.00")
    LaunchedEffect(autoCycles) {
        if (!autoCycles) return@LaunchedEffect
        while (true) {
            delay(2000)
            amountIndex = (amountIndex + 1) % amounts.size
        }
    }
    GalleryScaffold(title = stringResource(R.string.dev_gallery_amounts), onBack = onBack, modifier = modifier) {
        Text(stringResource(R.string.dev_gallery_amount_cycle), style = MaterialTheme.typography.titleSmall)
        MonthToDateModuleView(
            amountText = amounts[amountIndex],
            monthTitle = stringResource(R.string.hero_label),
            projectedCaption = stringResource(R.string.projected_caption, projected[amountIndex]),
            subscriptionCaption = null,
            currencyNote = null,
            filterNote = null,
        )
        Spacer(Modifier.height(8.dp))
        PrimaryButton(
            onClick = { amountIndex = (amountIndex + 1) % amounts.size },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.dev_gallery_next_amount))
        }
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            Text("自动循环", style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
            Switch(checked = autoCycles, onCheckedChange = { autoCycles = it })
        }
        Spacer(Modifier.height(8.dp))
        Text(
            stringResource(R.string.dev_gallery_amount_cycle_note),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(16.dp))
        Text("圆环进场", style = MaterialTheme.typography.titleSmall)
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            key(compositionReveal) {
                CompositionDonut(slices = GalleryFixtures.specComposition)
            }
        }
        Spacer(Modifier.height(8.dp))
        PrimaryButton(
            onClick = { compositionReveal += 1 },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("再转一次")
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryAmountStatesViewPreview() {
    TollCatTheme {
        GalleryAmountStatesView(onBack = {})
    }
}
