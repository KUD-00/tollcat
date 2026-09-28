package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.BudgetRow
import com.zhechengqi.tollcat.CategorySliceRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SubscriptionModuleItem
import com.zhechengqi.tollcat.SubscriptionsModuleRow
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.BudgetModuleView
import com.zhechengqi.tollcat.dashboard.CategoriesModuleView
import com.zhechengqi.tollcat.dashboard.HeatmapModuleView
import com.zhechengqi.tollcat.dashboard.PinnedServicesModuleView
import com.zhechengqi.tollcat.dashboard.SubscriptionsModuleCard
import com.zhechengqi.tollcat.dashboard.SuperlativesModuleView
import com.zhechengqi.tollcat.developer.DashboardLabFixtures

/** 编辑面里可以打开的那几块：设计稿数字 + 几种边界（年付、类别很多、预算快满 / 超了）。 */
@Composable
fun GalleryModulesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val fixtures = DashboardLabFixtures.contents
    GalleryScaffold(title = stringResource(R.string.dev_gallery_modules), onBack = onBack, modifier = modifier) {
        GalleryExhibit(title = "固定订阅：月付 + 年付（年付按 12 摊进大数字）") {
            SubscriptionsModuleCard(
                module = SubscriptionsModuleRow(
                    monthlyTotalText = "$5.67",
                    countCaption = "2 笔，折算每月。年付按 12 摊。",
                    nextChargeCaption = null,
                    items = listOf(
                        SubscriptionModuleItem("a", "ChatGPT Plus", "$20.00", "每年", "", "openai", "openai", 1),
                        SubscriptionModuleItem("b", "GitHub Team", "$4.00", "每月", "", "github", "github", 1),
                    ),
                ),
                onOpen = {},
            )
        }
        GalleryExhibit(title = "日历热力图：格子靠左，文字在右") {
            HeatmapModuleView(fixtures.heatmap, onOpen = {})
        }
        GalleryExhibit(title = "按类别：和构成同一张粗条卡，条头是类别图标") {
            CategoriesModuleView(fixtures.categories, onOpen = {})
        }
        GalleryExhibit(title = "按类别：类别很多时尾巴合成「其他」") {
            CategoriesModuleView(
                listOf(
                    CategorySliceRow("hosting", "$21.40", 30, 0.30f, "aws", listOf("AWS")),
                    CategorySliceRow("aiInference", "$14.00", 20, 0.20f, "openai", listOf("OpenAI")),
                    CategorySliceRow("database", "$10.00", 14, 0.14f, "neon", listOf("Neon")),
                    CategorySliceRow("networkEdge", "$9.00", 13, 0.13f, "cloudflare", listOf("Cloudflare")),
                    CategorySliceRow("observability", "$7.00", 10, 0.10f, "", listOf("Sentry")),
                    CategorySliceRow("ciCd", "$5.00", 7, 0.07f, "github", listOf("GitHub")),
                    CategorySliceRow("messaging", "$4.00", 6, 0.06f, "", listOf("Twilio")),
                ),
                onOpen = {},
            )
        }
        GalleryExhibit(title = "预算线：还早") {
            BudgetModuleView(BudgetRow("$21.40", "$80.00", "$58.60", "$0.00", 0.27f, usedPercent = 27, isOver = false, isClose = false))
        }
        GalleryExhibit(title = "预算线：快满了") {
            BudgetModuleView(BudgetRow("$72.00", "$80.00", "$8.00", "$0.00", 0.9f, usedPercent = 90, isOver = false, isClose = true))
        }
        GalleryExhibit(title = "预算线：超了（竖标是预算那条线，红色斜纹是超出的部分）") {
            BudgetModuleView(BudgetRow("$91.30", "$80.00", "$0.00", "$11.30", 1.14f, usedPercent = 114, isOver = true, isClose = true))
        }
        GalleryExhibit(title = "预算线：超了很多") {
            BudgetModuleView(BudgetRow("$160.00", "$80.00", "$0.00", "$80.00", 2f, usedPercent = 200, isOver = true, isClose = true))
        }
        GalleryExhibit(title = "之最") {
            SuperlativesModuleView(fixtures.superlatives, onOpen = {})
        }
        GalleryExhibit(title = "服务一览（钉住的账号）") {
            PinnedServicesModuleView(fixtures.pinnedServices, onOpen = {})
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryModulesViewPreview() {
    TollCatTheme {
        GalleryModulesView(onBack = {})
    }
}
