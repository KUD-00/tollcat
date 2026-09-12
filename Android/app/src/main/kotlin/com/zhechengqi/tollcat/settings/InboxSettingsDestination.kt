package com.zhechengqi.tollcat.settings

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.MeterCoreNative
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import com.zhechengqi.tollcat.ui.StatusBanner
import com.zhechengqi.tollcat.ui.StatusTone
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.Date
import java.util.Locale

@Composable
fun InboxSettingsDestination(
    session: TollCatSession,
    onBack: () -> Unit,
    onOpenManualUsage: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val preferences = session.preferences
    val scope = rememberCoroutineScope()
    val storedInbox = remember {
        InboxMailboxStore.read(session.credentials)
            ?: InboxMailboxStore.migrateFromPreferences(session.credentials, preferences)
    }
    var mailbox by remember { mutableStateOf(storedInbox?.mailbox ?: "") }
    var readKey by remember { mutableStateOf(storedInbox?.readKey ?: "") }
    var ingestSecret by remember { mutableStateOf<String?>(null) }
    var keys by remember { mutableStateOf(listOf<IngestKeyInfo>()) }
    var failure by remember { mutableStateOf<InboxFailure?>(null) }
    var confirmingDelete by remember { mutableStateOf(false) }
    var pendingRevoke by remember { mutableStateOf<String?>(null) }

    fun persist(nextMailbox: String, nextReadKey: String) {
        mailbox = nextMailbox
        readKey = nextReadKey
        if (nextMailbox.isBlank() || nextReadKey.isBlank()) {
            InboxMailboxStore.delete(session.credentials)
        } else {
            InboxMailboxStore.save(session.credentials, nextMailbox, nextReadKey)
        }
    }

    fun refreshKeys() {
        if (readKey.isBlank()) return
        scope.launch {
            runCatching {
                withContext(Dispatchers.Default) { InboxClient.listKeys(readKey) }
            }.onSuccess { keys = it }.onFailure { error ->
                failure = (error as? InboxException)?.failure ?: InboxFailure.Unreachable
            }
        }
    }

    LaunchedEffect(readKey) { refreshKeys() }

    SettingsScaffold(
        title = stringResource(R.string.settings_inbox),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 32.dp),
        ) {
            failure?.let {
                StatusBanner(
                    title = stringResource(R.string.settings_inbox),
                    symbol = MaterialSymbol.Error,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    tone = StatusTone.Error,
                    body = inboxFailureText(it),
                )
            }
            if (mailbox.isBlank()) {
                InboxEmpty()
            } else {
                ingestSecret?.let { secret ->
                    SettingsSection(title = stringResource(R.string.settings_inbox_fresh)) {
                        Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                            FreshKeyCopyBox(secret = secret)
                        }
                        SettingsNavRow(
                            title = stringResource(R.string.settings_inbox_saved),
                            onClick = { ingestSecret = null },
                            showChevron = false,
                        )
                    }
                    Text(
                        stringResource(R.string.settings_inbox_fresh_hint),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
                    )
                }
                SettingsSection(title = stringResource(R.string.settings_inbox_keys)) {
                    if (keys.isEmpty()) {
                        Text(
                            stringResource(R.string.settings_inbox_keys_empty),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(16.dp),
                        )
                    }
                    keys.forEach { key ->
                        SettingsNavRow(
                            title = key.label.ifBlank { stringResource(R.string.settings_inbox_untitled) },
                            subtitle = lastUsedCaption(key.lastUsedAt),
                            onClick = { pendingRevoke = key.id },
                            showChevron = false,
                            headlineColor = MaterialTheme.colorScheme.error,
                        )
                    }
                    SettingsNavRow(
                        title = stringResource(R.string.settings_inbox_mint),
                        onClick = {
                            scope.launch {
                                val minted = withContext(Dispatchers.Default) {
                                    runCatching {
                                        InboxClient.mint(
                                            readKey,
                                            context.getString(R.string.settings_inbox_new_script),
                                        )
                                    }
                                }
                                minted.fold(
                                    onSuccess = {
                                        ingestSecret = it.second
                                        refreshKeys()
                                    },
                                    onFailure = { error ->
                                        failure = (error as? InboxException)?.failure
                                            ?: InboxFailure.Unreachable
                                    },
                                )
                            }
                        },
                        showChevron = false,
                    )
                }
                Text(
                    stringResource(R.string.settings_inbox_keys_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
                )
                SettingsSection(title = stringResource(R.string.settings_inbox_id_label)) {
                    SettingsValueRow(
                        title = stringResource(R.string.settings_inbox_id_label),
                        value = mailbox,
                    )
                    SettingsNavRow(
                        title = stringResource(R.string.settings_inbox_copy_read),
                        icon = MaterialSymbol.ContentCopy,
                        onClick = { copy(context, readKey) },
                        showChevron = false,
                    )
                }
                Text(
                    stringResource(R.string.settings_inbox_privacy),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
                )
                SettingsSection(title = stringResource(R.string.settings_inbox_delete)) {
                    SettingsNavRow(
                        title = stringResource(R.string.settings_inbox_delete),
                        onClick = { confirmingDelete = true },
                        headlineColor = MaterialTheme.colorScheme.error,
                        showChevron = false,
                    )
                }
            }
            Column(Modifier.padding(horizontal = 16.dp, vertical = 16.dp)) {
                PrimaryButton(onClick = onOpenManualUsage, modifier = Modifier.fillMaxWidth()) {
                    Text(stringResource(R.string.settings_inbox_manual_action))
                }
            }
        }
    }

    if (confirmingDelete) {
        AlertDialog(
            onDismissRequest = { confirmingDelete = false },
            title = { Text(stringResource(R.string.settings_inbox_delete_title)) },
            text = { Text(deleteWarning(session)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmingDelete = false
                        scope.launch {
                            withContext(Dispatchers.Default) {
                                runCatching { InboxClient.delete(readKey) }
                            }
                            persist("", "")
                            ingestSecret = null
                            keys = emptyList()
                        }
                    },
                ) {
                    Text(
                        stringResource(R.string.settings_inbox_delete),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmingDelete = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
    pendingRevoke?.let { id ->
        AlertDialog(
            onDismissRequest = { pendingRevoke = null },
            title = { Text(stringResource(R.string.settings_inbox_revoke_title)) },
            text = { Text(stringResource(R.string.settings_inbox_revoke_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        pendingRevoke = null
                        scope.launch {
                            withContext(Dispatchers.Default) {
                                runCatching { InboxClient.revoke(readKey, id) }
                            }
                            if (ingestSecret != null) ingestSecret = null
                            refreshKeys()
                        }
                    },
                ) {
                    Text(
                        stringResource(R.string.settings_inbox_revoke),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingRevoke = null }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
}

@Composable
private fun lastUsedCaption(raw: String?): String {
    val never = stringResource(R.string.settings_inbox_never_used)
    val millis = parseInboxInstant(raw) ?: return never
    return formatInboxMonthAndDay(millis)
}

@Composable
private fun deleteWarning(session: TollCatSession): String {
    val body = stringResource(R.string.settings_inbox_delete_body)
    val names = affectedInboxProviderNames(session)
    if (names.isEmpty()) return body
    val separator = stringResource(R.string.settings_list_separator)
    return names.joinToString(separator) + "\n\n" + body
}

private fun affectedInboxProviderNames(session: TollCatSession): List<String> {
    return session.ledger.accounts()
        .filter { AccountExtras.usesInbox(it) && !AccountExtras.isArchived(it) }
        .map { account ->
            session.catalog.provider(account.providerId)?.displayName ?: account.providerId
        }
        .distinct()
}

private fun parseInboxInstant(raw: String?): Long? {
    val trimmed = raw?.trim().orEmpty()
    if (trimmed.isEmpty()) return null
    runCatching { Instant.parse(trimmed).toEpochMilli() }.getOrNull()?.let { return it }
    if (trimmed.length == 10 && trimmed[4] == '-' && trimmed[7] == '-') {
        val parts = trimmed.split("-")
        if (parts.size == 3) {
            val year = parts[0].toIntOrNull() ?: return null
            val month = parts[1].toIntOrNull() ?: return null
            val day = parts[2].toIntOrNull() ?: return null
            return runCatching {
                LocalDate.of(year, month, day).atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
            }.getOrNull()
        }
    }
    return null
}

private fun formatInboxMonthAndDay(millis: Long): String {
    if (MeterCoreNative.loaded) {
        runCatching {
            val formatted = MeterCoreNative.formatMonthAndDay(millis, MoneyDisplay.localeTag())
            if (formatted.isNotBlank()) return formatted
        }
    }
    val locale = Locale.forLanguageTag(MoneyDisplay.localeTag())
    val skeleton = android.text.format.DateFormat.getBestDateTimePattern(locale, "MMMMd")
    return SimpleDateFormat(skeleton, locale).format(Date(millis))
}

@Composable
private fun inboxFailureText(failure: InboxFailure): String {
    return stringResource(
        when (failure) {
            InboxFailure.RateLimited -> R.string.settings_inbox_rate_limited
            InboxFailure.Unauthorized -> R.string.settings_inbox_gone
            InboxFailure.Unreachable, InboxFailure.Malformed -> R.string.settings_inbox_unreachable
        },
    )
}

private fun copy(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    clipboard.setPrimaryClip(ClipData.newPlainText("inbox", text))
}

/** 刚签出来的 secret 只显示这一次。大号等宽，点整块复制。 */
@Composable
private fun FreshKeyCopyBox(secret: String, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val copyLabel = stringResource(R.string.action_copy)
    Surface(
        onClick = { copy(context, secret) },
        modifier = modifier
            .fillMaxWidth()
            .semantics {
                role = Role.Button
                contentDescription = copyLabel
            },
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainerHighest,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = secret,
                style = MaterialTheme.typography.titleMedium.copy(fontFamily = FontFamily.Monospace),
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f),
            )
            SymbolIcon(
                MaterialSymbol.ContentCopy,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun FreshKeyCopyBoxPreview() {
    TollCatTheme {
        Column(Modifier.padding(16.dp)) {
            FreshKeyCopyBox(secret = "tc_live_preview_secret_once")
        }
    }
}
