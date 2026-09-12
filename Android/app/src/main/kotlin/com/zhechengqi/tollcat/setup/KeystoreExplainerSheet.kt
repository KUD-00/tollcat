package com.zhechengqi.tollcat.setup

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.TollCatSheet

@Composable
fun KeystoreExplainerSheet(onDismiss: () -> Unit) {
    TollCatSheet(onDismiss = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = stringResource(R.string.services_keystore_what),
                style = MaterialTheme.typography.headlineSmall,
            )
            Text(stringResource(R.string.services_keystore_body_1), style = MaterialTheme.typography.bodyLarge)
            Text(stringResource(R.string.services_keystore_body_2), style = MaterialTheme.typography.bodyLarge)
            Text(stringResource(R.string.services_keystore_body_3), style = MaterialTheme.typography.bodyLarge)
        }
    }
}
