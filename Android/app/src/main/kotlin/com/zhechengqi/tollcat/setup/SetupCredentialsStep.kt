package com.zhechengqi.tollcat.setup

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateMap
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.CatalogField
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.StatusBanner
import com.zhechengqi.tollcat.ui.StatusTone
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

@Composable
fun SetupCredentialsStep(
    fields: List<CatalogField>,
    values: SnapshotStateMap<String, String>,
    fieldErrors: Map<String, String>,
    outcome: SetupVerifyOutcome?,
    onEdited: () -> Unit,
    onExplainKeystore: () -> Unit,
    modifier: Modifier = Modifier,
    onRevisePermissions: (() -> Unit)? = null,
    collisionReason: String? = null,
    saveFailed: Boolean = false,
    showsNickname: Boolean = false,
    siblingNickname: String = "",
    onSiblingNicknameChange: (String) -> Unit = {},
    newNickname: String = "",
    onNewNicknameChange: (String) -> Unit = {},
) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = MeterSpacing.md, vertical = MeterSpacing.xs),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
    ) {
        Text(
            text = stringResource(R.string.services_credentials_header),
            style = MaterialTheme.typography.titleMedium,
        )
        fields.forEach { field ->
            val error = fieldErrors[field.key]
            TextField(
                value = values[field.key].orEmpty(),
                onValueChange = {
                    values[field.key] = it
                    onEdited()
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text(field.label) },
                supportingText = {
                    when {
                        error != null -> Text(error)
                        field.hint.isNotBlank() -> Text(field.hint)
                    }
                },
                isError = error != null,
                singleLine = true,
                visualTransformation = if (field.isSecret) {
                    PasswordVisualTransformation()
                } else {
                    VisualTransformation.None
                },
                trailingIcon = {
                    TextButton(
                        onClick = {
                            pasteClipboard(context)?.let { clip ->
                                values[field.key] = clip
                                onEdited()
                            }
                        },
                    ) {
                        Text(stringResource(R.string.action_paste))
                    }
                },
            )
        }
        collisionReason?.let { reason ->
            StatusBanner(
                title = reason,
                symbol = MaterialSymbol.Error,
                tone = StatusTone.Error,
            )
        }
        if (saveFailed) {
            StatusBanner(
                title = stringResource(R.string.setup_keystore_write_failed),
                symbol = MaterialSymbol.Error,
                tone = StatusTone.Error,
            )
        }
        if (collisionReason == null) {
            outcome?.let { SetupVerifyResultView(it, onRevisePermissions = onRevisePermissions) }
        }
        if (showsNickname && outcome?.isSuccess == true && collisionReason == null) {
            Text(
                text = stringResource(R.string.services_nickname_header),
                style = MaterialTheme.typography.titleMedium,
            )
            TextField(
                value = siblingNickname,
                onValueChange = onSiblingNicknameChange,
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.services_nickname_existing)) },
                singleLine = true,
            )
            TextField(
                value = newNickname,
                onValueChange = onNewNicknameChange,
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.services_nickname_new)) },
                singleLine = true,
            )
            Text(
                text = stringResource(R.string.services_nickname_footer),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (outcome?.isSuccess != true && collisionReason == null) {
            Text(
                text = stringResource(R.string.services_test_hint),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        TextButton(onClick = onExplainKeystore) {
            Text("${stringResource(R.string.services_keystore_caption)} ${stringResource(R.string.services_keystore_what)}")
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupCredentialsStepPreview() {
    val values = remember {
        mutableStateMapOf("apiToken" to "", "accountID" to "")
    }
    TollCatTheme {
        SetupCredentialsStep(
            fields = listOf(
                CatalogField("apiToken", "API Token", isSecret = true),
                CatalogField("accountID", "Account ID"),
            ),
            values = values,
            fieldErrors = mapOf("apiToken" to "请填写API Token"),
            outcome = SetupVerifyOutcome.EmptyReading,
            onEdited = {},
            onExplainKeystore = {},
            onRevisePermissions = {},
        )
    }
}

@Preview(name = "Nickname Light", showBackground = true)
@Preview(name = "Nickname Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupCredentialsNicknamePreview() {
    val values = remember {
        mutableStateMapOf("apiToken" to "cf-token", "accountID" to "abc")
    }
    TollCatTheme {
        SetupCredentialsStep(
            fields = listOf(
                CatalogField("apiToken", "API Token", isSecret = true),
                CatalogField("accountID", "Account ID"),
            ),
            values = values,
            fieldErrors = emptyMap(),
            outcome = SetupVerifyOutcome.Success("本周期至今 $11.05", "周期 8/1 – 8/31 · 日粒度可用"),
            onEdited = {},
            onExplainKeystore = {},
            showsNickname = true,
            siblingNickname = "账号 1",
            newNickname = "",
        )
    }
}

@Preview(name = "Collision Light", showBackground = true)
@Preview(name = "Collision Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupCredentialsCollisionPreview() {
    val values = remember {
        mutableStateMapOf("apiToken" to "••••", "accountID" to "abc")
    }
    TollCatTheme {
        SetupCredentialsStep(
            fields = listOf(
                CatalogField("apiToken", "API Token", isSecret = true),
                CatalogField("accountID", "Account ID"),
            ),
            values = values,
            fieldErrors = emptyMap(),
            outcome = SetupVerifyOutcome.Success("本周期至今 $11.05", "周期 8/1 – 8/31 · 日粒度可用"),
            onEdited = {},
            onExplainKeystore = {},
            collisionReason = "这把凭据已经接入为「Cloudflare · 工作」。",
        )
    }
}
