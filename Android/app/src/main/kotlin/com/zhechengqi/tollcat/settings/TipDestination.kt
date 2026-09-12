package com.zhechengqi.tollcat.settings

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.res.Configuration
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatView
import java.text.DateFormat
import java.util.Date

@Composable
fun TipDestination(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val model = remember { TipModel(context.applicationContext) }
    DisposableEffect(model) {
        model.start()
        onDispose {
            model.abandonComposerIfNeeded()
            model.release()
        }
    }
    TipContent(
        model = model,
        activity = context.findActivity(),
        onBack = onBack,
        modifier = modifier,
    )
}

@Composable
private fun TipContent(
    model: TipModel,
    activity: Activity?,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val reduceMotion = LocalReduceMotion.current
    val catSize by animateDpAsState(
        targetValue = if (model.composerVisible) 128.dp else 88.dp,
        animationSpec = if (reduceMotion) snap() else spring(),
        label = "tip-cat",
    )
    val catLabel = stringResource(
        if (model.composerVisible) {
            R.string.settings_tip_cat_celebrating
        } else {
            R.string.settings_tip_cat_waiting
        },
    )
    SettingsScaffold(
        title = stringResource(R.string.settings_tip),
        onBack = onBack,
        modifier = modifier,
        bottomBar = {
            if (model.composerVisible) {
                PrimaryButton(
                    onClick = { model.submitComposer() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                ) {
                    Text(stringResource(R.string.settings_tip_send))
                }
            }
        },
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 16.dp),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                CatView(
                    mood = if (model.composerVisible) CatMood.Saved else CatMood.Normal,
                    size = catSize,
                    modifier = Modifier.semantics { contentDescription = catLabel },
                )
                if (model.composerVisible) {
                    val copy = model.thanks
                    Text(
                        text = stringResource(copy.headlineRes),
                        style = MaterialTheme.typography.titleLarge,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(top = 8.dp),
                    )
                    Text(
                        text = stringResource(copy.noteRes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }
            }
            if (model.composerVisible) {
                ComposerSection(model)
            } else {
                ProductsSection(model = model, activity = activity)
                HistorySection(model)
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun ProductsSection(model: TipModel, activity: Activity?) {
    val stacked = LocalDensity.current.fontScale >= 1.3f
    when (model.catalogState) {
        TipModel.CatalogState.Loading -> Unit
        TipModel.CatalogState.Unavailable -> {
            SettingsGroup {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = stringResource(R.string.settings_tip_store_unavailable),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    Text(
                        text = stringResource(R.string.settings_tip_store_unavailable_body),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 8.dp),
                    )
                    PrimaryButton(
                        onClick = { model.start() },
                        modifier = Modifier.padding(top = 12.dp),
                    ) {
                        Text(stringResource(R.string.settings_tip_retry))
                    }
                }
            }
        }
        TipModel.CatalogState.Ready -> {
            SettingsGroup {
                if (stacked) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        model.offerings.forEach { offering ->
                            OfferingButton(
                                offering = offering,
                                layout = OfferingLayout.Row,
                                enabled = !model.isPurchasing,
                                onClick = { activity?.let { model.buy(it, offering) } },
                            )
                        }
                    }
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.Bottom,
                    ) {
                        model.offerings.forEach { offering ->
                            OfferingButton(
                                offering = offering,
                                layout = OfferingLayout.Column,
                                enabled = !model.isPurchasing,
                                onClick = { activity?.let { model.buy(it, offering) } },
                                modifier = Modifier.weight(1f),
                            )
                        }
                    }
                }
            }
        }
    }
    val footer = when {
        model.isPurchasing -> stringResource(R.string.settings_tip_purchasing)
        model.catalogState == TipModel.CatalogState.Loading -> stringResource(R.string.settings_tip_loading)
        model.catalogState == TipModel.CatalogState.Unavailable -> {
            stringResource(R.string.settings_tip_store_unavailable_footer)
        }
        else -> stringResource(R.string.settings_tip_hint)
    }
    Text(
        text = footer,
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
    )
    model.purchaseNotice?.let { notice ->
        Text(
            text = stringResource(notice.copyRes),
            style = MaterialTheme.typography.bodyMedium,
            color = if (notice == TipPurchaseNotice.Cancelled) {
                MaterialTheme.colorScheme.onSurfaceVariant
            } else {
                MaterialTheme.colorScheme.error
            },
            modifier = Modifier.padding(horizontal = 32.dp),
        )
    }
}

private enum class OfferingLayout { Column, Row }

