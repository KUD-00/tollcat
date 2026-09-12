package com.zhechengqi.tollcat

import android.app.Application
import android.net.Uri
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import com.zhechengqi.tollcat.developer.DemoSeeder
import com.zhechengqi.tollcat.developer.DeveloperDebugLog
import com.zhechengqi.tollcat.developer.DeveloperStoreDump
import com.zhechengqi.tollcat.dashboard.DashboardFilterState
import com.zhechengqi.tollcat.ui.PersistenceStatus
import com.zhechengqi.tollcat.settings.InboxClient
import com.zhechengqi.tollcat.settings.ReminderAlarmScheduler
import com.zhechengqi.tollcat.settings.SettingsDeepLink
import com.zhechengqi.tollcat.settings.TipStore
import com.zhechengqi.tollcat.settings.SettingsDeepLinkEvent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.UUID

class TollCatViewModel(application: Application) : AndroidViewModel(application) {
    val session = TollCatSession(
        credentials = AndroidKeystoreCredentialStore(application),
        ledger = SqliteLedgerStore(application),
        preferences = PreferencesStore(application),
    )

    init {
        JniGate.run {
            MeterCoreNative.load(application)
            val root = SwiftResourceExtractor.extract(application)
            MeterCoreNative.setResourceRoot(root.absolutePath)
            Proof.log(application)
            session.bootstrap()
        }
    }
}

