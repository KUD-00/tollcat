package com.zhechengqi.tollcat

import androidx.activity.compose.BackHandler
import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.ExposedDropdownMenu
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.dashboard.DashboardHeroHeader
import com.zhechengqi.tollcat.dashboard.dashboardHeroState
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.settings.currencyLabel
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import java.time.Month
import java.time.format.TextStyle
import kotlinx.coroutines.launch

/** 页序按新用户心里冒出来的问题排：这是什么 → 数字从哪来 → 凭据放哪 → 从哪开始。和 iOS 同序。 */
private enum class OnboardingPage(
    @param:StringRes val titleRes: Int,
    @param:StringRes val bodyRes: Int,
) {
    Number(
        titleRes = R.string.onboarding_page_number_title,
        bodyRes = R.string.onboarding_page_number_body,
    ),
    Source(
        titleRes = R.string.onboarding_page_source_title,
        bodyRes = R.string.onboarding_page_source_body,
    ),
    Credentials(
        titleRes = R.string.onboarding_page_credentials_title,
        bodyRes = R.string.onboarding_page_credentials_body,
    ),
    Add(
        titleRes = R.string.onboarding_page_add_title,
        bodyRes = R.string.onboarding_page_add_body,
    ),
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun OnboardingScreen(
    onSkip: () -> Unit,
    onAddFirstProvider: () -> Unit,
    modifier: Modifier = Modifier,
    currencies: List<String> = listOf("USD"),
    selectedCurrency: String = "USD",
    onCurrencyChange: (String) -> Unit = {},
    initialPage: Int = 0,
) {
    val pages = OnboardingPage.entries
    val pagerState = rememberPagerState(initialPage = initialPage.coerceIn(0, pages.lastIndex)) { pages.size }
    val scope = rememberCoroutineScope()
    val last = pagerState.currentPage == pages.lastIndex
    val progress = stringResource(
        R.string.onboarding_progress,
        pagerState.currentPage + 1,
        pages.size,
    )

    BackHandler(enabled = pagerState.currentPage > 0) {
        scope.launch { pagerState.animateScrollToPage(pagerState.currentPage - 1) }
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.surface,
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        text = progress,
                        style = MaterialTheme.typography.labelLarge.copy(fontFeatureSettings = "tnum"),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
                actions = {
                    TextButton(onClick = onSkip, modifier = Modifier.testTag(UITestId.ONBOARDING_SKIP)) {
                        Text(stringResource(R.string.onboarding_skip))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                ),
            )
        },
        bottomBar = {
            Surface(color = MaterialTheme.colorScheme.surfaceContainer) {
                // 底栏底色铺到屏幕底边，按钮本身让开手势条——不然手势条压在按钮上，
                // 按下去一变形就像被底边裁掉一截。
                Box(Modifier.navigationBarsPadding()) {
                    PrimaryButton(
                        onClick = {
                            if (last) {
                                onAddFirstProvider()
                            } else {
                                scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(MeterSpacing.md)
                            .testTag(UITestId.ONBOARDING_NEXT),
                    ) {
                        Text(
                            stringResource(
                                if (last) R.string.onboarding_add_first else R.string.onboarding_continue,
                            ),
                        )
                    }
                }
            }
        },
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize(),
        ) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) { index ->
                OnboardingPageContent(
                    page = pages[index],
                    currencies = currencies,
                    selectedCurrency = selectedCurrency,
                    onCurrencyChange = onCurrencyChange,
                )
            }
            OnboardingDots(
                count = pages.size,
                selected = pagerState.currentPage,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = MeterSpacing.md),
            )
        }
    }
}

