package com.zhechengqi.tollcat.settings

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.ui.PrimaryButton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale

@Composable
fun FeedbackDestination(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val version = remember { appVersionCaption(context) }
    val os = remember { androidOsVersion() }
    val device = remember { androidDeviceModel() }
    val locale = remember { Locale.getDefault().toLanguageTag() }
    val providers = remember {
        session.memberships().map { membership ->
            session.catalog.provider(membership.providerId)?.displayName ?: membership.providerId
        }
    }
    var category by remember { mutableStateOf(FeedbackCategory.Bug) }
    var message by remember { mutableStateOf("") }
    var contact by remember { mutableStateOf("") }
    var includeProviders by remember { mutableStateOf(false) }
    var submitting by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<FeedbackResult?>(null) }
    val scope = rememberCoroutineScope()
    val remaining = FeedbackClient.MESSAGE_MAX - message.length

    SettingsScaffold(
        title = stringResource(R.string.settings_feedback),
        onBack = onBack,
        modifier = modifier,
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
            ) {
                PrimaryButton(
                    onClick = {
                        submitting = true
                        result = null
                        val attached = if (includeProviders) providers else null
                        scope.launch {
                            val outcome = withContext(Dispatchers.IO) {
                                FeedbackClient.submit(
                                    category = category,
                                    message = message,
                                    contact = contact,
                                    appVersion = version,
                                    osVersion = os,
                                    locale = locale,
                                    deviceModel = device,
                                    providers = attached,
                                )
                            }
                            result = outcome
                            submitting = false
                            if (outcome == FeedbackResult.Sent) {
                                message = ""
                                contact = ""
                                includeProviders = false
                            }
                        }
                    },
                    enabled = message.trim().isNotEmpty() && !submitting,
                    modifier = Modifier.fillMaxWidth(),
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
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (outcome == FeedbackResult.Failed) {
                            MaterialTheme.colorScheme.error
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        },
                        modifier = Modifier.padding(top = 8.dp),
                    )
                }
            }
        },
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 16.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_feedback_category),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(start = 32.dp, end = 16.dp, top = 16.dp, bottom = 8.dp),
            )
            Row(
                modifier = Modifier
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                FeedbackCategory.entries.forEach { item ->
                    FilterChip(
                        selected = category == item,
                        onClick = { category = item },
                        label = { Text(categoryTitle(item)) },
                    )
                }
            }
            OutlinedTextField(
                value = message,
                onValueChange = { if (it.length <= FeedbackClient.MESSAGE_MAX) message = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                minLines = 5,
                maxLines = 12,
                label = { Text(stringResource(R.string.settings_feedback_message_label)) },
                placeholder = { Text(stringResource(R.string.settings_feedback_message_hint)) },
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
                    modifier = Modifier.padding(horizontal = 32.dp),
                )
            }
            OutlinedTextField(
                value = contact,
                onValueChange = { if (it.length <= FeedbackClient.CONTACT_MAX) contact = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                singleLine = true,
                label = { Text(stringResource(R.string.settings_feedback_contact_header)) },
                placeholder = { Text(stringResource(R.string.settings_feedback_contact_hint)) },
            )
            SettingsSection(title = stringResource(R.string.settings_feedback_env_header)) {
                envRow(stringResource(R.string.settings_feedback_env_version), version)
                envRow(stringResource(R.string.settings_feedback_env_os), os)
                envRow(stringResource(R.string.settings_feedback_env_device), device)
                envRow(stringResource(R.string.settings_feedback_env_locale), locale)
                SettingsSwitchRow(
                    title = stringResource(R.string.settings_feedback_include_providers),
                    subtitle = if (includeProviders && providers.isNotEmpty()) {
                        stringResource(
                            R.string.settings_feedback_providers_attached,
                            providers.joinToString(stringResource(R.string.settings_list_separator)),
                        )
                    } else {
                        stringResource(R.string.settings_feedback_providers_hint)
                    },
                    checked = includeProviders,
                    onCheckedChange = { includeProviders = it },
                )
            }
            Text(
                text = stringResource(R.string.settings_feedback_env_footer),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
            )
            Spacer(Modifier.height(8.dp))
        }
    }
}

@Composable
private fun categoryTitle(category: FeedbackCategory): String {
    return when (category) {
        FeedbackCategory.Bug -> stringResource(R.string.settings_feedback_cat_bug)
        FeedbackCategory.Idea -> stringResource(R.string.settings_feedback_cat_idea)
        FeedbackCategory.Provider -> stringResource(R.string.settings_feedback_cat_provider)
        FeedbackCategory.Other -> stringResource(R.string.settings_feedback_cat_other)
    }
}

@Composable
private fun envRow(label: String, value: String) {
    ListItem(
        headlineContent = { Text(label) },
        trailingContent = {
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
        modifier = Modifier.clip(SettingsRowShape),
        colors = settingsRowColors(),
    )
}
