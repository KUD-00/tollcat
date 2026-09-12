package com.zhechengqi.tollcat.settings

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.TollCatSheet

/** 系统通知框只能弹一次。打开前先把「会收到什么、为什么值得开」讲清楚。 */
@Composable
fun ReminderOptInSheet(
    onAllow: () -> Unit,
    onDecline: () -> Unit,
) {
    TollCatSheet(onDismiss = onDecline) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_reminder_opt_in_title),
                style = MaterialTheme.typography.headlineSmall,
            )
            Text(
                text = stringResource(R.string.settings_reminder_opt_in_body),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            ReminderNotificationPreview()
            Spacer(Modifier.height(4.dp))
            PrimaryButton(
                onClick = onAllow,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.settings_reminder_opt_in_allow))
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

@Preview(name = "Light")
@Preview(name = "Dark", uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ReminderOptInSheetPreview() {
    TollCatTheme {
        ReminderOptInSheet(onAllow = {}, onDecline = {})
    }
}
