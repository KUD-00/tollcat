package com.zhechengqi.tollcat.developer.gallery

import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R

@Composable
fun GalleryCredentialFieldsView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    var token by remember { mutableStateOf("") }
    var account by remember { mutableStateOf("") }
    GalleryScaffold(
        title = stringResource(R.string.dev_gallery_fields),
        onBack = onBack,
        modifier = modifier,
    ) {
        OutlinedTextField(
            value = token,
            onValueChange = { token = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("API Token") },
            singleLine = true,
            trailingIcon = {
                TextButton(onClick = { paste(context)?.let { token = it } }) {
                    Text(stringResource(R.string.action_paste))
                }
            },
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = account,
            onValueChange = { account = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Account ID") },
            singleLine = true,
            trailingIcon = {
                TextButton(onClick = { paste(context)?.let { account = it } }) {
                    Text(stringResource(R.string.action_paste))
                }
            },
        )
        Spacer(Modifier.height(12.dp))
        Text(
            stringResource(R.string.dev_fields_footer),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun paste(context: Context): String? {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val text = clipboard.primaryClip?.getItemAt(0)?.coerceToText(context)?.toString() ?: return null
    return text.trim().takeIf { it.isNotEmpty() }
}
