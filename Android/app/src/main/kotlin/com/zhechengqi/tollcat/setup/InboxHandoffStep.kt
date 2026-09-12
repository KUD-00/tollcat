package com.zhechengqi.tollcat.setup

import android.content.Context
import android.content.res.Configuration
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.AccountRow
import com.zhechengqi.tollcat.JniGate
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.settings.InboxClient
import com.zhechengqi.tollcat.settings.InboxException
import com.zhechengqi.tollcat.settings.InboxFailure
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

enum class InboxHandoffPhase {
    Idle,
    Provisioning,
    Failed,
    Issued,
}

/**
 * 读数信箱接入的状态机。没有「测试连接」：用户这会儿还没写脚本，
 * 信箱里必然是空的。
 */
class InboxHandoffState(
    private val session: TollCatSession,
    private val providerId: String,
    private val displayName: String,
    private val accountId: String,
) {
    var phase by mutableStateOf(InboxHandoffPhase.Idle)
        private set
    var failure by mutableStateOf<InboxFailure?>(null)
        private set
    var ingestSecret by mutableStateOf<String?>(null)
        private set
    var siblingNickname by mutableStateOf("")
    var newNickname by mutableStateOf("")

    private var ingestKeyId: String? = null
    private var pendingMailbox: String? = null
    private var pendingReadKey: String? = null
    private var createdMailboxThisSession = false
    private var mintedKeyThisSession = false
    private var connected = false

    val showsNickname: Boolean
        get() {
            if (isRotating()) return false
            return siblings().isNotEmpty()
        }

    val canConnect: Boolean
        get() {
            if (phase != InboxHandoffPhase.Issued) return false
            if (ingestSecret.isNullOrBlank() || ingestKeyId.isNullOrBlank()) return false
            if (showsNickname && newNickname.trim().isEmpty()) return false
            return true
        }

    fun prompt(context: Context, nowMillis: Long): String {
        val title = if (showsNickname && newNickname.trim().isNotEmpty()) {
            "$displayName · ${newNickname.trim()}"
        } else {
            displayName
        }
        return InboxPrompt.text(context, title, providerId, nowMillis)
    }

    fun prepare() {
        if (phase == InboxHandoffPhase.Provisioning || phase == InboxHandoffPhase.Issued) return
        phase = InboxHandoffPhase.Provisioning
        failure = null
        JniGate.run { provisionOnJni() }
    }

    fun retry() {
        phase = InboxHandoffPhase.Provisioning
        failure = null
        JniGate.run {
            discardOnJni()
            provisionOnJni()
        }
    }

    fun connect(defaultSiblingName: String, onDone: (Boolean) -> Unit) {
        if (!canConnect) {
            onDone(false)
            return
        }
        val mailbox = pendingMailbox
        val readKey = pendingReadKey
        val keyId = ingestKeyId
        if (mailbox.isNullOrBlank() || readKey.isNullOrBlank() || keyId.isNullOrBlank()) {
            onDone(false)
            return
        }
        val account = currentAccount() ?: run {
            onDone(false)
            return
        }
        val oldKey = AccountExtras.ingestKeyId(account)
        try {
            InboxMailboxStore.save(session.credentials, mailbox, readKey)
            session.ledger.upsertAccount(AccountExtras.withInbox(account, keyId))
            if (showsNickname) {
                siblings().firstOrNull()?.let { sibling ->
                    val name = siblingNickname.trim().ifEmpty { defaultSiblingName }
                    session.setNickname(sibling.accountId, name)
                }
                session.setNickname(account.accountId, newNickname.trim())
            } else {
                session.setNickname(account.accountId, AccountExtras.nickname(account))
            }
            connected = true
            if (!oldKey.isNullOrBlank() && oldKey != keyId) {
                JniGate.run { runCatching { InboxClient.revoke(readKey, oldKey) } }
            }
            onDone(true)
        } catch (_: Throwable) {
            onDone(false)
        }
    }

    fun discardIfUnconnected() {
        if (connected) return
        val created = createdMailboxThisSession
        val minted = mintedKeyThisSession
        val readKey = pendingReadKey
        val keyId = ingestKeyId
        createdMailboxThisSession = false
        mintedKeyThisSession = false
        pendingMailbox = null
        pendingReadKey = null
        ingestKeyId = null
        ingestSecret = null
        phase = InboxHandoffPhase.Idle
        failure = null
        JniGate.run {
            if (connected) return@run
            if (minted && !keyId.isNullOrBlank() && !readKey.isNullOrBlank()) {
                runCatching { InboxClient.revoke(readKey, keyId) }
            }
            if (created && !readKey.isNullOrBlank()) {
                runCatching { InboxClient.delete(readKey) }
            }
        }
    }

    fun seedNicknameDraft(defaultSiblingName: String) {
        if (!showsNickname || siblingNickname.isNotEmpty()) return
        val existing = siblings().firstOrNull()?.let { AccountExtras.nickname(it) }.orEmpty()
        siblingNickname = existing.ifEmpty { defaultSiblingName }
    }

    private fun isRotating(): Boolean {
        val account = currentAccount() ?: return false
        return session.hasCredentials(account) || AccountExtras.usesInbox(account)
    }

    private fun siblings(): List<AccountRow> =
        session.accounts(providerId).filter {
            it.accountId != accountId && !AccountExtras.isArchived(it)
        }

    private fun currentAccount(): AccountRow? =
        session.accounts(providerId).firstOrNull { it.accountId == accountId }

    private fun provisionOnJni() {
        try {
            val existing = InboxMailboxStore.read(session.credentials)
                ?: InboxMailboxStore.migrateFromPreferences(session.credentials, session.preferences)
            val existingMailbox = existing?.mailbox ?: ""
            val existingReadKey = existing?.readKey ?: ""
            if (existingMailbox.isNotBlank() && existingReadKey.isNotBlank()) {
                val label = displayName
                val minted = InboxClient.mint(existingReadKey, label)
                pendingMailbox = existingMailbox
                pendingReadKey = existingReadKey
                ingestKeyId = minted.first
                createdMailboxThisSession = false
                mintedKeyThisSession = true
                JniGate.onMain {
                    ingestSecret = minted.second
                    phase = InboxHandoffPhase.Issued
                }
            } else {
                val created = InboxClient.create()
                pendingMailbox = created.mailbox
                pendingReadKey = created.readKey
                ingestKeyId = created.ingestKeyId
                createdMailboxThisSession = true
                mintedKeyThisSession = false
                JniGate.onMain {
                    ingestSecret = created.ingestKey
                    phase = InboxHandoffPhase.Issued
                }
            }
        } catch (error: InboxException) {
            JniGate.onMain {
                failure = error.failure
                phase = InboxHandoffPhase.Failed
            }
        } catch (_: Throwable) {
            JniGate.onMain {
                failure = InboxFailure.Unreachable
                phase = InboxHandoffPhase.Failed
            }
        }
    }

    private fun discardOnJni() {
        if (connected) return
        val created = createdMailboxThisSession
        val minted = mintedKeyThisSession
        val readKey = pendingReadKey
        val keyId = ingestKeyId
        if (minted && !keyId.isNullOrBlank() && !readKey.isNullOrBlank()) {
            runCatching { InboxClient.revoke(readKey, keyId) }
        }
        if (created && !readKey.isNullOrBlank()) {
            runCatching { InboxClient.delete(readKey) }
        }
    }
}

