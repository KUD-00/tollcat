package com.zhechengqi.tollcat.setup

import android.content.Context
import android.content.res.Configuration
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.AccountRow
import com.zhechengqi.tollcat.CatalogField
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SetupGuideDoc
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.ui.FillProgressButton
import com.zhechengqi.tollcat.ui.FillProgressPhase
import com.zhechengqi.tollcat.ui.HierarchicalContent
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SetupWizard(
    session: TollCatSession,
    providerId: String,
    accountId: String,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    session.dataRevision
    val provider = session.catalog.provider(providerId)
    val guide = remember(providerId) { session.setupGuide(providerId) }
    val name = provider?.displayName ?: providerId
    val account = session.accounts(providerId).firstOrNull { it.accountId == accountId }
        ?: session.accounts(providerId).firstOrNull()
        ?: session.ensureAccount(providerId, accountId)
    val usesInbox = provider?.supportsInbox == true
    val fields = guide?.fields.orEmpty().ifEmpty { provider?.fields.orEmpty() }
    val stored = remember(account.credentialReference, session.dataRevision) {
        session.loadCredentialFields(account)
    }
    val values = remember(stored) {
        mutableStateMapOf<String, String>().apply {
            fields.forEach { field ->
                // 换钥：secret 不要预填已存的值。
                put(field.key, if (field.isSecret) "" else stored[field.key].orEmpty())
            }
        }
    }
    var step by rememberSaveable { mutableStateOf(SetupWizardStep.Guide) }
    var testedOk by rememberSaveable { mutableStateOf(false) }
    var didTest by rememberSaveable { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var outcome by remember { mutableStateOf<SetupVerifyOutcome?>(null) }
    var verifiedSnapshot by remember { mutableStateOf<SnapshotRow?>(null) }
    var collisionReason by remember { mutableStateOf<String?>(null) }
    var saveFailed by remember { mutableStateOf(false) }
    var explainKeystore by remember { mutableStateOf(false) }
    var siblingNickname by rememberSaveable { mutableStateOf("") }
    var newNickname by rememberSaveable { mutableStateOf("") }
    val defaultSiblingName = stringResource(R.string.services_account_n, 1)
    val fieldErrors = if (!didTest) {
        emptyMap()
    } else {
        fields.mapNotNull { field ->
            field.errorMessage(
                values[field.key].orEmpty(),
                context.getString(R.string.setup_field_required, field.label),
            )?.let { field.key to it }
        }.toMap()
    }
    val allFilled = fields.isNotEmpty() && fields.all { !values[it.key].isNullOrBlank() }
    val rotating = session.hasCredentials(account) || AccountExtras.usesInbox(account)
    val siblings = session.accounts(providerId).filter {
        it.accountId != account.accountId && !AccountExtras.isArchived(it)
    }
    val showsNickname = !rotating && siblings.isNotEmpty() && testedOk && collisionReason == null
    val inboxState = rememberInboxHandoffState(session, providerId, name, account.accountId)

    LaunchedEffect(showsNickname, defaultSiblingName, siblings.firstOrNull()?.accountId) {
        if (showsNickname && siblingNickname.isEmpty()) {
            val existing = siblings.firstOrNull()?.let { AccountExtras.nickname(it) }.orEmpty()
            siblingNickname = existing.ifEmpty { defaultSiblingName }
        }
    }

    InboxHandoffLifecycle(
        active = usesInbox && step == SetupWizardStep.Credentials,
        state = inboxState,
    )

    BackHandler(enabled = step != SetupWizardStep.Guide) {
        step = SetupWizardStep.Guide
    }

    val title = when (step) {
        SetupWizardStep.Guide -> stringResource(R.string.services_setup_guide_title, name)
        SetupWizardStep.Credentials -> stringResource(R.string.setup_title, name)
    }
    val stepDigits = "${step.displayNumber} / ${SetupWizardStep.TOTAL}"
    val stepSpoken = stringResource(
        R.string.setup_step_progress,
        step.displayNumber,
        SetupWizardStep.TOTAL,
    )

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(title)
                        Text(
                            text = stepDigits,
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.semantics { contentDescription = stepSpoken },
                        )
                    }
                },
                navigationIcon = {
                    IconButton(
                        shapes = IconButtonDefaults.shapes(),
                        onClick = {
                            when (step) {
                                SetupWizardStep.Guide -> session.popServices()
                                SetupWizardStep.Credentials -> step = SetupWizardStep.Guide
                            }
                        },
                    ) {
                        SymbolIcon(
                            MaterialSymbol.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                },
            )
        },
        bottomBar = {
            Surface(color = MaterialTheme.colorScheme.surfaceContainer) {
                SetupWizardPrimaryAction(
                    step = step,
                    usesInbox = usesInbox,
                    testedOk = testedOk,
                    busy = busy,
                    allFilled = allFilled,
                    collisionReason = collisionReason,
                    showsNickname = showsNickname,
                    newNickname = newNickname,
                    inboxCanConnect = inboxState.canConnect,
                    onGuideNext = { step = SetupWizardStep.Credentials },
                    onTestOrSave = testOrSave@{
                        if (busy && !testedOk) return@testOrSave
                        performCredentialAction(
                            session = session,
                            account = account,
                            fields = fields,
                            values = values.toMap(),
                            siblings = siblings,
                            showsNickname = showsNickname,
                            siblingNickname = siblingNickname,
                            newNickname = newNickname,
                            defaultSiblingName = defaultSiblingName,
                            testedOk = testedOk,
                            verifiedSnapshot = verifiedSnapshot,
                            guide = guide,
                            context = context,
                            providerName = name,
                            setDidTest = { didTest = true },
                            setBusy = { busy = it },
                            setOutcome = { outcome = it },
                            setTestedOk = { testedOk = it },
                            setVerifiedSnapshot = { verifiedSnapshot = it },
                            setCollisionReason = { collisionReason = it },
                            setSaveFailed = { saveFailed = it },
                        )
                    },
                    onInboxConnect = {
                        inboxState.connect(defaultSiblingName) { ok ->
                            if (ok) session.popServices()
                        }
                    },
                )
            }
        },
    ) { inner ->
        HierarchicalContent(
            targetState = step,
            depth = step.ordinal,
            modifier = Modifier
                .padding(inner)
                .imePadding()
                .fillMaxSize(),
        ) { current ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .testTag(
                        when (current) {
                            SetupWizardStep.Guide -> UITestId.SETUP_GUIDE
                            SetupWizardStep.Credentials -> UITestId.SETUP_CREDENTIALS
                        },
                    ),
            ) {
                when (current) {
                    SetupWizardStep.Guide -> {
                        if (provider != null) SetupGuideStep(provider, guide)
                    }
                    SetupWizardStep.Credentials -> {
                        if (usesInbox) {
                            InboxHandoffStep(
                                state = inboxState,
                                nowMillis = session.nowMillis(),
                                defaultSiblingName = defaultSiblingName,
                            )
                        } else {
                            SetupCredentialsStep(
                                fields = fields,
                                values = values,
                                fieldErrors = fieldErrors,
                                outcome = outcome,
                                onEdited = {
                                    testedOk = false
                                    outcome = null
                                    verifiedSnapshot = null
                                    collisionReason = null
                                    saveFailed = false
                                },
                                onExplainKeystore = { explainKeystore = true },
                                onRevisePermissions = { step = SetupWizardStep.Guide },
                                collisionReason = collisionReason,
                                saveFailed = saveFailed,
                                showsNickname = showsNickname,
                                siblingNickname = siblingNickname,
                                onSiblingNicknameChange = { siblingNickname = it },
                                newNickname = newNickname,
                                onNewNicknameChange = { newNickname = it },
                            )
                            val theoretical = provider != null && SetupProviderFacts.offersSetupFeedback(provider)
                            if (didTest && theoretical) {
                                SetupFeedbackSection(
                                    providerName = name,
                                    testedOk = testedOk,
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    if (explainKeystore) {
        KeystoreExplainerSheet(onDismiss = { explainKeystore = false })
    }
}

@Composable
private fun SetupWizardPrimaryAction(
    step: SetupWizardStep,
    usesInbox: Boolean,
    testedOk: Boolean,
    busy: Boolean,
    allFilled: Boolean,
    collisionReason: String?,
    showsNickname: Boolean,
    newNickname: String,
    inboxCanConnect: Boolean,
    onGuideNext: () -> Unit,
    onTestOrSave: () -> Unit,
    onInboxConnect: () -> Unit,
) {
    val barModifier = Modifier
        .fillMaxWidth()
        .padding(MeterSpacing.md)
        .testTag(UITestId.SETUP_NEXT)
    when {
        step == SetupWizardStep.Guide -> {
            val label = stringResource(R.string.services_setup_have_credentials)
            PrimaryButton(
                onClick = onGuideNext,
                modifier = barModifier.semantics { contentDescription = label },
            ) {
                Text(label)
            }
        }
        usesInbox -> {
            val label = stringResource(R.string.inbox_handoff_connect)
            PrimaryButton(
                onClick = onInboxConnect,
                enabled = inboxCanConnect,
                modifier = barModifier.semantics { contentDescription = label },
            ) {
                Text(label)
            }
        }
        else -> {
            val label = stringResource(
                if (testedOk) R.string.action_save_credentials else R.string.action_test_connection,
            )
            val nicknameBlocked = testedOk && showsNickname && newNickname.trim().isEmpty()
            val enabled = when {
                collisionReason != null -> false
                nicknameBlocked -> false
                testedOk -> true
                busy -> true
                else -> allFilled
            }
            val phase = when {
                busy && !testedOk -> FillProgressPhase.Progressing
                testedOk -> FillProgressPhase.Completed
                else -> FillProgressPhase.Idle
            }
            FillProgressButton(
                text = label,
                phase = phase,
                onClick = onTestOrSave,
                modifier = barModifier.semantics { contentDescription = label },
                enabled = enabled,
            )
        }
    }
}

private fun performCredentialAction(
    session: TollCatSession,
    account: AccountRow,
    fields: List<CatalogField>,
    values: Map<String, String>,
    siblings: List<AccountRow>,
    showsNickname: Boolean,
    siblingNickname: String,
    newNickname: String,
    defaultSiblingName: String,
    testedOk: Boolean,
    verifiedSnapshot: SnapshotRow?,
    guide: SetupGuideDoc?,
    context: Context,
    providerName: String,
    setDidTest: () -> Unit,
    setBusy: (Boolean) -> Unit,
    setOutcome: (SetupVerifyOutcome) -> Unit,
    setTestedOk: (Boolean) -> Unit,
    setVerifiedSnapshot: (SnapshotRow?) -> Unit,
    setCollisionReason: (String?) -> Unit,
    setSaveFailed: (Boolean) -> Unit,
) {
    if (testedOk) {
        persistVerified(
            session = session,
            account = account,
            values = values,
            siblings = siblings,
            showsNickname = showsNickname,
            siblingNickname = siblingNickname,
            newNickname = newNickname,
            defaultSiblingName = defaultSiblingName,
            verifiedSnapshot = verifiedSnapshot,
            setSaveFailed = setSaveFailed,
        )
        return
    }
    setDidTest()
    val nextErrors = fields.associate { field ->
        field.key to field.errorMessage(
            values[field.key].orEmpty(),
            context.getString(R.string.setup_field_required, field.label),
        )
    }.filterValues { it != null }
    if (nextErrors.isNotEmpty()) return
    setBusy(true)
    setCollisionReason(null)
    setSaveFailed(false)
    session.verifyConnection(account, values, persist = false) { result ->
        setBusy(false)
        val mapped = SetupVerifyMapper.outcome(
            context = context,
            result = result,
            troubleshooting = guide?.troubleshooting.orEmpty(),
        )
        setOutcome(mapped)
        val ok = mapped is SetupVerifyOutcome.Success
        setTestedOk(ok)
        setVerifiedSnapshot(result.snapshot.takeIf { ok })
        if (ok) {
            val hit = session.collidingAccount(account.providerId, values)
                ?.takeIf { it.accountId != account.accountId }
            setCollisionReason(
                hit?.let { other ->
                    context.getString(
                        R.string.services_fingerprint_collision,
                        AccountExtras.displayName(other, providerName),
                    )
                },
            )
        }
    }
}

private fun persistVerified(
    session: TollCatSession,
    account: AccountRow,
    values: Map<String, String>,
    siblings: List<AccountRow>,
    showsNickname: Boolean,
    siblingNickname: String,
    newNickname: String,
    defaultSiblingName: String,
    verifiedSnapshot: SnapshotRow?,
    setSaveFailed: (Boolean) -> Unit,
) {
    val filled = values.filterValues { it.isNotBlank() }
    try {
        session.saveCredentials(account, filled)
    } catch (_: Throwable) {
        setSaveFailed(true)
        return
    }
    session.rememberFingerprint(account, filled)
    verifiedSnapshot?.let { session.ledger.replaceAccountSnapshots(account.accountId, it) }
    if (showsNickname) {
        siblings.firstOrNull()?.let { sibling ->
            session.setNickname(sibling.accountId, siblingNickname.trim().ifEmpty { defaultSiblingName })
        }
        session.setNickname(account.accountId, newNickname.trim())
    } else {
        session.setNickname(account.accountId, AccountExtras.nickname(account))
    }
    session.popServices()
}

@Preview(name = "Test Light", showBackground = true)
@Preview(name = "Test Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupWizardTestingPreview() {
    TollCatTheme {
        Surface {
            SetupWizardPrimaryAction(
                step = SetupWizardStep.Credentials,
                usesInbox = false,
                testedOk = false,
                busy = true,
                allFilled = true,
                collisionReason = null,
                showsNickname = false,
                newNickname = "",
                inboxCanConnect = false,
                onGuideNext = {},
                onTestOrSave = {},
                onInboxConnect = {},
            )
        }
    }
}

@Preview(name = "Inbox Light", showBackground = true)
@Preview(name = "Inbox Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupWizardInboxPreview() {
    TollCatTheme {
        Surface {
            SetupWizardPrimaryAction(
                step = SetupWizardStep.Credentials,
                usesInbox = true,
                testedOk = false,
                busy = false,
                allFilled = false,
                collisionReason = null,
                showsNickname = false,
                newNickname = "",
                inboxCanConnect = true,
                onGuideNext = {},
                onTestOrSave = {},
                onInboxConnect = {},
            )
        }
    }
}
