package com.zhechengqi.tollcat.setup

import android.content.res.Configuration
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withLink
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.BentoGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateMap
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentType
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextOverflow
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
    // 和第 1 页同一套排法：分组标题 + bento 卡片 + 卡片下面的小字。输入框没有下划线，
    // 底色就是卡片的底色——一张卡里几行字段，而不是几个各自带框的表单控件。
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = MeterSpacing.md),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
    ) {
        SectionHeading(stringResource(R.string.services_credentials_header))
        BentoGroup(modifier = Modifier.padding(horizontal = MeterSpacing.md)) {
            fields.forEach { field ->
                CredentialFieldRow(
                    field = field,
                    value = values[field.key].orEmpty(),
                    isError = fieldErrors[field.key] != null,
                    onValueChange = {
                        values[field.key] = it
                        onEdited()
                    },
                    onPaste = {
                        pasteClipboard(context)?.let { clip ->
                            values[field.key] = clip
                            onEdited()
                        }
                    },
                )
            }
        }
        // 出错的那几格说清楚缺什么；没错时这里写凭据存哪儿。
        val errors = fields.mapNotNull { fieldErrors[it.key] }
        if (errors.isNotEmpty()) {
            errors.forEach { message -> Footnote(message, color = MaterialTheme.colorScheme.error) }
        }
        KeystoreFootnote(onExplainKeystore)
        collisionReason?.let { reason ->
            StatusBanner(
                title = reason,
                symbol = MaterialSymbol.Error,
                tone = StatusTone.Error,
                modifier = Modifier.padding(horizontal = MeterSpacing.md),
            )
        }
        if (saveFailed) {
            StatusBanner(
                title = stringResource(R.string.setup_keystore_write_failed),
                symbol = MaterialSymbol.Error,
                tone = StatusTone.Error,
                modifier = Modifier.padding(horizontal = MeterSpacing.md),
            )
        }
        if (collisionReason == null) {
            outcome?.let {
                Box(Modifier.padding(horizontal = MeterSpacing.md)) {
                    SetupVerifyResultView(it, onRevisePermissions = onRevisePermissions)
                }
            }
        }
        if (showsNickname && outcome?.isSuccess == true && collisionReason == null) {
            SectionHeading(stringResource(R.string.services_nickname_header))
            BentoGroup(modifier = Modifier.padding(horizontal = MeterSpacing.md)) {
                PlainFieldRow(
                    label = stringResource(R.string.services_nickname_existing),
                    value = siblingNickname,
                    onValueChange = onSiblingNicknameChange,
                )
                PlainFieldRow(
                    label = stringResource(R.string.services_nickname_new),
                    value = newNickname,
                    onValueChange = onNewNicknameChange,
                )
            }
            Footnote(stringResource(R.string.services_nickname_footer))
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun SectionHeading(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMediumEmphasized,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(start = MeterSpacing.xxl, end = MeterSpacing.md, top = MeterSpacing.lg, bottom = MeterSpacing.xxs),
    )
}

@Composable
private fun Footnote(text: String, color: Color = MaterialTheme.colorScheme.onSurfaceVariant) {
    Text(
        text = text,
        style = MaterialTheme.typography.bodySmall,
        color = color,
        modifier = Modifier.padding(horizontal = MeterSpacing.xxl),
    )
}

/** 「凭据会存进 Keystore。什么是 Keystore？」——后半句可点，和 iOS 那行脚注同一个位置。 */
@Composable
private fun KeystoreFootnote(onExplain: () -> Unit) {
    val caption = stringResource(R.string.services_keystore_caption)
    val link = stringResource(R.string.services_keystore_what)
    val linkColor = MaterialTheme.colorScheme.primary
    val text = remember(caption, link, linkColor) {
        buildAnnotatedString {
            append(caption)
            append(" ")
            withLink(
                LinkAnnotation.Clickable(
                    tag = "keystore",
                    styles = TextLinkStyles(SpanStyle(color = linkColor)),
                    linkInteractionListener = { onExplain() },
                ),
            ) { append(link) }
        }
    }
    Text(
        text = text,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = MeterSpacing.xxl),
    )
}

@Composable
private fun bentoFieldColors() = TextFieldDefaults.colors(
    focusedContainerColor = MaterialTheme.colorScheme.surfaceContainer,
    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainer,
    errorContainerColor = MaterialTheme.colorScheme.surfaceContainer,
    focusedIndicatorColor = Color.Transparent,
    unfocusedIndicatorColor = Color.Transparent,
)

@Composable
private fun CredentialFieldRow(
    field: CatalogField,
    value: String,
    isError: Boolean,
    onValueChange: (String) -> Unit,
    onPaste: () -> Unit,
) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        modifier = if (field.isSecret) {
            Modifier.fillMaxWidth().semantics { contentType = ContentType.Password }
        } else {
            Modifier.fillMaxWidth()
        },
        label = { Text(field.label) },
        // 提示（「以 github_pat_ 开头」）放在占位里：聚焦、还没填时才出现，不在卡片外面再挂一行。
        placeholder = field.hint.takeIf { it.isNotBlank() }?.let { hint ->
            { Text(hint, maxLines = 1, overflow = TextOverflow.Ellipsis) }
        },
        isError = isError,
        singleLine = true,
        shape = Bento.middle,
        colors = bentoFieldColors(),
        visualTransformation = if (field.isSecret) {
            PasswordVisualTransformation()
        } else {
            VisualTransformation.None
        },
        // 只遮住显示不够：普通文本输入类型下，输入法会把敲进去的 token 记进词库、
        // 候选栏，云输入法还会上传。密钥字段声明为密码类型并关掉纠错联想。
        keyboardOptions = if (field.isSecret) {
            KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false)
        } else {
            KeyboardOptions.Default
        },
        trailingIcon = {
            TextButton(onClick = onPaste) {
                Text(stringResource(R.string.action_paste))
            }
        },
    )
}

@Composable
private fun PlainFieldRow(label: String, value: String, onValueChange: (String) -> Unit) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier.fillMaxWidth(),
        label = { Text(label) },
        singleLine = true,
        shape = Bento.middle,
        colors = bentoFieldColors(),
    )
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