@Composable
fun rememberInboxHandoffState(
    session: TollCatSession,
    providerId: String,
    displayName: String,
    accountId: String,
): InboxHandoffState {
    return remember(providerId, accountId) {
        InboxHandoffState(session, providerId, displayName, accountId)
    }
}

@Composable
fun InboxHandoffStep(
    state: InboxHandoffState,
    nowMillis: Long,
    defaultSiblingName: String,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    LaunchedEffect(state.showsNickname, defaultSiblingName) {
        state.seedNicknameDraft(defaultSiblingName)
    }
    InboxHandoffBody(
        phase = state.phase,
        prompt = state.prompt(context, nowMillis),
        ingestSecret = state.ingestSecret,
        failure = state.failure,
        showsNickname = state.showsNickname && state.phase == InboxHandoffPhase.Issued,
        siblingNickname = state.siblingNickname,
        onSiblingNicknameChange = { state.siblingNickname = it },
        newNickname = state.newNickname,
        onNewNicknameChange = { state.newNickname = it },
        onRetry = { state.retry() },
        modifier = modifier,
    )
}

@Composable
fun InboxHandoffLifecycle(
    active: Boolean,
    state: InboxHandoffState,
) {
    if (!active) return
    LaunchedEffect(state) { state.prepare() }
    DisposableEffect(state) {
        onDispose { state.discardIfUnconnected() }
    }
}

