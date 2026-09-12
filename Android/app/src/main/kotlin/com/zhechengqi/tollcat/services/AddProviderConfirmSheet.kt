package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CatalogField
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.TollCatSheet
import com.zhechengqi.tollcat.ui.UITestId

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AddProviderConfirmSheet(
    provider: CatalogProvider,
    onAdd: () -> Unit,
    onDismiss: () -> Unit,
) {
    TollCatSheet(onDismiss = onDismiss) {
        AddProviderConfirmContent(
            provider = provider,
            onAdd = onAdd,
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp, vertical = 8.dp),
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun AddProviderConfirmContent(
    provider: CatalogProvider,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val addLabel = stringResource(R.string.services_add_named, provider.displayName)
    val addSpoken = stringResource(R.string.action_add_service)
    Column(
        modifier = modifier.verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        ServiceGlyph(
            name = provider.displayName,
            colorKey = provider.colorKey.ifBlank { provider.id },
            size = 72.dp,
        )
        if (provider.summary.isNotBlank()) {
            Spacer(Modifier.height(20.dp))
            Text(
                text = provider.summary,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
            )
        }
        Spacer(Modifier.height(20.dp))
        PrimaryButton(
            onClick = onAdd,
            modifier = Modifier
                .fillMaxWidth()
                .semantics { contentDescription = addSpoken }
                .testTag(UITestId.ADD_PROVIDER_CONFIRM),
        ) {
            Text(addLabel)
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun AddProviderConfirmPreview() {
    TollCatTheme {
        AddProviderConfirmContent(
            provider = CatalogProvider(
                id = "openai",
                displayName = "OpenAI",
                kind = "prepaid",
                category = "aiInference",
                tier = 1,
                tierReason = "",
                colorKey = "openai",
                costsMoneyToRefresh = false,
                supportsInbox = false,
                hasLiveFetch = true,
                summary = "GPT 等模型的 API 平台。预充值，按 token 扣余额。",
                searchKeywords = emptyList(),
                accessStatus = "available",
                declineReason = "",
                supportsDailyGranularity = true,
                historyLookbackMonths = 0,
                billingURL = "",
                credentialSetupURL = "",
                fields = emptyList<CatalogField>(),
            ),
            onAdd = {},
            modifier = Modifier.padding(24.dp),
        )
    }
}