class TollCatSession(
    val credentials: CredentialStore,
    val ledger: LedgerStore,
    val preferences: PreferencesStore,
) {
    var catalog by mutableStateOf(Catalog(emptyList(), listOf("USD")))
        private set
    var dashboard by mutableStateOf(DashboardSnapshot.vacant)
        private set
    var tab by mutableStateOf(AppTab.Dashboard)
    var servicesStack by mutableStateOf(listOf<ServicesRoute>(ServicesRoute.List))
    var isRefreshing by mutableStateOf(false)
    var refreshMessage by mutableStateOf<String?>(null)
    var setupMessage by mutableStateOf<String?>(null)
    var displayCurrency by mutableStateOf(preferences.displayCurrency)

    /** 仪表盘取景框。改它必须走 [applyFilter]：筛选是重算，不是渲染后过滤。 */
    var filter by mutableStateOf(DashboardFilterState.fromJson(preferences.dashboardFilterJson))
        private set
    var clockOverrideMillis by mutableStateOf<Long?>(null)
    var lastRefreshSummary by mutableStateOf("")

    /** 刷新全失败时仪表页脚用人话，不再把 ok/fail 调试串丢进 snackbar。 */
    var refreshFailed by mutableStateOf(false)
        private set

    var didFailToReadDashboard by mutableStateOf(false)
        private set

    var isDemoBannerDismissed by mutableStateOf(false)

    /** 刚清完全部数据：空态换一句「已经清掉了」，加回第一家之后关掉。 */
    var didClearAllData by mutableStateOf(false)
        private set

    /** 深链要落到设置哪一处。消费掉就置回 null。 */
    var pendingSettingsDeepLink by mutableStateOf<SettingsDeepLinkEvent?>(null)
        private set
    private var settingsDeepLinkSeq = 0L

    fun nowMillis(): Long = clockOverrideMillis ?: System.currentTimeMillis()

    fun bootstrap() {
        MoneyDisplay.currency = displayCurrency
        val nextCatalog = runCatching { Catalog.parse(MeterCoreNative.catalogJson(MoneyDisplay.localeTag())) }
            .getOrElse { Catalog(emptyList(), listOf("USD")) }
        JniGate.onMain {
            catalog = nextCatalog
            Log.i(TAG, "ui=product tabs=仪表,服务,设置 providers=${catalog.providers.size}")
        }
        recompute()
    }

    fun memberships(): List<MembershipRow> = ledger.memberships()

    fun liveMemberships(): List<MembershipRow> = ledger.memberships().filter { membership ->
        ledger.accounts(membership.providerId).any { !AccountExtras.isArchived(it) }
    }

    fun archivedMemberships(): List<MembershipRow> = ledger.memberships().filter { membership ->
        val accounts = ledger.accounts(membership.providerId)
        accounts.isNotEmpty() && accounts.all { AccountExtras.isArchived(it) }
    }

    fun accounts(providerId: String): List<AccountRow> = ledger.accounts(providerId)

    fun liveAccounts(providerId: String): List<AccountRow> =
        ledger.accounts(providerId).filter { !AccountExtras.isArchived(it) }

    fun persistenceStatus(): PersistenceStatus = PersistenceStatus(
        containsDemoData = containsDemoData(),
        didFailToRead = didFailToReadDashboard,
        isDemoBannerDismissed = isDemoBannerDismissed,
    )

    fun dismissDemoBanner() {
        isDemoBannerDismissed = true
        preferences.isDemoModeEnabled = false
    }

    fun openDashboard() {
        tab = AppTab.Dashboard
    }

    fun previewDashboard(draft: DashboardFilterState): DashboardSnapshot = computeDashboard(draft)

    fun serviceScopedDashboard(): DashboardSnapshot = computeDashboard(
        DashboardFilterState(includesSubscriptions = true),
    )

    fun monthsBackWithReadings(): Set<Int> {
        val now = nowMillis()
        val found = mutableSetOf(0)
        val cal = Calendar.getInstance()
        cal.timeInMillis = now
        val nowYear = cal.get(Calendar.YEAR)
        val nowMonth = cal.get(Calendar.MONTH)
        fun backOf(millis: Long): Int? {
            if (millis <= 0L) return null
            cal.timeInMillis = millis
            val months = (nowYear - cal.get(Calendar.YEAR)) * 12 + (nowMonth - cal.get(Calendar.MONTH))
            return months.takeIf { it in 0..DashboardFilterState.MAX_MONTHS_BACK }
        }
        for (row in ledger.snapshots()) {
            backOf(row.fetchedAtMillis)?.let { found.add(it) }
            backOf(row.periodStartMillis)?.let { found.add(it) }
        }
        for (row in ledger.subscriptions()) {
            val start = Calendar.getInstance().apply {
                set(Calendar.YEAR, row.anchorYear)
                set(Calendar.MONTH, row.anchorMonth - 1)
                set(Calendar.DAY_OF_MONTH, 1)
            }.timeInMillis
            backOf(start)?.let { found.add(it) }
        }
        return found
    }

    fun archiveProvider(providerId: String) {
        val now = nowMillis()
        for (account in ledger.accounts(providerId)) {
            credentials.delete(account.credentialReference)
            ledger.upsertAccount(AccountExtras.withArchivedAt(account, now))
        }
        JniGate.run { recompute() }
    }

    fun setNickname(accountId: String, nickname: String?) {
        val account = ledger.accounts().firstOrNull { it.accountId == accountId } ?: return
        ledger.upsertAccount(AccountExtras.withNickname(account, nickname))
        JniGate.run { recompute(); bumpData() }
    }

    fun collidingAccount(providerId: String, fields: Map<String, String>): AccountRow? {
        val fingerprint = AccountExtras.fingerprintOf(fields)
        return ledger.accounts(providerId).firstOrNull { AccountExtras.fingerprint(it) == fingerprint }
    }

    fun rememberFingerprint(account: AccountRow, fields: Map<String, String>) {
        ledger.upsertAccount(AccountExtras.withFingerprint(account, AccountExtras.fingerprintOf(fields)))
    }

    fun hasCredentials(account: AccountRow): Boolean {
        return !credentials.read(account.credentialReference).isNullOrBlank()
    }

    fun latestSnapshot(providerId: String): SnapshotRow? {
        return ledger.snapshots()
            .filter { it.providerId == providerId }
            .maxByOrNull { it.fetchedAtMillis }
    }

    fun addProvider(providerId: String) {
        if (ledger.memberships().any { it.providerId == providerId }) {
            openDetail(providerId)
            return
        }
        noteUserHasData()
        val sort = ledger.memberships().size
        ledger.upsertMembership(MembershipRow(providerId, sort))
        val accountId = UUID.randomUUID().toString()
        ledger.upsertAccount(
            AccountRow(
                accountId = accountId,
                providerId = providerId,
                credentialReference = "acct.$accountId",
                sortIndex = 0,
            ),
        )
        openDetail(providerId)
        JniGate.run { recompute() }
    }

    fun removeProvider(providerId: String) {
        for (account in ledger.accounts(providerId)) {
            credentials.delete(account.credentialReference)
        }
        ledger.deleteMembership(providerId)
        if (servicesStack.lastOrNull() is ServicesRoute.Detail) {
            popServices()
        }
        JniGate.run { recompute() }
    }

    fun openAdd() {
        tab = AppTab.Services
        if (servicesStack.lastOrNull() != ServicesRoute.Add) {
            servicesStack = servicesStack + ServicesRoute.Add
        }
    }

    fun openAddMore() {
        tab = AppTab.Services
        if (servicesStack.lastOrNull() != ServicesRoute.AddMore) {
            servicesStack = servicesStack + ServicesRoute.AddMore
        }
    }

    fun openPast() {
        tab = AppTab.Services
        if (servicesStack.lastOrNull() != ServicesRoute.Past) {
            servicesStack = servicesStack + ServicesRoute.Past
        }
    }

    fun openDetail(providerId: String) {
        tab = AppTab.Services
        val withoutAdd = servicesStack.filter { it != ServicesRoute.Add && it != ServicesRoute.AddMore }
        val next = ServicesRoute.Detail(providerId)
        servicesStack = if (withoutAdd.lastOrNull() == next) withoutAdd else withoutAdd + next
    }

    /** 仪表「需要注意」行：有账号 id 就开那一份，否则按厂商。 */
    fun openAccountOrProvider(id: String) {
        if (id.isBlank()) return
        val account = ledger.accounts().firstOrNull { it.accountId == id }
        openDetail(account?.providerId ?: id)
    }

    fun openSettings(path: String? = null) {
        tab = AppTab.Settings
        settingsDeepLinkSeq += 1
        pendingSettingsDeepLink = SettingsDeepLinkEvent(path, settingsDeepLinkSeq)
    }

    fun openSettingsDeepLink(uri: Uri) {
        if (!SettingsDeepLink.matches(uri)) return
        openSettings(SettingsDeepLink.path(uri))
    }

    fun consumeSettingsDeepLink(): SettingsDeepLinkEvent? {
        val event = pendingSettingsDeepLink
        pendingSettingsDeepLink = null
        return event
    }

    fun openSetup(providerId: String, accountId: String) {
        tab = AppTab.Services
        val next = ServicesRoute.Setup(providerId, accountId)
        if (servicesStack.lastOrNull() != next) {
            servicesStack = servicesStack + next
        }
    }

    fun popServices() {
        if (servicesStack.size > 1) {
            servicesStack = servicesStack.dropLast(1)
        }
    }

    fun saveCredentials(account: AccountRow, fields: Map<String, String>) {
        credentials.save(JSONObject(fields).toString(), account.credentialReference)
    }

    /** 接入没有公开账单接口的服务时懒建信箱。已经有了就不动。 */
    fun ensureInbox(): Boolean {
        if (InboxMailboxStore.read(credentials) != null) return true
        // 旧版本的明文值搬进凭据店，别让用户重建信箱丢掉已有读数。
        if (InboxMailboxStore.migrateFromPreferences(credentials, preferences) != null) return true
        return runCatching {
            val created = InboxClient.create()
            InboxMailboxStore.save(credentials, created.mailbox, created.readKey)
            true
        }.getOrDefault(false)
    }

    fun loadCredentialFields(account: AccountRow): Map<String, String> {
        val raw = credentials.read(account.credentialReference) ?: return emptyMap()
        return runCatching {
            val json = JSONObject(raw)
            json.keys().asSequence().associateWith { json.optString(it) }
        }.getOrElse { emptyMap() }
    }

    fun testAndSave(account: AccountRow, fields: Map<String, String>, persist: Boolean): FetchResult {
        val filled = fields.filterValues { it.isNotBlank() }
        val result = fetch(account, filled)
        if (result.ok && persist) {
            saveCredentials(account, filled)
            result.snapshot?.let { ledger.replaceAccountSnapshots(account.accountId, it) }
            if (catalog.providers.any { it.id == account.providerId && it.supportsInbox }) {
                ensureInbox()
            }
            JniGate.run { recompute() }
            JniGate.onMain { setupMessage = result.spend }
        } else if (result.ok) {
            JniGate.onMain { setupMessage = result.spend }
        } else {
            JniGate.onMain { setupMessage = result.error }
        }
        return result
    }

    fun refreshAll(includePaid: Boolean = false, freshnessMillis: Long? = null) {
        if (isRefreshing) return
        isRefreshing = true
        refreshMessage = null
        refreshFailed = false
        JniGate.run {
            try {
                val accounts = ledger.accounts().filter { !AccountExtras.isArchived(it) }
                if (accounts.isEmpty()) {
                    JniGate.onMain {
                        lastRefreshSummary = "empty"
                        isRefreshing = false
                    }
                    return@run
                }
                var ok = 0
                var fail = 0
                var lastSpend: String? = null
                val nowMillis = nowMillis()
                for (account in accounts) {
                    val provider = catalog.provider(account.providerId)
                    if (
                        !includePaid &&
                        provider?.costsMoneyToRefresh == true &&
                        !preferences.includeInGlobalRefresh(account.accountId)
                    ) {
                        continue
                    }
                    val lastFetched = ledger.snapshots()
                        .filter { it.accountId == account.accountId }
                        .maxByOrNull { it.fetchedAtMillis }
                        ?.fetchedAtMillis
                    if (freshnessMillis != null && lastFetched != null && nowMillis - lastFetched < freshnessMillis) {
                        continue
                    }
                    if (provider != null && !provider.shouldFetch(lastFetched, nowMillis)) {
                        continue
                    }
                    val fields = loadCredentialFields(account)
                    val result = fetch(account, fields)
                    if (result.ok && result.snapshot != null) {
                        ledger.insertSnapshot(result.snapshot)
                        ok += 1
                        lastSpend = result.spend
                        Log.i(
                            TAG,
                            "refresh provider=${account.providerId} spend=${result.spend}",
                        )
                    } else {
                        fail += 1
                        Log.w(TAG, "refresh fail provider=${account.providerId} error=${result.error}")
                    }
                }
                refreshInboxReadings()
                val message = "ok:$ok fail:$fail spend=$lastSpend"
                recompute()
                JniGate.onMain {
                    lastRefreshSummary = message
                    refreshFailed = fail > 0 && ok == 0
                    isRefreshing = false
                    Log.i(TAG, "refreshAll ok=$ok fail=$fail formatted=${dashboard.formattedTotal}")
                    DeveloperDebugLog.record("refresh", message)
                }
            } catch (error: Throwable) {
                Log.e(TAG, "refreshAll", error)
                JniGate.onMain {
                    refreshFailed = true
                    isRefreshing = false
                }
            }
        }
    }

    fun seedDemo(): DemoSeeder.Result {
        val result = DemoSeeder.seed(ledger, credentials, nowMillis())
        when (result) {
            DemoSeeder.Result.Seeded -> {
                preferences.isDemoModeEnabled = true
                noteUserHasData()
                JniGate.run { recompute(); bumpData() }
                DeveloperDebugLog.record("store", "seeded demo snapshots")
            }
            DemoSeeder.Result.NotEmpty ->
                DeveloperDebugLog.record("store", "seed skipped: store not empty")
            is DemoSeeder.Result.Failed ->
                DeveloperDebugLog.record("store", "seed failed: ${result.message}")
        }
        return result
    }

    fun containsDemoData(): Boolean = DemoSeeder.containsDemoData(ledger)

    fun applyClockOverride(millis: Long?) {
        clockOverrideMillis = millis
        JniGate.run { recompute(); bumpData() }
    }

    fun storeDump(): String = DeveloperStoreDump.json(ledger)

    fun setCurrency(code: String) {
        displayCurrency = code
        preferences.displayCurrency = code
        MoneyDisplay.currency = code
        JniGate.run { recompute() }
    }

    fun applyFilter(next: DashboardFilterState) {
        filter = next
        preferences.dashboardFilterJson = next.toJson()
        JniGate.run { recompute() }
    }

    /** 设置里那颗开关的实现。付费家默认不进，除非账号勾了加入全局刷新。 */
    fun refreshIfNeededOnActivate() {
        if (!preferences.refreshOnActivate) return
        if (isRefreshing) return
        if (liveMemberships().isEmpty()) return
        refreshAll(includePaid = false, freshnessMillis = 15L * 60L * 1000L)
    }

    /** 向导教程。目录里没有这家时返回 null。 */
    fun setupGuide(providerId: String): SetupGuideDoc? {
        return runCatching {
            SetupGuideDoc.parse(MeterCoreNative.setupGuideJson(providerId, MoneyDisplay.localeTag()))
        }
            .getOrNull()
    }

    fun clearAll() {
        for (account in ledger.accounts()) {
            credentials.delete(account.credentialReference)
        }
        InboxMailboxStore.delete(credentials)
        credentials.deleteAll()
        preferences.clearLegacyInbox()
        ledger.clearAll()
        ReminderAlarmScheduler.cancel(preferences.appContext)
        preferences.clear()
        TipStore.clear(preferences.appContext)
        displayCurrency = "USD"
        MoneyDisplay.currency = "USD"
        filter = DashboardFilterState()
        clockOverrideMillis = null
        lastRefreshSummary = ""
        servicesStack = listOf<ServicesRoute>(ServicesRoute.List)
        tab = AppTab.Dashboard
        didClearAllData = true
        JniGate.run { recompute(); bumpData() }
        Log.i(TAG, "cleared=ok")
    }

    fun recompute() {
        val previous = dashboard
        val next = computeDashboard()
        val widget = widgetDashboard(next)
        val refreshedAt = lastSuccessfulRefreshAt()
        val now = nowMillis()
        val other = preferences.appContext.getString(R.string.dashboard_composition_other)
        val failedRead = next.empty && previous.empty && ledger.memberships().isNotEmpty()
        JniGate.onMain {
            dashboard = next
            if (!next.empty) didFailToReadDashboard = false
            else if (failedRead) didFailToReadDashboard = true
            WidgetSnapshot.write(widget, refreshedAt, now, other)
            Log.i(
                TAG,
                "dashboard empty=${dashboard.empty} formatted=${dashboard.formattedTotal} confidence=${dashboard.confidence}",
            )
        }
    }

    /** 小组件只跟订阅口径，不跟排除名单和月份。 */
    private fun widgetDashboard(current: DashboardSnapshot): DashboardSnapshot {
        if (filter.isCurrentMonth && filter.excludedAccountIds.isEmpty()) return current
        return computeDashboard(
            DashboardFilterState(includesSubscriptions = filter.includesSubscriptions),
        )
    }

    private fun lastSuccessfulRefreshAt(): Long? {
        return ledger.snapshots().maxByOrNull { it.fetchedAtMillis }?.fetchedAtMillis?.takeIf { it > 0L }
    }

    private fun layoutFilterJson(filterState: DashboardFilterState): String {
        val root = JSONObject(filterState.toJson())
        root.put("pinnedAccounts", JSONArray(preferences.pinnedAccountIds.toList()))
        val budget = preferences.monthlyBudgetUsd.trim()
        if (budget.isNotEmpty()) root.put("monthlyBudgetUSD", budget)
        return root.toString()
    }

    fun applyDashboardLayout(
        order: List<String>,
        pinned: Set<String>,
        budgetUsd: String,
    ) {
        preferences.setModuleOrder(order)
        preferences.pinnedAccountIds = pinned
        preferences.monthlyBudgetUsd = budgetUsd.trim()
        JniGate.run { recompute() }
    }

    private fun computeDashboard(
        filterState: DashboardFilterState = filter,
    ): DashboardSnapshot {
        val snapshots = JSONArray()
        for (row in ledger.snapshots()) {
            snapshots.put(snapshotJson(row))
        }
        val subscriptions = JSONArray()
        for (row in ledger.subscriptions()) {
            subscriptions.put(
                JSONObject().apply {
                    put("name", row.name)
                    put("amountUSD", row.amountUsd)
                    put("period", row.period)
                    put("anchorYear", row.anchorYear)
                    put("anchorMonth", row.anchorMonth)
                    put("anchorDay", row.anchorDay)
                    // 漏接这三个键，退掉的订阅会在 Android 上一直扣下去。
                    row.endYear?.let { put("endYear", it) }
                    row.endMonth?.let { put("endMonth", it) }
                    row.endDay?.let { put("endDay", it) }
                    row.providerId?.let { put("providerID", it) }
                    row.accountId?.let { put("accountID", it) }
                    put("quantity", row.quantity)
                },
            )
        }
        val previous = dashboard
        return runCatching {
            DashboardSnapshot.parse(
                MeterCoreNative.computeDashboardJson(
                    snapshots.toString(),
                    subscriptions.toString(),
                    nowMillis(),
                    displayCurrency,
                    MoneyDisplay.localeTag(),
                    layoutFilterJson(filterState),
                ),
            )
        }.getOrElse { error ->
            Log.e(TAG, "dashboard compute failed", error)
            if (!previous.empty) previous else DashboardSnapshot.vacant
        }
    }

    private fun refreshInboxReadings() {
        val readKey = InboxMailboxStore.read(credentials)?.readKey
            ?: InboxMailboxStore.migrateFromPreferences(credentials, preferences)?.readKey
            ?: return
        val json = runCatching { MeterCoreNative.inboxReadingsJson(readKey) }.getOrNull() ?: return
        val root = runCatching { JSONObject(json) }.getOrNull() ?: return
        if (!root.optBoolean("ok", true) && root.optInt("status") !in 200..299) return
        val readings = root.optJSONArray("readings") ?: root.optJSONArray("items") ?: return
        val byKey = ledger.accounts()
            .filter { AccountExtras.ingestKeyId(it) != null && !AccountExtras.isArchived(it) }
            .associateBy { AccountExtras.ingestKeyId(it) }
        for (index in 0 until readings.length()) {
            val item = readings.optJSONObject(index) ?: continue
            val ingestId = item.optString("ingestKeyID").ifBlank { item.optString("ingestKeyId") }
            val account = byKey[ingestId] ?: continue
            val spend = item.optString("currentSpendUSD").ifBlank { null } ?: continue
            val periodStart = item.optLong("periodStartMillis").takeIf { it > 0L }
                ?: item.optLong("periodStart")
            ledger.insertSnapshot(
                SnapshotRow(
                    providerId = account.providerId,
                    accountId = account.accountId,
                    kind = "usage",
                    source = "inbox",
                    currentSpendUsd = spend,
                    periodStartMillis = periodStart,
                    periodEndMillis = nowMillis(),
                    fetchedAtMillis = nowMillis(),
                ),
            )
        }
    }

    private fun fetch(account: AccountRow, fields: Map<String, String>): FetchResult {
        val payload = JSONObject(fields).toString()
        val json = MeterCoreNative.fetchProviderJson(
            account.providerId,
            payload,
            nowMillis(),
        )
        DeveloperDebugLog.recordHttp(
            "POST ${account.providerId}",
            json,
        )
        return FetchResult.parse(json, account.accountId)
    }

    private fun snapshotJson(row: SnapshotRow): JSONObject {
        return JSONObject().apply {
            put("providerID", row.providerId)
            put("accountID", row.accountId)
            put("kind", row.kind)
            put("source", row.source)
            put("fetchedAt", row.fetchedAtMillis)
            put("periodStart", row.periodStartMillis)
            put("periodEnd", row.periodEndMillis)
            row.currentSpendUsd?.let { put("currentSpendUSD", it) }
            row.balanceUsd?.let { put("balanceUSD", it) }
            row.committedMonthlyUsd?.let { put("committedMonthlyUSD", it) }
            row.chargeDayOfMonth?.let { put("chargeDayOfMonth", it) }
            row.freeQuotaUsedRatio?.let { put("freeQuotaUsedRatio", it) }
            row.dailyUsdJson?.let { put("dailyUSD", JSONObject(it)) }
            row.convertedJson?.let { put("converted", JSONObject(it)) }
            row.walletsJson?.let { put("wallets", JSONArray(it)) }
            row.spendLinesJson?.let { put("lines", JSONArray(it)) }
        }
    }

    var dataRevision by mutableStateOf(0)
        private set

    fun subscriptionsFor(providerId: String): List<SubscriptionRow> {
        return ledger.subscriptions().filter { it.providerId == providerId }
    }

    fun unaffiliatedSubscriptions(): List<SubscriptionRow> {
        val members = ledger.memberships().map { it.providerId }.toSet()
        return ledger.subscriptions().filter { row ->
            row.providerId == null || row.providerId !in members
        }
    }

    fun snapshotsFor(providerId: String): List<SnapshotRow> {
        return ledger.snapshots()
            .filter { it.providerId == providerId }
            .sortedByDescending { it.fetchedAtMillis }
    }

    /** 详情页历史图。分桶、做差、推断段在共享层算好，这边只解回视图状态。 */
    fun historyChart(providerId: String, range: com.zhechengqi.tollcat.services.HistoryRange): com.zhechengqi.tollcat.services.HistoryChartState {
        val rows = JSONArray()
        for (row in snapshotsFor(providerId)) {
            rows.put(snapshotJson(row))
        }
        return runCatching {
            com.zhechengqi.tollcat.services.HistoryChartState.parse(
                MeterCoreNative.historyChartJson(
                    providerId,
                    rows.toString(),
                    range.key,
                    nowMillis(),
                    0,
                    range.key == "days7" || range.key == "days30",
                ),
            )
        }.getOrElse { com.zhechengqi.tollcat.services.HistoryChartState.None }
    }

    fun ensureAccount(providerId: String, accountId: String? = null): AccountRow {
        if (accountId != null) {
            ledger.accounts(providerId).firstOrNull { it.accountId == accountId }?.let { return it }
        }
        ledger.accounts(providerId).firstOrNull()?.let { return it }
        return addUsageAccount(providerId)
    }

    fun addUsageAccount(providerId: String): AccountRow {
        val id = UUID.randomUUID().toString()
        val row = AccountRow(
            accountId = id,
            providerId = providerId,
            credentialReference = "acct.$id",
            sortIndex = ledger.accounts(providerId).size,
        )
        ledger.upsertAccount(row)
        noteUserHasData()
        bumpData()
        return row
    }

    fun openUsageSetup(providerId: String, accountId: String? = null) {
        val account = ensureAccount(providerId, accountId)
        openSetup(providerId, account.accountId)
    }

    /// 按 id 覆盖。改名不再需要先删后插——行的身份是 id，不是名字。
    fun saveSubscription(row: SubscriptionRow) {
        ledger.upsertSubscription(row)
        JniGate.run { recompute(); bumpData() }
    }

    /** 真删。**会改写历史**——只给「录错了」用；不订了在编辑页填一个结束月。 */
    fun deleteSubscription(id: String) {
        ledger.deleteSubscription(id)
        JniGate.run { recompute(); bumpData() }
    }

    /** 这一笔到此刻为止结束了没有。填在未来的结束月不算——那种还在付。 */
    fun hasEnded(row: SubscriptionRow): Boolean {
        val calendar = Calendar.getInstance().apply { timeInMillis = nowMillis() }
        return row.hasEndedBy(calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH) + 1)
    }

    fun deleteUsageAccount(accountId: String) {
        val account = ledger.accounts().firstOrNull { it.accountId == accountId } ?: return
        credentials.delete(account.credentialReference)
        ledger.deleteAccount(accountId)
        JniGate.run { recompute(); bumpData() }
    }

    fun saveManualUsage(
        providerId: String,
        accountId: String?,
        amountUsd: String,
        periodMillis: Long = nowMillis(),
    ) {
        val account = ensureAccount(providerId, accountId)
        val now = nowMillis()
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = periodMillis
        calendar.set(java.util.Calendar.DAY_OF_MONTH, 1)
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val start = calendar.timeInMillis
        calendar.add(java.util.Calendar.MONTH, 1)
        calendar.add(java.util.Calendar.MILLISECOND, -1)
        val end = calendar.timeInMillis
        val kind = catalog.provider(providerId)?.kind?.ifBlank { null } ?: "usage"
        ledger.insertSnapshot(
            SnapshotRow(
                providerId = providerId,
                accountId = account.accountId,
                kind = kind,
                source = "manual",
                currentSpendUsd = amountUsd,
                periodStartMillis = start,
                periodEndMillis = end,
                fetchedAtMillis = now,
            ),
        )
        JniGate.run { recompute(); bumpData() }
    }

    fun refreshProvider(providerId: String) {
        if (isRefreshing) return
        isRefreshing = true
        JniGate.run {
            try {
                val nowMillis = nowMillis()
                val provider = catalog.provider(providerId)
                for (account in ledger.accounts(providerId)) {
                    val lastFetched = ledger.snapshots()
                        .filter { it.accountId == account.accountId }
                        .maxByOrNull { it.fetchedAtMillis }
                        ?.fetchedAtMillis
                    if (provider != null && !provider.shouldFetch(lastFetched, nowMillis)) {
                        continue
                    }
                    val fields = loadCredentialFields(account)
                    if (fields.isEmpty()) continue
                    val result = fetch(account, fields)
                    if (result.ok && result.snapshot != null) {
                        ledger.insertSnapshot(result.snapshot.copy(accountId = account.accountId))
                    }
                }
                recompute()
                JniGate.onMain {
                    dataRevision += 1
                    isRefreshing = false
                }
            } catch (error: Throwable) {
                Log.e(TAG, "refreshProvider", error)
                JniGate.onMain { isRefreshing = false }
            }
        }
    }

    fun verifyConnection(
        account: AccountRow,
        fields: Map<String, String>,
        persist: Boolean,
        onDone: (FetchResult) -> Unit,
    ) {
        JniGate.run {
            val result = testAndSave(account, fields, persist)
            JniGate.onMain {
                dataRevision += 1
                onDone(result)
            }
        }
    }

    private fun bumpData() {
        JniGate.onMain { dataRevision += 1 }
    }

    private fun noteUserHasData() {
        JniGate.onMain { didClearAllData = false }
    }

    companion object {
        const val TAG = "TollCat"
    }
}

enum class AppTab { Dashboard, Services, Settings }

sealed class ServicesRoute {
    data object List : ServicesRoute()
    data object Add : ServicesRoute()
    /** 添加列表里「更多服务」那一页：常见服务之外剩下的全部。搜索仍走全目录。 */
    data object AddMore : ServicesRoute()
    /** 不再花钱、但过去花过的那些。入口和「添加服务」同一节。 */
    data object Past : ServicesRoute()
    data class Detail(val providerId: String) : ServicesRoute()
    data class Setup(val providerId: String, val accountId: String) : ServicesRoute()
}