@Composable
private fun InboxHandoffBody(
    phase: InboxHandoffPhase,
    prompt: String,
    ingestSecret: String?,
    failure: InboxFailure?,
    showsNickname: Boolean,
    siblingNickname: String,
    onSiblingNicknameChange: (String) -> Unit,
    newNickname: String,
    onNewNicknameChange: (String) -> Unit,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = MeterSpacing.md, vertical = MeterSpacing.xs),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
    ) {
        when (phase) {
            InboxHandoffPhase.Idle, InboxHandoffPhase.Provisioning -> {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(MeterSpacing.lg))
                    Text(
                        text = stringResource(R.string.inbox_handoff_provisioning),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            InboxHandoffPhase.Failed -> {
                Text(
                    text = stringResource(R.string.inbox_handoff_failed),
                    style = MaterialTheme.typography.titleMedium,
                )
                Text(
                    text = inboxHandoffFailureText(failure),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                TextButton(onClick = onRetry) {
                    Text(stringResource(R.string.inbox_handoff_retry))
                }
            }
            InboxHandoffPhase.Issued -> {
                PromptSection(
                    prompt = prompt,
                    onCopy = {
                        copyText(
                            context,
                            prompt,
                            context.getString(R.string.inbox_handoff_copy_prompt),
                        )
                    },
                )
                ingestSecret?.let { secret ->
                    Text(
                        text = stringResource(R.string.inbox_handoff_key_header),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    SetupCopyBox(value = secret)
                    Text(
                        text = stringResource(R.string.inbox_handoff_key_footer),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                if (showsNickname) {
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
            }
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun PromptSection(
    prompt: String,
    onCopy: () -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    Text(
        text = stringResource(R.string.inbox_handoff_prompt_header),
        style = MaterialTheme.typography.titleMedium,
    )
    Box(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(end = MeterSpacing.xl)
                .animateContentSize(),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        ) {
            Text(
                text = prompt,
                style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = if (expanded) Int.MAX_VALUE else 6,
                overflow = TextOverflow.Ellipsis,
            )
            TextButton(onClick = { expanded = !expanded }) {
                Text(
                    stringResource(
                        if (expanded) R.string.inbox_handoff_collapse else R.string.inbox_handoff_expand,
                    ),
                )
            }
        }
        IconButton(
            onClick = onCopy,
            modifier = Modifier.align(Alignment.TopEnd),
            shapes = IconButtonDefaults.shapes(),
        ) {
            SymbolIcon(
                MaterialSymbol.ContentCopy,
                contentDescription = stringResource(R.string.inbox_handoff_copy_prompt),
            )
        }
    }
    Text(
        text = stringResource(R.string.inbox_handoff_prompt_footer),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun inboxHandoffFailureText(failure: InboxFailure?): String {
    return stringResource(
        when (failure) {
            InboxFailure.RateLimited -> R.string.settings_inbox_rate_limited
            InboxFailure.Unauthorized, InboxFailure.Malformed -> R.string.settings_inbox_gone
            InboxFailure.Unreachable, null -> R.string.settings_inbox_unreachable
        },
    )
}

private val previewPrompt = """
    帮我做一个每天自动上报 Render 花费的脚本。

    第一步，取账单：登录 Render，读出「本月至今」的总花费，单位美元。
    这家没有公开的账单 API，你需要自己想办法——浏览器自动化、解析账单邮件都行。

    第二步，上报：把这个数字 POST 到下面这个地址。

      POST https://api.tollcat.app/v1/readings
      Authorization: Bearer ${'$'}TOLL_INGEST_KEY
      content-type: application/json

      {"provider":"render","periodStart":"2026-09-01","currentSpendUSD":"12.34"}
""".trimIndent()

@Preview(name = "Light · 拿到 key", showBackground = true)
@Preview(name = "Dark · 拿到 key", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun InboxHandoffIssuedPreview() {
    TollCatTheme {
        InboxHandoffBody(
            phase = InboxHandoffPhase.Issued,
            prompt = previewPrompt,
            ingestSecret = "tolli_PREVIEW_KEY_1234",
            failure = null,
            showsNickname = false,
            siblingNickname = "",
            onSiblingNicknameChange = {},
            newNickname = "",
            onNewNicknameChange = {},
            onRetry = {},
        )
    }
}

@Preview(name = "Light · 建信箱失败", showBackground = true)
@Preview(name = "Dark · 建信箱失败", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun InboxHandoffFailedPreview() {
    TollCatTheme {
        InboxHandoffBody(
            phase = InboxHandoffPhase.Failed,
            prompt = "",
            ingestSecret = null,
            failure = InboxFailure.Unreachable,
            showsNickname = false,
            siblingNickname = "",
            onSiblingNicknameChange = {},
            newNickname = "",
            onNewNicknameChange = {},
            onRetry = {},
        )
    }
}

@Preview(name = "Light · 正在创建", showBackground = true)
@Preview(name = "Dark · 正在创建", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun InboxHandoffProvisioningPreview() {
    TollCatTheme {
        InboxHandoffBody(
            phase = InboxHandoffPhase.Provisioning,
            prompt = "",
            ingestSecret = null,
            failure = null,
            showsNickname = false,
            siblingNickname = "",
            onSiblingNicknameChange = {},
            newNickname = "",
            onNewNicknameChange = {},
            onRetry = {},
        )
    }
}
