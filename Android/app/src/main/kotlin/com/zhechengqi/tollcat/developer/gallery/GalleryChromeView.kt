package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.AppShortNavigationBar
import com.zhechengqi.tollcat.AppTab
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.DashboardFabMenu
import com.zhechengqi.tollcat.dashboard.DashboardFabScrim

/** 底部操作：FAB 菜单（能点开收起）和横排的短导航栏，放在一块「手机下半截」里看。 */
@Composable
fun GalleryChromeView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var expanded by remember { mutableStateOf(false) }
    var tab by remember { mutableStateOf(AppTab.Dashboard) }
    GalleryScaffold(title = stringResource(R.string.dev_gallery_chrome), onBack = onBack, modifier = modifier) {
        GalleryExhibit(title = "点 FAB：三项竖着长出来，加号转成叉；点遮罩或返回收起") {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(420.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(MaterialTheme.colorScheme.surfaceContainerLow),
            ) {
                DashboardFabScrim(expanded = expanded, onDismiss = { expanded = false })
                DashboardFabMenu(
                    expanded = expanded,
                    onExpandedChange = { expanded = it },
                    onAddService = {},
                    onAddSubscription = {},
                    onEditDashboard = {},
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(bottom = 96.dp, end = 16.dp),
                )
                AppShortNavigationBar(
                    tab = tab,
                    onSelect = { tab = it },
                    modifier = Modifier.align(Alignment.BottomCenter),
                )
            }
        }
        GalleryExhibit(title = "短导航栏单独看：图标和文字横排，选中的是药丸") {
            AppShortNavigationBar(tab = tab, onSelect = { tab = it })
            Text(
                "平板和折叠屏展开时换成侧边 rail，这一条只在手机宽度出现。",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 8.dp),
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryChromeViewPreview() {
    TollCatTheme {
        GalleryChromeView(onBack = {})
    }
}
