package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.AccountRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.TollCatSheet

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CredentialManagementSheet(
    session: TollCatSession,
    providerId: String,
    displayName: String,
    onDismiss: () -> Unit,
    onRotate: (AccountRow) -> Unit,
    onAdd: () -> Unit,
) {
    session.dataRevision
    val accounts = session.liveAccounts(providerId)
    val nicknames = remember(accounts.map { it.accountId }) {
        mutableStateMapOf<String, String>().apply {
            accounts.forEach { put(it.accountId, AccountExtras.nickname(it).orEmpty()) }
        }
    }
    var pendingDelete by remember { mutableStateOf<AccountRow?>(null) }
    val saveNicknames = {
        nicknames.forEach { (id, value) ->
            val account = accounts.firstOrNull { it.accountId == id } ?: return@forEach
            val trimmed = value.trim().ifEmpty { null }
            if (trimmed != AccountExtras.nickname(account)) {
                session.setNickname(id, trimmed)
            }
        }
    }
    DisposableEffect(Unit) {
        onDispose { saveNicknames() }
    }
    TollCatSheet(
        onDismiss = {
            saveNicknames()
            onDismiss()
        },
    ) {
        CredentialManagementContent(
            displayName = displayName,
            accounts = accounts,
            nicknames = nicknames,
            connected = { session.hasCredentials(it) },
            usesInbox = { AccountExtras.usesInbox(it) },
            lastRefresh = { account ->
                session.snapshotsFor(providerId)
                    .filter { it.accountId == account.accountId }
                    .maxByOrNull { it.fetchedAtMillis }
                    ?.fetchedAtMillis
            },
            nowMillis = session.nowMillis(),
            onRotate = onRotate,
            onAdd = onAdd,
            onDelete = { pendingDelete = it },
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(bottom = 16.dp),
        )
    }
    pendingDelete?.let { account ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text(stringResource(R.string.services_delete_account_title)) },
            text = { Text(stringResource(R.string.services_delete_account_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        session.deleteUsageAccount(account.accountId)
                        pendingDelete = null
                        if (session.liveAccounts(providerId).isEmpty()) onDismiss()
                    },
                ) {
                    Text(
                        stringResource(R.string.services_remove_confirm),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
}

@Composable
internal fun CredentialManagementContent(
    displayName: String,
    accounts: List<AccountRow>,
    nicknames: MutableMap<String, String>,
    connected: (AccountRow) -> Boolean,
    usesInbox: (AccountRow) -> Boolean,
    lastRefresh: (AccountRow) -> Long?,
    nowMillis: Long,
    onRotate: (AccountRow) -> Unit,
    onAdd: () -> Unit,
    onDelete: (AccountRow) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(modifier = modifier) {
        Text(
            text = stringResource(R.string.action_manage_credentials),
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
        )
        accounts.forEachIndexed { index, account ->
            val nick = nicknames[account.accountId].orEmpty()
            val title = nick.trim().ifEmpty {
                if (accounts.size == 1) {
                    stringResource(R.string.services_section_usage)
                } else {
                    stringResource(R.string.services_account_n, index + 1)
                }
            }
            val last = lastRefresh(account)
            val caption = when {
                last != null -> stringResource(
                    R.string.services_last_refresh,
                    ServiceRelativeTime.caption(context, last, nowMillis),
                )
                usesInbox(account) -> stringResource(R.string.setup_support_inbox)
                connected(account) -> stringResource(R.string.services_credential_rotate)
                else -> stringResource(R.string.services_unconnected)
            }
            ListItem(
                onClick = { onRotate(account) },
                supportingContent = { Text(caption) },
                trailingContent = {
                    TextButton(onClick = { onDelete(account) }) {
                        Text(
                            stringResource(R.string.services_remove_confirm),
                            color = MaterialTheme.colorScheme.error,
                        )
                    }
                },
                content = { Text(title) },
            )
            TextField(
                value = nick,
                onValueChange = { nicknames[account.accountId] = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 4.dp),
                label = { Text(stringResource(R.string.services_name)) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = {}),
            )
            HorizontalDivider()
        }
        ListItem(
            onClick = onAdd,
            supportingContent = {
                Text(stringResource(R.string.services_credential_add_footer, displayName))
            },
            content = { Text(stringResource(R.string.services_credential_add)) },
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CredentialManagementPreview() {
    val accounts = listOf(
        AccountRow("a1", "cloudflare", "acct.a1", 0),
        AccountRow("a2", "cloudflare", "acct.a2", 1, """{"nickname":"工作"}"""),
    )
    val nicks = mutableStateMapOf("a1" to "", "a2" to "工作")
    TollCatTheme {
        CredentialManagementContent(
            displayName = "Cloudflare",
            accounts = accounts,
            nicknames = nicks,
            connected = { true },
            usesInbox = { false },
            lastRefresh = { 1_725_000_000_000 },
            nowMillis = 1_725_000_060_000,
            onRotate = {},
            onAdd = {},
            onDelete = {},
        )
    }
}
