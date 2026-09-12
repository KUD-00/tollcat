package com.zhechengqi.tollcat.share

import android.content.res.Configuration
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme

@Composable
fun ShareCardPreviewImage(
    content: ShareCardContent,
    modifier: Modifier = Modifier,
) {
    val bitmap = remember(content) { ShareCardBitmap.render(content) }
    Image(
        bitmap = bitmap.asImageBitmap(),
        contentDescription = null,
        modifier = modifier.fillMaxWidth(),
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ShareCardPreview() {
    TollCatTheme {
        ShareCardPreviewImage(
            content = ShareCardContent.preview(
                periodTitle = "八月",
                tagline = stringResource(R.string.share_card_tagline),
            ),
            modifier = Modifier.padding(16.dp),
        )
    }
}