@Composable
private fun OfferingButton(
    offering: TipOffering,
    layout: OfferingLayout,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val kind = offering.productID?.treat ?: TipTreatKind.Candy
    val spoken = "${offering.displayName}，${offering.displayPrice}"
    val hint = stringResource(R.string.settings_tip_buy_hint)
    val body = @Composable {
        when (layout) {
            OfferingLayout.Column -> {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                ) {
                    TipTreatView(kind = kind, size = 76.dp)
                    Text(
                        text = offering.displayName,
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center,
                        maxLines = 2,
                    )
                    Text(
                        text = offering.displayPrice,
                        style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
            }
            OfferingLayout.Row -> {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp, horizontal = 4.dp),
                ) {
                    TipTreatView(kind = kind, size = 76.dp)
                    Column {
                        Text(offering.displayName, style = MaterialTheme.typography.bodyLarge)
                        Text(
                            text = offering.displayPrice,
                            style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                            color = MaterialTheme.colorScheme.primary,
                        )
                    }
                }
            }
        }
    }
    Column(
        modifier = modifier
            .clip(SettingsRowShape)
            .clickable(enabled = enabled, onClick = onClick)
            .semantics(mergeDescendants = true) {
                contentDescription = "$spoken. $hint"
                role = Role.Button
            }
            .padding(4.dp),
    ) {
        body()
    }
}

@Composable
private fun ComposerSection(model: TipModel) {
    OutlinedTextField(
        value = model.draftName,
        onValueChange = { value ->
            model.draftName = value.take(TipFieldLimits.NAME)
        },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        singleLine = true,
        label = { Text(stringResource(R.string.settings_tip_name_label)) },
    )
    OutlinedTextField(
        value = model.draftMessage,
        onValueChange = { value ->
            model.draftMessage = value.take(TipFieldLimits.MESSAGE)
        },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        minLines = 3,
        maxLines = 6,
        label = { Text(stringResource(R.string.settings_tip_message_label)) },
    )
    Text(
        text = stringResource(R.string.settings_tip_composer_footer),
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
    )
    if (model.willRetryMessage) {
        Text(
            text = stringResource(R.string.settings_tip_will_retry),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 32.dp),
        )
    }
}

@Composable
private fun HistorySection(model: TipModel) {
    SettingsSection(title = stringResource(R.string.settings_tip_history)) {
        if (model.records.isEmpty()) {
            ListItem(
                headlineContent = {
                    Text(
                        text = stringResource(R.string.settings_tip_history_empty),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
                modifier = Modifier.clip(SettingsRowShape),
                colors = settingsRowColors(),
            )
        } else {
            val formatter = remember {
                DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT)
            }
            model.records.forEach { item ->
                val title = if (item.productTitleRes != 0) {
                    stringResource(item.productTitleRes)
                } else {
                    item.productID
                }
                ListItem(
                    headlineContent = {
                        Row(modifier = Modifier.fillMaxWidth()) {
                            Text(title, style = MaterialTheme.typography.bodyLarge)
                            Spacer(Modifier.weight(1f))
                            Text(
                                text = item.displayPrice,
                                style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    },
                    supportingContent = {
                        Column {
                            Text(
                                text = formatter.format(Date(item.purchasedAtMillis)),
                                style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                            )
                            item.name?.takeIf { it.isNotEmpty() }?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
                            item.message?.takeIf { it.isNotEmpty() }?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
                            if (!item.isSubmitted) {
                                Text(
                                    text = stringResource(R.string.settings_tip_unsent),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.outline,
                                )
                            }
                        }
                    },
                    modifier = Modifier
                        .clip(SettingsRowShape)
                        .semantics(mergeDescendants = true) {},
                    colors = settingsRowColors(),
                )
            }
        }
    }
}

private val TipPurchaseNotice.copyRes: Int
    get() = when (this) {
        TipPurchaseNotice.Cancelled -> R.string.settings_tip_cancelled
        TipPurchaseNotice.Pending -> R.string.settings_tip_pending
        TipPurchaseNotice.Failed -> R.string.settings_tip_failed
    }

private fun Context.findActivity(): Activity? {
    var current: Context = this
    while (current is ContextWrapper) {
        if (current is Activity) return current
        current = current.baseContext
    }
    return null
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TipReadyPreview() {
    val context = LocalContext.current
    TollCatTheme {
        TipContent(
            model = remember { TipModel.preview(context) },
            activity = null,
            onBack = {},
        )
    }
}

@Preview(name = "Unavailable", showBackground = true)
@Composable
private fun TipUnavailablePreview() {
    val context = LocalContext.current
    TollCatTheme {
        TipContent(
            model = remember { TipModel.preview(context, unavailable = true) },
            activity = null,
            onBack = {},
        )
    }
}

@Preview(name = "History", showBackground = true)
@Preview(name = "History Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TipHistoryPreview() {
    val context = LocalContext.current
    TollCatTheme {
        TipContent(
            model = remember { TipModel.preview(context, seedHistory = true) },
            activity = null,
            onBack = {},
        )
    }
}

@Preview(name = "Composer", showBackground = true)
@Composable
private fun TipComposerPreview() {
    val context = LocalContext.current
    val model = remember {
        TipModel.preview(context, seedHistory = true).also { it.previewOpenComposer() }
    }
    TollCatTheme {
        TipContent(model = model, activity = null, onBack = {})
    }
}