/**
 * 标本放在一块固定高的图区里居中，标题从图区下沿开始：四页的标本高矮不一，
 * 标题和正文却钉在同一条线上，翻页时文字不跳。第一页的标本最高，图区按它留够；
 * 放大字号时标本比图区高，就把图区撑开，退回自然排布。和 iOS `phonePageView` 同一个做法。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun OnboardingPageContent(
    page: OnboardingPage,
    currencies: List<String>,
    selectedCurrency: String,
    onCurrencyChange: (String) -> Unit,
) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val stageSlot = maxHeight * OnboardingStageShare
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = MeterSpacing.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = stageSlot),
            ) {
                OnboardingStage(
                    page = page,
                    currencies = currencies,
                    selectedCurrency = selectedCurrency,
                    onCurrencyChange = onCurrencyChange,
                )
            }
            Spacer(Modifier.height(MeterSpacing.lg))
            // 标题和正文合成一个无障碍节点；预览区里的货币下拉要单独能点，不并进来。
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.semantics(mergeDescendants = true) {},
            ) {
                Text(
                    text = stringResource(page.titleRes),
                    style = MaterialTheme.typography.headlineMediumEmphasized,
                    color = MaterialTheme.colorScheme.onSurface,
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(MeterSpacing.sm))
                Text(
                    text = stringResource(page.bodyRes),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
            Spacer(Modifier.height(MeterSpacing.md))
        }
    }
}

/** 图区占页高的比例。按最高的第一页（仪表顶栏 + 货币那一行）在 Pixel 10a 上放得下定的。 */
private const val OnboardingStageShare = 0.56f

@Composable
private fun OnboardingStage(
    page: OnboardingPage,
    currencies: List<String>,
    selectedCurrency: String,
    onCurrencyChange: (String) -> Unit,
) {
    when (page) {
        OnboardingPage.Number -> Column(
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs),
            modifier = Modifier.fillMaxWidth(),
        ) {
            OnboardingDashboardPreview(currency = selectedCurrency)
            // 新用户会把 $43.20 当成自己的账单：「示例数字」和货币下拉挤一行，不另占一段。
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = stringResource(R.string.onboarding_sample_numbers),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .padding(start = MeterSpacing.md)
                        .weight(1f),
                )
                OnboardingCurrencyMenu(
                    currencies = currencies,
                    selected = selectedCurrency,
                    onSelect = onCurrencyChange,
                )
            }
        }
        OnboardingPage.Source -> OnboardingSourcePreview()
        OnboardingPage.Credentials -> OnboardingKeystoreFacts()
        OnboardingPage.Add -> OnboardingAddProviderPreview()
    }
}

/**
 * 开场第 1 页：就是仪表顶上那块主色总数卡（卡片形态），不另画一份缩样——
 * 仪表改了样子，这里跟着变。数字跟着下拉里的币种改写，月份跟着界面语言。
 */
@Composable
private fun OnboardingDashboardPreview(currency: String) {
    val locale = LocalConfiguration.current.locales[0]
    val snapshot = remember(currency, locale) {
        OnboardingDemoContent.heroSnapshot(
            monthTitle = Month.AUGUST.getDisplayName(TextStyle.FULL_STANDALONE, locale),
            format = { usd -> MoneyDisplay.formatUsd(usd, currency) },
        )
    }
    DashboardHeroHeader(
        state = dashboardHeroState(
            dashboard = snapshot,
            filterNote = null,
            includesSubscriptions = false,
            canToggleScope = false,
            nowMillis = OnboardingDemoContent.CLOCK_MILLIS,
        ),
        fullBleed = false,
    )
}

/**
 * 显示货币：一个下拉，不把十几种币平铺成按钮——平铺会把标题和正文挤出首屏。
 * 锚点用文字按钮（有按压反馈、M3E 形变），菜单走 [ExposedDropdownMenuBox] 定位。
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun OnboardingCurrencyMenu(
    currencies: List<String>,
    selected: String,
    onSelect: (String) -> Unit,
) {
    val codes = currencies.ifEmpty { listOf("USD") }
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
        TextButton(
            onClick = { expanded = !expanded },
            shapes = ButtonDefaults.shapes(),
            // 开合交给按钮自己；锚点只管菜单贴在哪。两边都响应会一点就开了又关。
            modifier = Modifier.menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable, enabled = false),
        ) {
            Text(currencyLabel(selected), maxLines = 1, overflow = TextOverflow.Ellipsis)
            Spacer(Modifier.width(MeterSpacing.xxs))
            ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded)
        }
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            matchAnchorWidth = false,
        ) {
            codes.forEach { code ->
                DropdownMenuItem(
                    text = { Text(currencyLabel(code)) },
                    onClick = {
                        onSelect(code)
                        expanded = false
                    },
                    trailingIcon = if (code == selected) {
                        { SymbolIcon(MaterialSymbol.Check, contentDescription = null) }
                    } else {
                        null
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding,
                )
            }
        }
    }
}

/**
 * 开场第 2 页：这台设备直接问各家官方接口。没有对应的屏，用设备符号和真服务图标画一张示意，
 * 中间不画任何云或服务器——那正是这一页要否认的东西。
 */
