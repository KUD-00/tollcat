package com.zhechengqi.tollcat

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.zhechengqi.tollcat.setup.SetupWizard

@Composable
fun SetupCredentialsScreen(
    session: TollCatSession,
    providerId: String,
    accountId: String,
    modifier: Modifier = Modifier,
) {
    SetupWizard(
        session = session,
        providerId = providerId,
        accountId = accountId,
        modifier = modifier,
    )
}
