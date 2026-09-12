package com.zhechengqi.tollcat.setup

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.settings.FeedbackCategory
import com.zhechengqi.tollcat.settings.FeedbackClient
import com.zhechengqi.tollcat.settings.FeedbackResult
import com.zhechengqi.tollcat.settings.androidDeviceModel
import com.zhechengqi.tollcat.settings.androidOsVersion
import com.zhechengqi.tollcat.settings.appVersionCaption
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale

@Composable
fun SetupFeedbackSection(
    providerName: String,
    testedOk: Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val version = remember { appVersionCaption(context) }
    val os = remember { androidOsVersion() }
    val device = remember { androidDeviceModel() }
    val locale = remember { Locale.getDefault().toLanguageTag() }
    val draft = if (testedOk) {
        stringResource(R.string.setup_feedback_draft_ok, providerName)
    } else {
        stringResource(R.string.setup_feedback_draft_unknown, providerName)
    }
    var message by remember(testedOk, providerName) { mutableStateOf(draft) }
    var contact by remember { mutableStateOf("") }
    var submitting by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<FeedbackResult?>(null) }
    val scope = rememberCoroutineScope()
    val remaining = FeedbackClient.MESSAGE_MAX - message.length

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = stringResource(R.string.settings_feedback),
            style = MaterialTheme.typography.titleMedium,
        )
        if (result == FeedbackResult.Sent) {
            Text(
                text = stringResource(R.string.settings_feedback_sent),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            return@Column
        }
        Text(
            text = stringResource(
                if (testedOk) {
                    R.string.setup_feedback_success_lede
                } else {
                    R.string.setup_feedback_failure_lede
                },
            ),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        OutlinedTextField(
            value = message,
            onValueChange = { if (it.length <= FeedbackClient.MESSAGE_MAX) message = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text(stringResource(R.string.settings_feedback_message_hint)) },
            minLines = 3,
        )
        if (remaining <= 200) {
            Text(
                text = stringResource(R.string.settings_feedback_remaining, remaining),
                style = MaterialTheme.typography.bodySmall,
                color = if (remaining < 0) {
                    MaterialTheme.colorScheme.error
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
            )
        }
        OutlinedTextField(
            value = contact,
            onValueChange = { if (it.length <= FeedbackClient.CONTACT_MAX) contact = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text(stringResource(R.string.settings_feedback_contact_hint)) },
            singleLine = true,
        )
        Text(
            text = providerName,
            style = MaterialTheme.typography.bodyMedium,
        )
        TextButton(
            onClick = {
                submitting = true
                result = null
                val category = if (testedOk) FeedbackCategory.Other else FeedbackCategory.Bug
                val body = message
                val handle = contact
                scope.launch {
                    val outcome = withContext(Dispatchers.IO) {
                        FeedbackClient.submit(
                            category = category,
                            message = body,
                            contact = handle,
                            appVersion = version,
                            osVersion = os,
                            locale = locale,
                            deviceModel = device,
                            providers = listOf(providerName),
                        )
                    }
                    result = outcome
                    submitting = false
                    if (outcome == FeedbackResult.Sent) {
                        message = ""
                        contact = ""
                    }
                }
            },
            enabled = message.trim().isNotEmpty() && !submitting,
        ) {
            Text(stringResource(R.string.settings_feedback_send))
        }
        result?.let { outcome ->
            Text(
                text = when (outcome) {
                    FeedbackResult.Sent -> stringResource(R.string.settings_feedback_sent)
                    FeedbackResult.RateLimited -> stringResource(R.string.settings_feedback_rate_limited)
                    FeedbackResult.Failed -> stringResource(R.string.settings_feedback_failed)
                },
                style = MaterialTheme.typography.bodySmall,
                color = if (outcome == FeedbackResult.Failed) {
                    MaterialTheme.colorScheme.error
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
            )
        }
        Text(
            text = stringResource(R.string.setup_feedback_privacy),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