@Composable
private fun OnboardingSourcePreview() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Row(
            modifier = Modifier
                .padding(MeterSpacing.md)
                .semantics(mergeDescendants = true) {},
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
                modifier = Modifier.weight(1f),
            ) {
                SymbolIcon(
                    MaterialSymbol.Smartphone,
                    contentDescription = null,
                    size = MeterSpacing.brandMark,
                    tint = MaterialTheme.colorScheme.primary,
                )
                Text(
                    text = stringResource(R.string.onboarding_source_this_device),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs),
            ) {
                SymbolIcon(
                    MaterialSymbol.SwapHoriz,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Text(
                    text = stringResource(R.string.onboarding_source_read_only),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Column(
                verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
                modifier = Modifier.weight(1f),
            ) {
                OnboardingDemoContent.sourcePreview.forEach { row ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
                    ) {
                        ServiceGlyph(name = row.name, colorKey = row.id)
                        Text(
                            text = row.name,
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
        }
    }
}

/** 开场第 3 页：三枚符号讲事实，一行一件事。长句留给正文，卡片里不再重复一遍。 */
@Composable
private fun OnboardingKeystoreFacts() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Column(
            modifier = Modifier
                .padding(MeterSpacing.md)
                .semantics(mergeDescendants = true) {},
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        ) {
            OnboardingFactRow(MaterialSymbol.Smartphone, stringResource(R.string.onboarding_fact_this_device))
            OnboardingFactRow(MaterialSymbol.CloudOff, stringResource(R.string.onboarding_fact_no_cloud_backup))
            OnboardingFactRow(MaterialSymbol.Lock, stringResource(R.string.onboarding_fact_unlocked_only))
        }
    }
}

@Composable
private fun OnboardingFactRow(symbol: MaterialSymbol, text: String) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth(),
    ) {
        SymbolIcon(
            symbol,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
        )
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f),
        )
    }
}

/** 开场第 4 页：添加列表的行，带计费方式。只是样子，不能点。 */
@Composable
private fun OnboardingAddProviderPreview() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Column(Modifier.semantics(mergeDescendants = true) {}) {
            OnboardingDemoContent.addPreview.forEach { row ->
                ListItem(
                    leadingContent = { ServiceGlyph(name = row.name, colorKey = row.id) },
                    supportingContent = { Text(stringResource(row.kindRes)) },
                    colors = ListItemDefaults.colors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    ),
                    content = { Text(row.name) },
                )
            }
        }
    }
}

@Composable
private fun OnboardingDots(count: Int, selected: Int, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(count) { index ->
            val selectedDot = index == selected
            Box(
                Modifier
                    .size(if (selectedDot) MeterSpacing.sm else MeterSpacing.xs)
                    .clip(CircleShape)
                    .background(
                        if (selectedDot) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.outlineVariant
                        },
                    ),
            )
        }
    }
}

@Preview(showBackground = true, name = "Light")
@Composable
private fun OnboardingPreviewLight() {
    TollCatTheme {
        OnboardingScreen(
            onSkip = {},
            onAddFirstProvider = {},
            currencies = listOf("USD", "CNY", "JPY"),
        )
    }
}

@Preview(showBackground = true, name = "Dark", uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun OnboardingPreviewDark() {
    TollCatTheme {
        OnboardingScreen(
            onSkip = {},
            onAddFirstProvider = {},
            currencies = listOf("USD", "CNY", "JPY"),
        )
    }
}

@Preview(showBackground = true, name = "Source Light")
@Preview(showBackground = true, name = "Source Dark", uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun OnboardingSourcePagePreview() {
    TollCatTheme {
        OnboardingScreen(
            onSkip = {},
            onAddFirstProvider = {},
            initialPage = 1,
        )
    }
}

@Preview(showBackground = true, name = "Credentials Light")
@Preview(showBackground = true, name = "Credentials Dark", uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun OnboardingCredentialsPagePreview() {
    TollCatTheme {
        OnboardingScreen(
            onSkip = {},
            onAddFirstProvider = {},
            initialPage = 2,
        )
    }
}

@Preview(showBackground = true, name = "Add Light")
@Preview(showBackground = true, name = "Add Dark", uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun OnboardingAddPagePreview() {
    TollCatTheme {
        OnboardingScreen(
            onSkip = {},
            onAddFirstProvider = {},
            initialPage = 3,
        )
    }
}
