package com.zhechengqi.tollcat

import androidx.activity.compose.BackHandler
import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilterChip
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.dashboard.CompositionTones
import com.zhechengqi.tollcat.dashboard.DashboardPreviewData
import com.zhechengqi.tollcat.dashboard.MonthToDateModuleView
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.settings.currencyLabel
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatView
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import kotlinx.coroutines.launch

private enum class OnboardingPage(
    @param:StringRes val titleRes: Int,
    @param:StringRes val bodyRes: Int,
) {
    Number(
        titleRes = R.string.onboarding_page_number_title,
        bodyRes = R.string.onboarding_page_number_body,
    ),
    Credentials(
        titleRes = R.string.onboarding_page_credentials_title,
        bodyRes = R.string.onboarding_page_credentials_body,
    ),
    Widget(
        titleRes = R.string.onboarding_page_widget_title,
        bodyRes = R.string.onboarding_page_widget_body,
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

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun OnboardingPageContent(
    page: OnboardingPage,
    currencies: List<String>,
    selectedCurrency: String,
    onCurrencyChange: (String) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = MeterSpacing.xl)
            .semantics(mergeDescendants = true) {},
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(MeterSpacing.md))
        OnboardingStage(
            page = page,
            currencies = currencies,
            selectedCurrency = selectedCurrency,
            onCurrencyChange = onCurrencyChange,
        )
        Spacer(Modifier.height(MeterSpacing.xxl))
        Text(
            text = stringResource(page.titleRes),
            style = MaterialTheme.typography.headlineLargeEmphasized,
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
        Spacer(Modifier.height(MeterSpacing.md))
    }
}

@Composable
private fun OnboardingStage(
    page: OnboardingPage,
    currencies: List<String>,
    selectedCurrency: String,
    onCurrencyChange: (String) -> Unit,
) {
    when (page) {
        OnboardingPage.Number -> Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
            modifier = Modifier.fillMaxWidth(),
        ) {
            OnboardingDashboardPreview()
            OnboardingCurrencyPicker(
                currencies = currencies,
                selected = selectedCurrency,
                onSelect = onCurrencyChange,
            )
        }
        OnboardingPage.Credentials -> OnboardingKeystoreFacts()
        OnboardingPage.Widget -> OnboardingWidgetPreview()
        OnboardingPage.Add -> OnboardingAddProviderPreview()
    }
}

@Composable
private fun OnboardingDashboardPreview() {
    val snapshot = DashboardPreviewData.snapshot
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
    ) {
        MonthToDateModuleView(
            amountText = snapshot.formattedVariable.ifBlank { snapshot.formattedTotal },
            monthTitle = snapshot.monthTitle,
            projectedCaption = stringResource(R.string.projected_caption, snapshot.formattedProjected),
            subscriptionCaption = snapshot.subscriptionFormatted?.let {
                stringResource(R.string.dashboard_subscription_excluded, it)
            },
            currencyNote = null,
            filterNote = null,
        )
        OnboardingCompositionStrip()
    }
}

@Composable
private fun OnboardingCompositionStrip() {
    val rows = DashboardPreviewData.snapshot.composition
    if (rows.isEmpty()) return
    val total = rows.sumOf { it.fraction.coerceAtLeast(0.01f).toDouble() }.toFloat().coerceAtLeast(0.01f)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(MeterSpacing.sm)
            .clip(MaterialTheme.shapes.small),
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.budgetBlockGap),
    ) {
        rows.forEachIndexed { index, row ->
            Box(
                Modifier
                    .weight(row.fraction.coerceAtLeast(0.01f) / total)
                    .fillMaxHeight()
                    .background(CompositionTones.color(index)),
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun OnboardingCurrencyPicker(
    currencies: List<String>,
    selected: String,
    onSelect: (String) -> Unit,
) {
    val codes = currencies.ifEmpty { listOf("USD") }
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            text = stringResource(R.string.settings_currency),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurface,
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        ) {
            codes.forEach { code ->
                FilterChip(
                    selected = code == selected,
                    onClick = { onSelect(code) },
                    label = { Text(currencyLabel(code)) },
                )
            }
        }
    }
}

@Composable
private fun OnboardingKeystoreFacts() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Column(
            modifier = Modifier.padding(MeterSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        ) {
            OnboardingFactRow(
                symbol = MaterialSymbol.Lock,
                text = stringResource(R.string.setup_keystore_note),
            )
            OnboardingFactRow(
                symbol = MaterialSymbol.Storage,
                text = stringResource(R.string.services_keystore_body_2),
            )
        }
    }
}

@Composable
private fun OnboardingFactRow(symbol: MaterialSymbol, text: String) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
        verticalAlignment = Alignment.Top,
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

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun OnboardingWidgetPreview() {
    val payload = WidgetSnapshot.designSpec
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Column(
            modifier = Modifier.padding(MeterSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = payload.monthTitle,
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1f),
                )
                CatView(mood = CatMood.Normal, size = MeterSpacing.brandMark, isAnimated = false)
            }
            Text(
                text = payload.formattedTotal,
                style = MaterialTheme.typography.headlineLargeEmphasized.copy(fontFeatureSettings = "tnum"),
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Text(
                text = stringResource(R.string.projected_caption, payload.formattedProjected),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(MeterSpacing.xs))
            OnboardingCompositionStrip()
        }
    }
}

@Composable
private fun OnboardingAddProviderPreview() {
    val rows = listOf(
        "AWS" to "aws",
        "Cloudflare" to "cloudflare",
        "OpenAI" to "openai",
        "GitHub" to "github",
    )
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Column {
            rows.forEach { (name, key) ->
                ListItem(
                    leadingContent = { ServiceGlyph(name = name, colorKey = key) },
                    colors = ListItemDefaults.colors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    ),
                    content = { Text(name) },
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

@Preview(showBackground = true, name = "Widget Light")
@Preview(showBackground = true, name = "Widget Dark", uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun OnboardingWidgetPagePreview() {
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
