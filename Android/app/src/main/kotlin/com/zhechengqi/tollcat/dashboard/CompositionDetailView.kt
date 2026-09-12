package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun CompositionDetailView(
    rows: List<CompositionRow>,
    onBack: () -> Unit,
    onOpenProvider: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val otherLabel = stringResource(R.string.dashboard_composition_other)
    val slices = compositionSlices(rows, otherLabel)
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.module_composition)) },
                navigationIcon = {
                    IconButton(
                        onClick = onBack,
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(
                            MaterialSymbol.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                },
            )
        },
    ) { inner ->
        LazyColumn(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize(),
            contentPadding = PaddingValues(horizontal = MeterSpacing.md, vertical = MeterSpacing.xs),
            verticalArrangement = Arrangement.spacedBy(Bento.gap),
        ) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = MeterSpacing.md),
                    contentAlignment = Alignment.Center,
                ) {
                    CompositionDonut(slices = slices)
                }
            }
            itemsIndexed(rows, key = { index, row -> "${row.accountId}-${row.providerId}-$index" }) { index, row ->
                val hint = stringResource(R.string.dashboard_view_provider, row.displayName)
                DashboardInsightRow(
                    title = row.displayName,
                    glyphKey = (row.colorKey.ifBlank { row.providerId }).takeIf { it.isNotBlank() },
                    subtitle = "${row.percent}%",
                    trailingText = row.amount,
                    spokenLabel = "${row.displayName}，${row.amount}",
                    onClick = dashboardOpenAction(row.accountId, row.providerId, onOpenProvider),
                    modifier = Modifier
                        .clip(Bento.groupShape(first = index == 0, last = index == rows.lastIndex))
                        .background(MaterialTheme.colorScheme.surfaceContainer)
                        .semantics { contentDescription = hint },
                )
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CompositionDetailViewPreview() {
    TollCatTheme {
        CompositionDetailView(
            rows = DashboardPreviewData.snapshot.composition.mapIndexed { index, row ->
                row.copy(accountId = "acct-$index")
            },
            onBack = {},
            onOpenProvider = {},
        )
    }
}
