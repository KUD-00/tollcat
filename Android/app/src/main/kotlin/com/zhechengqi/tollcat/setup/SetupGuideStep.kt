package com.zhechengqi.tollcat.setup

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CatalogField
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.GuidePart
import com.zhechengqi.tollcat.GuideStep
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SetupGuideDoc
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.BentoGroup
import com.zhechengqi.tollcat.ui.EmptyState
import com.zhechengqi.tollcat.ui.EmptyStateGlyph
import com.zhechengqi.tollcat.ui.EmptyStateSize
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

/**
 * 向导教程页。内容和 iOS `SetupGuideStepView` 同一份 catalog：
 * 计费事实一组，每段凭据一组步骤。没有教程时走 [EmptyState]。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SetupGuideStep(
    provider: CatalogProvider,
    guide: SetupGuideDoc?,
    modifier: Modifier = Modifier,
) {
    val fields = guide?.fields.orEmpty().ifEmpty { provider.fields }
    val missing = guide == null || guide.parts.isEmpty()
    Column(modifier = modifier.fillMaxWidth().padding(top = 8.dp, bottom = 24.dp)) {
        SetupUsageFactsSection(
            provider = provider,
            fields = fields,
            modifier = Modifier.padding(horizontal = 16.dp),
        )
        if (missing) {
            MissingSetupGuide(provider)
        } else {
            guide.parts.forEach { part ->
                GuidePartBlock(part = part, guide = guide)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun MissingSetupGuide(provider: CatalogProvider) {
    val uriHandler = LocalUriHandler.current
    val url = provider.credentialSetupURL
    EmptyState(
        title = stringResource(R.string.services_setup_guide_missing),
        modifier = Modifier.padding(top = 12.dp),
        size = EmptyStateSize.Compact,
        body = stringResource(R.string.services_setup_guide_missing_body),
        actionLabel = stringResource(R.string.action_open_in_browser).takeIf { url.isNotBlank() },
        onAction = url.takeIf { it.isNotBlank() }?.let { { uriHandler.openUri(it) } },
        glyph = {
            EmptyStateGlyph(
                symbol = MaterialSymbol.ListAlt,
                shape = MaterialShapes.SoftBurst.toShape(),
            )
        },
    )
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun GuidePartBlock(part: GuidePart, guide: SetupGuideDoc) {
    if (part.steps.isEmpty()) return
    val heading = part.title
    if (heading.isNotBlank()) {
        Text(
            text = stringResource(R.string.setup_how_to_get, heading),
            style = MaterialTheme.typography.titleMediumEmphasized,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(start = 32.dp, end = 16.dp, top = 20.dp, bottom = 8.dp),
        )
    } else {
        Spacer(Modifier.height(16.dp))
    }
    BentoGroup(modifier = Modifier.padding(horizontal = 16.dp)) {
        part.steps.forEachIndexed { index, step ->
            GuideStepRow(index = index + 1, step = step, guide = guide)
        }
    }
}

@Composable
private fun GuideStepRow(index: Int, step: GuideStep, guide: SetupGuideDoc) {
    val spoken = stringResource(R.string.setup_step_a11y, index, step.text)
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = Bento.middle,
        color = MaterialTheme.colorScheme.surfaceContainer,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                StepIndexBadge(index)
                Text(
                    text = stepText(step, guide),
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier
                        .weight(1f)
                        .semantics { contentDescription = spoken },
                )
            }
            val copyable = step.copyableValue
            if (copyable != null) {
                SetupCopyBox(
                    value = copyable,
                    label = step.copyableLabel.orEmpty(),
                )
            }
        }
    }
}

/** 加粗与行内深链的标记来自 catalog（emphasized / linkPhrases），不解析 markdown。 */
@Composable
private fun stepText(step: GuideStep, guide: SetupGuideDoc): AnnotatedString {
    val uriHandler = LocalUriHandler.current
    val linkColor = MaterialTheme.colorScheme.primary
    return buildAnnotatedString {
        append(step.text)
        step.emphasized.forEach { phrase ->
            markRange(step.text, phrase) { start, end ->
                addStyle(SpanStyle(fontWeight = FontWeight.SemiBold), start, end)
            }
        }
        val url = guide.linkURL(step.linkTarget)
        if (url != null) {
            step.linkPhrases.forEach { phrase ->
                markRange(step.text, phrase) { start, end ->
                    addStyle(
                        SpanStyle(
                            color = linkColor,
                            fontWeight = FontWeight.Medium,
                            textDecoration = TextDecoration.Underline,
                        ),
                        start,
                        end,
                    )
                    addLink(
                        LinkAnnotation.Clickable(
                            tag = "guide-link",
                            styles = TextLinkStyles(
                                SpanStyle(
                                    color = linkColor,
                                    textDecoration = TextDecoration.Underline,
                                ),
                            ),
                        ) {
                            uriHandler.openUri(url)
                        },
                        start,
                        end,
                    )
                }
            }
        }
    }
}

private inline fun markRange(text: String, phrase: String, apply: (Int, Int) -> Unit) {
    if (phrase.isEmpty()) return
    val start = text.indexOf(phrase)
    if (start >= 0) apply(start, start + phrase.length)
}

@Preview(name = "Guide Light", showBackground = true)
@Preview(name = "Guide Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupGuideStepPreview() {
    TollCatTheme {
        SetupGuideStep(
            provider = previewCatalogProvider(),
            guide = previewSetupGuide(),
        )
    }
}

@Preview(name = "Missing Light", showBackground = true)
@Preview(name = "Missing Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupGuideStepMissingPreview() {
    TollCatTheme {
        SetupGuideStep(
            provider = previewCatalogProvider(
                id = "fly",
                displayName = "Fly.io",
                colorKey = "fly",
                supportsInbox = true,
                hasLiveFetch = false,
                credentialSetupURL = "",
            ),
            guide = null,
        )
    }
}

private fun previewSetupGuide() = SetupGuideDoc(
    summary = "",
    parts = listOf(
        GuidePart(
            fields = listOf(CatalogField("apiToken", "API Token", isSecret = true)),
            steps = listOf(
                GuideStep(
                    text = "打开 Cloudflare 控制台的 API Tokens 页面，点 Create Token。选 Custom token，只勾 Account · Billing · Read。",
                    emphasized = listOf("API Tokens", "Create Token"),
                    linkPhrases = listOf("Cloudflare 控制台"),
                    linkTarget = "",
                    copyableLabel = "权限",
                    copyableValue = "Account · Billing · Read",
                ),
                GuideStep(
                    text = "创建后立刻复制 token，它只显示一次。",
                    emphasized = emptyList(),
                    linkPhrases = emptyList(),
                    linkTarget = "",
                    copyableLabel = null,
                    copyableValue = null,
                ),
            ),
        ),
        GuidePart(
            fields = listOf(CatalogField("accountID", "Account ID")),
            steps = listOf(
                GuideStep(
                    text = "在概览页右侧复制 Account ID。",
                    emphasized = listOf("Account ID"),
                    linkPhrases = emptyList(),
                    linkTarget = "",
                    copyableLabel = null,
                    copyableValue = null,
                ),
            ),
        ),
    ),
    verifyHint = "",
    troubleshooting = emptyList(),
    links = mapOf("" to "https://dash.cloudflare.com/profile/api-tokens"),
    billingURL = "",
)
