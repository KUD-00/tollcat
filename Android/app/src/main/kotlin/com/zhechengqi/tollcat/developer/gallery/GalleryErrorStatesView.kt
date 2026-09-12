package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.GuideErrorCase
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.services.ServiceRow
import com.zhechengqi.tollcat.services.ServiceRowUi
import com.zhechengqi.tollcat.setup.SetupVerifyOutcome
import com.zhechengqi.tollcat.setup.SetupVerifyResultView
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.StatusBanner
import com.zhechengqi.tollcat.ui.StatusTone
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

@Composable
fun GalleryErrorStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(title = stringResource(R.string.dev_gallery_errors), onBack = onBack, modifier = modifier) {
        GalleryExhibit("401") {
            SetupVerifyResultView(
                SetupVerifyOutcome.Http(
                    GuideErrorCase(
                        401,
                        stringResource(R.string.dev_err_401),
                        stringResource(R.string.dev_err_401_next),
                    ),
                ),
            )
        }
        GalleryExhibit("403") {
            SetupVerifyResultView(
                SetupVerifyOutcome.Http(
                    GuideErrorCase(
                        403,
                        stringResource(R.string.dev_err_403),
                        stringResource(R.string.dev_err_403_next),
                    ),
                ),
            )
        }
        GalleryExhibit(stringResource(R.string.dev_err_network)) {
            SetupVerifyResultView(SetupVerifyOutcome.Network)
        }
        GalleryExhibit(stringResource(R.string.dev_err_empty)) {
            SetupVerifyResultView(SetupVerifyOutcome.EmptyReading)
        }
        GalleryExhibit(stringResource(R.string.dev_err_stale)) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ServiceRow(
                    row = ServiceRowUi(
                        providerId = "cloudflare",
                        displayName = "Cloudflare",
                        colorKey = "cloudflare",
                        kind = "usage",
                        category = "networkEdge",
                        amountText = "$11.05",
                        amountValue = 11.05,
                        subtitle = stringResource(R.string.dev_err_stale_sub),
                        usesSecondaryValue = false,
                    ),
                    onClick = {},
                    hint = stringResource(R.string.services_stale),
                    shape = Bento.solo,
                )
                StatusBanner(
                    title = stringResource(R.string.services_stale),
                    symbol = MaterialSymbol.Sync,
                    tone = StatusTone.Caution,
                    body = stringResource(R.string.dev_err_stale_note),
                )
            }
        }
        GalleryExhibit(stringResource(R.string.dev_err_disk)) {
            StatusBanner(
                title = stringResource(R.string.dev_err_disk),
                symbol = MaterialSymbol.Storage,
                tone = StatusTone.Error,
                body = stringResource(R.string.dev_err_disk_body),
            )
        }
    }
}
