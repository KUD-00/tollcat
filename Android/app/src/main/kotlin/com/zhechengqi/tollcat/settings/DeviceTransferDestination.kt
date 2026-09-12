package com.zhechengqi.tollcat.settings

import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.PrimaryButton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private const val TRANSFER_LIFETIME_HOURS = 24

@Composable
fun DeviceTransferDestination(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var tab by remember { mutableStateOf("export") }
    var export by remember { mutableStateOf<TransferExport?>(null) }
    var exporting by remember { mutableStateOf(false) }
    var importing by remember { mutableStateOf(false) }
    var code by remember { mutableStateOf("") }
    var pickedName by remember { mutableStateOf<String?>(null) }
    var pickedBytes by remember { mutableStateOf<ByteArray?>(null) }
    var message by remember { mutableStateOf<String?>(null) }
    var messageIsError by remember { mutableStateOf(false) }
    var lockout by remember { mutableStateOf(TransferLockout()) }
    var nowMillis by remember { mutableLongStateOf(session.nowMillis()) }

    val pick = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        val picked = uri ?: return@rememberLauncherForActivityResult
        scope.launch {
            val bytes = withContext(Dispatchers.IO) {
                runCatching { DeviceTransfer.readUri(context, picked) }.getOrNull()
            }
            pickedBytes = bytes
            pickedName = picked.lastPathSegment
            if (bytes == null) {
                message = context.getString(R.string.settings_transfer_invalid_file)
                messageIsError = true
            } else if (messageIsError) {
                message = null
            }
        }
    }

    LaunchedEffect(tab) {
        if (tab != "export" || export != null || exporting) return@LaunchedEffect
        exporting = true
        val made = withContext(Dispatchers.Default) {
            runCatching {
                DeviceTransfer.export(
                    session.ledger,
                    session.credentials,
                    session.preferences,
                    session.nowMillis(),
                )
            }.getOrNull()
        }
        export = made
        exporting = false
    }

    LaunchedEffect(lockout.lockedUntilMillis) {
        val until = lockout.lockedUntilMillis ?: return@LaunchedEffect
        while (true) {
            val now = session.nowMillis()
            nowMillis = now
            if (now >= until) break
            delay(1_000)
        }
    }

    val locked = lockout.isLocked(nowMillis)

    SettingsScaffold(
        title = stringResource(R.string.settings_transfer),
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
            SettingsSection(title = stringResource(R.string.settings_transfer)) {
                SettingsToggleGroupRow(
                    title = null,
                    options = listOf(
                        stringResource(R.string.settings_transfer_export) to "export",
                        stringResource(R.string.settings_transfer_import) to "import",
                    ),
                    selected = tab,
                    onSelect = { tab = it },
                )
            }
            if (tab == "export") {
                TransferExportPane(
                    export = export,
                    exporting = exporting,
                    onShare = {
                        val made = export ?: return@TransferExportPane
                        shareTransferFile(context, made)
                    },
                )
            } else {
                TransferImportPane(
                    code = code,
                    onCodeChange = { if (!locked) code = it },
                    pickedName = pickedName,
                    message = if (locked) {
                        stringResource(R.string.settings_transfer_locked, lockout.remainingSeconds(nowMillis))
                    } else {
                        message
                    },
                    messageIsError = messageIsError || locked,
                    canPick = !importing,
                    canImport = pickedBytes != null && code.isNotBlank() && !locked && !importing,
                    codeEnabled = !locked && !importing,
                    onPick = { pick.launch(arrayOf("*/*")) },
                    onImport = {
                        val bytes = pickedBytes
                        if (bytes == null) {
                            message = context.getString(R.string.settings_transfer_invalid_file)
                            messageIsError = true
                            return@TransferImportPane
                        }
                        val now = session.nowMillis()
                        nowMillis = now
                        if (lockout.isLocked(now)) {
                            message = context.getString(
                                R.string.settings_transfer_locked,
                                lockout.remainingSeconds(now),
                            )
                            messageIsError = true
                            return@TransferImportPane
                        }
                        importing = true
                        scope.launch {
                            val result = withContext(Dispatchers.Default) {
                                runCatching {
                                    DeviceTransfer.importPayload(
                                        bytes,
                                        code,
                                        session.ledger,
                                        session.credentials,
                                        session.preferences,
                                        session.nowMillis(),
                                    )
                                }
                            }
                            importing = false
                            result.fold(
                                onSuccess = {
                                    lockout = lockout.registerSuccess()
                                    session.displayCurrency = session.preferences.displayCurrency
                                    MoneyDisplay.currency = session.displayCurrency
                                    session.recompute()
                                    session.refreshAll()
                                    message = context.getString(R.string.settings_transfer_imported)
                                    messageIsError = false
                                },
                                onFailure = { error ->
                                    val nowAfter = session.nowMillis()
                                    nowMillis = nowAfter
                                    if (error.message == "auth") {
                                        val next = lockout.registerFailure(nowAfter)
                                        lockout = next
                                        message = context.getString(
                                            R.string.settings_transfer_remaining,
                                            next.remainingFreeAttempts,
                                        )
                                        messageIsError = true
                                    } else {
                                        message = context.getString(transferErrorRes(error.message))
                                        messageIsError = true
                                    }
                                },
                            )
                        }
                    },
                )
            }
        }
    }
}

