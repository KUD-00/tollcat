package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.GuideErrorCase
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.setup.SetupVerifyOutcome
import com.zhechengqi.tollcat.setup.SetupVerifyResultView
import com.zhechengqi.tollcat.ui.FillProgressButton
import com.zhechengqi.tollcat.ui.FillProgressPhase
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun GalleryVerifyConnectionView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var token by remember { mutableStateOf("gallery") }
    var account by remember { mutableStateOf("gallery") }
    var phase by remember { mutableStateOf(FillProgressPhase.Idle) }
    var outcome by remember { mutableStateOf<SetupVerifyOutcome?>(null) }
    var runID by remember { mutableIntStateOf(0) }
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val okTitle = stringResource(R.string.setup_verify_period_spend, "$11.05")
    val okDetail = stringResource(
        R.string.setup_verify_period_detail,
        "8/1",
        "8/31",
        stringResource(R.string.setup_verify_daily),
    )
    val failCase = GuideErrorCase(
        401,
        stringResource(R.string.setup_verify_401_body),
        stringResource(R.string.setup_verify_401_next),
    )
    val busy = phase == FillProgressPhase.Progressing
    fun run(succeed: Boolean) {
        runID += 1
        val id = runID
        outcome = null
        phase = FillProgressPhase.Progressing
        scope.launch {
            delay(1200)
            if (id != runID) return@launch
            if (succeed) {
                outcome = SetupVerifyOutcome.Success(okTitle, okDetail)
                phase = FillProgressPhase.Completed
            } else {
                outcome = SetupVerifyOutcome.Http(failCase)
                phase = FillProgressPhase.Idle
                haptic.performHapticFeedback(HapticFeedbackType.Reject)
            }
        }
    }
    fun reset() {
        runID += 1
        phase = FillProgressPhase.Idle
        outcome = null
    }
    GalleryScaffold(
        title = stringResource(R.string.dev_gallery_verify),
        onBack = onBack,
        modifier = modifier,
    ) {
        Text(stringResource(R.string.dev_verify_ok), style = MaterialTheme.typography.titleSmall)
        SetupVerifyResultView(SetupVerifyOutcome.Success(okTitle, okDetail))
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.dev_verify_fail), style = MaterialTheme.typography.titleSmall)
        SetupVerifyResultView(SetupVerifyOutcome.Http(failCase))
        Spacer(Modifier.height(16.dp))
        OutlinedTextField(
            value = token,
            onValueChange = { token = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("API Token") },
            singleLine = true,
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = account,
            onValueChange = { account = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Account ID") },
            singleLine = true,
        )
        outcome?.let { shown ->
            Spacer(Modifier.height(12.dp))
            SetupVerifyResultView(shown)
        }
        Spacer(Modifier.height(12.dp))
        FillProgressButton(
            text = stringResource(
                if (phase == FillProgressPhase.Completed) {
                    R.string.action_save_credentials
                } else {
                    R.string.action_test_connection
                },
            ),
            phase = phase,
            onClick = { run(succeed = true) },
            modifier = Modifier.fillMaxWidth(),
            enabled = phase != FillProgressPhase.Completed && token.isNotEmpty() && account.isNotEmpty(),
        )
        TextButton(onClick = { run(succeed = true) }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.dev_verify_ok))
        }
        TextButton(onClick = { run(succeed = false) }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.dev_verify_fail))
        }
        TextButton(onClick = { reset() }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.dev_verify_reset))
        }
        Spacer(Modifier.height(8.dp))
        Text(
            stringResource(R.string.dev_verify_footer),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryVerifyConnectionViewPreview() {
    TollCatTheme {
        GalleryVerifyConnectionView(onBack = {})
    }
}
