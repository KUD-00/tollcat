package com.zhechengqi.tollcat.setup

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.GuideErrorCase
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.StatusBanner
import com.zhechengqi.tollcat.ui.StatusTone
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

@Composable
fun SetupVerifyResultView(
    outcome: SetupVerifyOutcome,
    modifier: Modifier = Modifier,
    onRevisePermissions: (() -> Unit)? = null,
) {
    val tone = when (outcome) {
        is SetupVerifyOutcome.Success -> StatusTone.Success
        SetupVerifyOutcome.EmptyReading -> StatusTone.Caution
        is SetupVerifyOutcome.Http -> if (outcome.errorCase.httpStatus == 401) {
            StatusTone.Error
        } else {
            StatusTone.Caution
        }
        SetupVerifyOutcome.Network -> StatusTone.Neutral
        SetupVerifyOutcome.Unknown -> StatusTone.Error
    }
    val symbol = when (outcome) {
        is SetupVerifyOutcome.Success -> MaterialSymbol.CheckCircle
        SetupVerifyOutcome.EmptyReading -> MaterialSymbol.Info
        is SetupVerifyOutcome.Http -> if (outcome.errorCase.httpStatus == 401) {
            MaterialSymbol.Error
        } else {
            MaterialSymbol.Lock
        }
        SetupVerifyOutcome.Network -> MaterialSymbol.Warning
        SetupVerifyOutcome.Unknown -> MaterialSymbol.Error
    }
    val title = when (outcome) {
        is SetupVerifyOutcome.Success -> outcome.title
        SetupVerifyOutcome.EmptyReading -> stringResource(R.string.setup_verify_empty_title)
        is SetupVerifyOutcome.Http -> outcome.errorCase.httpStatus.toString()
        SetupVerifyOutcome.Network -> stringResource(R.string.setup_verify_network_title)
        SetupVerifyOutcome.Unknown -> stringResource(R.string.setup_verify_unknown_title)
    }
    val body = when (outcome) {
        is SetupVerifyOutcome.Success -> outcome.detail
        SetupVerifyOutcome.EmptyReading -> stringResource(R.string.setup_verify_empty_body)
        is SetupVerifyOutcome.Http -> outcome.errorCase.explanation
        SetupVerifyOutcome.Network -> stringResource(R.string.setup_verify_network_body)
        SetupVerifyOutcome.Unknown -> stringResource(R.string.setup_verify_unknown_body)
    }
    val nextStep = when (outcome) {
        is SetupVerifyOutcome.Success -> null
        SetupVerifyOutcome.EmptyReading -> stringResource(R.string.setup_verify_empty_next)
        is SetupVerifyOutcome.Http -> outcome.errorCase.nextStep
        SetupVerifyOutcome.Network -> stringResource(R.string.setup_verify_network_next)
        SetupVerifyOutcome.Unknown -> stringResource(R.string.setup_verify_unknown_next)
    }
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs)) {
        StatusBanner(
            title = title,
            symbol = symbol,
            tone = tone,
            body = body,
            nextStep = nextStep,
        )
        if (outcome.offersRevisePermissions && onRevisePermissions != null) {
            TextButton(onClick = onRevisePermissions) {
                Text(stringResource(R.string.setup_revise_permissions))
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupVerifyResultViewPreview() {
    TollCatTheme {
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SetupVerifyResultView(
                SetupVerifyOutcome.Success("本周期至今 $11.05", "周期 8/1 – 8/31 · 日粒度可用"),
            )
            SetupVerifyResultView(
                SetupVerifyOutcome.Http(
                    GuideErrorCase(401, "这个 token 无效，或者已经被撤销了。", "回上一步重新创建一把，创建后立刻复制。"),
                ),
                onRevisePermissions = {},
            )
            SetupVerifyResultView(SetupVerifyOutcome.EmptyReading)
            SetupVerifyResultView(SetupVerifyOutcome.Network)
        }
    }
}