@Composable
private fun TransferExportPane(
    export: TransferExport?,
    exporting: Boolean,
    onShare: () -> Unit,
) {
    SettingsSection(title = stringResource(R.string.settings_transfer_export)) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                stringResource(R.string.settings_transfer_export_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
    export?.let { made ->
        SettingsSection(title = stringResource(R.string.settings_transfer_code)) {
            Text(
                made.displayCode,
                style = MaterialTheme.typography.headlineMedium.copy(fontFamily = FontFamily.Monospace),
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
            )
        }
        Text(
            stringResource(R.string.settings_transfer_code_hint),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
        )
        SettingsGroup {
            SettingsValueRow(
                title = stringResource(R.string.settings_transfer_lifetime),
                value = stringResource(R.string.settings_transfer_hours, TRANSFER_LIFETIME_HOURS),
            )
        }
        Text(
            stringResource(R.string.settings_transfer_deadline, transferDeadlineCaption(made.notAfterMillis)),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
        )
    }
    Column(Modifier.padding(horizontal = 16.dp, vertical = 16.dp)) {
        PrimaryButton(
            onClick = onShare,
            enabled = export != null && !exporting,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.settings_transfer_share))
        }
    }
}

@Composable
private fun TransferImportPane(
    code: String,
    onCodeChange: (String) -> Unit,
    pickedName: String?,
    message: String?,
    messageIsError: Boolean,
    canPick: Boolean,
    canImport: Boolean,
    codeEnabled: Boolean,
    onPick: () -> Unit,
    onImport: () -> Unit,
) {
    SettingsSection(title = stringResource(R.string.settings_transfer_import)) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                stringResource(R.string.settings_transfer_import_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
    Column(
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        PrimaryButton(
            onClick = onPick,
            enabled = canPick,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.settings_transfer_pick))
        }
        pickedName?.let {
            Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        OutlinedTextField(
            value = code,
            onValueChange = onCodeChange,
            enabled = codeEnabled,
            label = { Text(stringResource(R.string.settings_transfer_code)) },
            modifier = Modifier.fillMaxWidth(),
        )
        PrimaryButton(
            onClick = onImport,
            enabled = canImport,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.settings_transfer_import))
        }
        message?.let {
            Text(
                it,
                color = if (messageIsError) {
                    MaterialTheme.colorScheme.error
                } else {
                    MaterialTheme.colorScheme.primary
                },
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
}

@Composable
private fun transferDeadlineCaption(notAfterMillis: Long): String {
    val locale = LocalContext.current.resources.configuration.locales[0] ?: Locale.getDefault()
    val skeleton = android.text.format.DateFormat.getBestDateTimePattern(locale, "MMMMdjjmm")
    return SimpleDateFormat(skeleton, locale).format(Date(notAfterMillis))
}

private fun shareTransferFile(context: android.content.Context, made: TransferExport) {
    val dir = File(context.cacheDir, "share").apply { mkdirs() }
    val file = File(dir, "tollcat-transfer.tollcat")
    file.writeBytes(made.fileBytes)
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.share", file)
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "application/octet-stream"
        putExtra(Intent.EXTRA_STREAM, uri)
        putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.settings_transfer_share))
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(
        Intent.createChooser(intent, context.getString(R.string.settings_transfer_share)),
    )
}

private fun transferErrorRes(message: String?): Int {
    return when (message) {
        "bad-code" -> R.string.settings_transfer_bad_code
        "expired" -> R.string.settings_transfer_expired
        "version", "schema" -> R.string.settings_transfer_old_schema
        "auth" -> R.string.settings_transfer_failed
        else -> R.string.settings_transfer_invalid_file
    }
}

@Preview(name = "Export Light", showBackground = true)
@Preview(name = "Export Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TransferExportPreview() {
    TollCatTheme {
        Column(Modifier.padding(bottom = 16.dp)) {
            TransferExportPane(
                export = TransferExport(
                    displayCode = "K7M2Q-9XR4T",
                    fileBytes = byteArrayOf(0x74),
                    notAfterMillis = 1_787_616_000_000L,
                ),
                exporting = false,
                onShare = {},
            )
        }
    }
}

@Preview(name = "Import Light", showBackground = true)
@Preview(name = "Import Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TransferImportPreview() {
    TollCatTheme {
        TransferImportPane(
            code = "AAAAA-AAAAA",
            onCodeChange = {},
            pickedName = "tollcat-transfer.tollcat",
            message = stringResource(R.string.settings_transfer_remaining, 4),
            messageIsError = true,
            canPick = true,
            canImport = true,
            codeEnabled = true,
            onPick = {},
            onImport = {},
        )
    }
}

@Preview(name = "Import locked Light", showBackground = true)
@Preview(name = "Import locked Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TransferImportLockedPreview() {
    TollCatTheme {
        TransferImportPane(
            code = "AAAAA-AAAAA",
            onCodeChange = {},
            pickedName = "tollcat-transfer.tollcat",
            message = stringResource(R.string.settings_transfer_locked, 15),
            messageIsError = true,
            canPick = true,
            canImport = false,
            codeEnabled = false,
            onPick = {},
            onImport = {},
        )
    }
}
