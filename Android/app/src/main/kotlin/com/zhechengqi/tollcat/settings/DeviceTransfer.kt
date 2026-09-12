package com.zhechengqi.tollcat.settings

import android.content.Context
import android.net.Uri
import com.zhechengqi.tollcat.AccountRow
import com.zhechengqi.tollcat.dashboard.DashboardModules
import com.zhechengqi.tollcat.CredentialStore
import com.zhechengqi.tollcat.LedgerStore
import com.zhechengqi.tollcat.MeterCoreNative
import com.zhechengqi.tollcat.MembershipRow
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.SubscriptionRow
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.security.SecureRandom
import java.util.Calendar
import java.util.TimeZone
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

private const val MAGIC = "TOLL"
private const val VERSION: Byte = 1
private const val SALT_LEN = 16
private const val NONCE_LEN = 12
private const val TAG_LEN = 16
private const val ITERATIONS = 600_000
private const val MIN_ITER = 600_000
private const val MAX_ITER = 4_000_000
private const val KEY_LEN = 32
private const val HEADER_LEN = 4 + 1 + 16 + 4 + 12 + 8
private const val APPLE_REF = 978_307_200.0
private const val LIFETIME_MS = 24L * 60 * 60 * 1000
private const val CODE_LENGTH = 10

data class TransferExport(
    val displayCode: String,
    val fileBytes: ByteArray,
    val notAfterMillis: Long,
)

object DeviceTransfer {
    fun export(
        ledger: LedgerStore,
        credentials: CredentialStore,
        preferences: PreferencesStore,
        nowMillis: Long,
    ): TransferExport {
        val code = generateCode()
        val payload = collect(ledger, credentials, preferences, nowMillis)
        val sealed = seal(payload.toString().toByteArray(Charsets.UTF_8), code.raw, nowMillis)
        return TransferExport(code.display, sealed.first, sealed.second)
    }

    fun importPayload(
        fileBytes: ByteArray,
        userCode: String,
        ledger: LedgerStore,
        credentials: CredentialStore,
        preferences: PreferencesStore,
        nowMillis: Long,
    ) {
        val code = normalizeCode(userCode) ?: error("bad-code")
        val plain = open(fileBytes, code, nowMillis)
        apply(JSONObject(String(plain, Charsets.UTF_8)), ledger, credentials, preferences)
    }

    fun readUri(context: Context, uri: Uri): ByteArray {
        return context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: error("unreadable")
    }

    private data class Code(val raw: String, val display: String)

    /**
     * 码本身在共享层生成（`MeterCore/TransferCode`）：字母表、位数、
     * 「I/L→1、O→0」那套只有一份。这一端只负责摆成 `XXXXX-XXXXX`。
     */
    private fun generateCode(): Code {
        val raw = MeterCoreNative.transferCodeGenerate()
        require(raw.length == CODE_LENGTH) { "bad-code" }
        return Code(raw, raw.substring(0, 5) + "-" + raw.substring(5))
    }

    private fun normalizeCode(input: String): String? {
        return MeterCoreNative.transferCodeNormalize(input).takeIf { it.length == CODE_LENGTH }
    }

    private fun collect(
        ledger: LedgerStore,
        credentials: CredentialStore,
        preferences: PreferencesStore,
        nowMillis: Long,
    ): JSONObject {
        val connections = JSONArray()
        for (account in ledger.accounts()) {
            val secret = credentials.read(account.credentialReference)
            val fields = runCatching { JSONObject(secret ?: "{}") }.getOrElse { JSONObject() }
            val fieldMap = JSONObject()
            fields.keys().forEach { key -> fieldMap.put(key, fields.optString(key)) }
            // 先铺这一端不认识的那些键（昵称、archivedAt、指纹、信箱投递 key…），
            // 再用本机确实管着的字段盖上去。不认识 ≠ 可以丢。
            val json = account.transferExtrasJson
                ?.let { raw -> runCatching { JSONObject(raw) }.getOrNull() }
                ?: JSONObject()
            json.put("accountID", account.accountId)
                .put("providerID", account.providerId)
                .put("sortIndex", account.sortIndex)
                .put("credentialReference", account.credentialReference)
                .put("includeInGlobalRefresh", preferences.includeInGlobalRefresh(account.accountId))
                .put("credentialFields", fieldMap)
            if (!json.has("isEnabled")) json.put("isEnabled", true)
            connections.put(json)
        }
        val memberships = JSONArray()
        for (row in ledger.memberships()) {
            memberships.put(JSONObject().put("providerID", row.providerId).put("sortIndex", row.sortIndex))
        }
        val subscriptions = JSONArray()
        for (row in ledger.subscriptions()) {
            subscriptions.put(
                JSONObject()
                    .put("name", row.name)
                    .put("amountUSD", row.amountUsd)
                    .put("period", row.period)
                    .put("anchorYear", row.anchorYear)
                    .put("anchorMonth", row.anchorMonth)
                    .put("anchorDay", row.anchorDay)
                    .put("endYear", row.endYear)
                    .put("endMonth", row.endMonth)
                    .put("endDay", row.endDay)
                    .put("accountID", row.accountId)
                    .put("providerID", row.providerId)
                    .put("quantity", row.quantity),
            )
        }
        val prefs = JSONObject()
            .put("includeAWSInGlobalRefresh", false)
            .put("isReminderEnabled", preferences.reminderEnabled)
            .put(
                "reminderSchedule",
                JSONObject()
                    .put("frequency", preferences.reminderFrequency)
                    .put("hour", preferences.reminderHour)
                    .put("minute", preferences.reminderMinute)
                    .put("weekday", preferences.reminderWeekday)
                    .put("dayOfMonth", preferences.reminderDayOfMonth),
            )
            .put("appearanceRaw", preferences.appearance)
            .put("hasCompletedOnboarding", true)
            .put("providerHistoryRangeRaw", "months12")
            .put("hidesCat", preferences.hidesCat)
            .put("refreshesUsageOnActivate", preferences.refreshOnActivate)
            .put("displayCurrency", preferences.displayCurrency)
            .put("seenUsageGuideIDs", JSONArray(preferences.seenUsageGuides().toList()))
            .put("lastSeenWhatsNewVersion", preferences.lastSeenWhatsNewVersion)
        val order = preferences.enabledModuleOrder()
        if (order != DashboardModules.defaultOn ||
            preferences.pinnedAccountIds.isNotEmpty() ||
            preferences.monthlyBudgetUsd.isNotBlank()
        ) {
            prefs.put(
                "dashboardLayout",
                JSONObject()
                    .put("v", 1)
                    .put("order", JSONArray(order))
                    .put("pinnedAccounts", JSONArray(preferences.pinnedAccountIds.toList()))
                    .put("monthlyBudgetUSD", preferences.monthlyBudgetUsd),
            )
        }
        val stored = InboxMailboxStore.read(credentials)
            ?: InboxMailboxStore.migrateFromPreferences(credentials, preferences)
        val mailbox = if (stored != null) {
            JSONObject().put("mailbox", stored.mailbox).put("readKey", stored.readKey)
        } else {
            JSONObject.NULL
        }
        val manuals = JSONArray()
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
        for (row in ledger.snapshots().filter { it.source == "manual" }) {
            cal.timeInMillis = row.periodStartMillis
            manuals.put(
                JSONObject()
                    .put("accountID", row.accountId)
                    .put("providerID", row.providerId)
                    .put("periodYear", cal.get(Calendar.YEAR))
                    .put("periodMonth", cal.get(Calendar.MONTH) + 1)
                    .put("amountUSD", row.currentSpendUsd ?: "0")
                    .put("enteredAt", appleRef(row.fetchedAtMillis))
                    .put("kindRaw", row.kind),
            )
        }
        return JSONObject()
            .put("schemaVersion", 1)
            .put("connections", connections)
            .put("memberships", memberships)
            .put("subscriptions", subscriptions)
            .put("preferences", prefs)
            .put("mailbox", mailbox)
            .put("manualUsages", manuals)
    }

    /**
     * **会抛的事全部发生在会毁的事之前。**
     *
     * 这一段以前是反的：先 `credentials.deleteAll()` + `ledger.clearAll()`，再拿
     * `getString()` 一条条解析。包里有一处坏字段，本机的接入就已经没了，而新数据
     * 只进了一半——Keychain / Keystore 不在事务里，SQLite 这边也没有事务包着。
     * iOS 那份在同一个位置写了同样一条规矩，理由一模一样。
     */
    private fun apply(
        payload: JSONObject,
        ledger: LedgerStore,
        credentials: CredentialStore,
        preferences: PreferencesStore,
    ) {
        if (payload.optInt("schemaVersion") != 1) error("schema")
        val parsed = parse(payload)

        // ↓ 从这里开始才动本机的东西。上面任何一步抛了，本机原样不动。
        for (account in ledger.accounts()) {
            credentials.delete(account.credentialReference)
        }
        credentials.deleteAll()
        ledger.clearAll()

        for (row in parsed.memberships) ledger.upsertMembership(row)
        for (connection in parsed.connections) {
            ledger.upsertAccount(connection.account)
            if (connection.credentialFields != null) {
                credentials.save(connection.credentialFields, connection.account.credentialReference)
            }
            connection.includeInGlobalRefresh?.let {
                preferences.setIncludeInGlobalRefresh(connection.account.accountId, it)
            }
        }
        for (row in parsed.subscriptions) ledger.upsertSubscription(row)
        for (row in parsed.manualUsages) ledger.insertSnapshot(row)

        parsed.mailbox?.let { (mailbox, readKey) ->
            InboxMailboxStore.save(credentials, mailbox, readKey)
        }
        parsed.preferences?.let { prefs ->
            applyPreferences(prefs, preferences)
            preferences.applyAppearance()
            ReminderAlarmScheduler.sync(preferences.appContext)
        }
    }

    /** 解出来的一份包。到这一步为止一个字节都还没写。 */
    private data class Parsed(
        val memberships: List<MembershipRow>,
        val connections: List<ParsedConnection>,
        val subscriptions: List<SubscriptionRow>,
        val manualUsages: List<SnapshotRow>,
        val mailbox: Pair<String, String>?,
        val preferences: JSONObject?,
    )

    private data class ParsedConnection(
        val account: AccountRow,
        val credentialFields: String?,
        val includeInGlobalRefresh: Boolean?,
    )

    private fun parse(payload: JSONObject): Parsed {
        val memberships = payload.optJSONArray("memberships") ?: JSONArray()
        val parsedMemberships = (0 until memberships.length()).map { index ->
            val item = memberships.getJSONObject(index)
            MembershipRow(item.getString("providerID"), item.optInt("sortIndex"))
        }

        val connections = payload.optJSONArray("connections") ?: JSONArray()
        val parsedConnections = (0 until connections.length()).map { index ->
            val item = connections.getJSONObject(index)
            val accountId = item.getString("accountID")
            val reference = item.optString("credentialReference").ifBlank { "acct.$accountId" }
            val fields = item.optJSONObject("credentialFields") ?: JSONObject()
            ParsedConnection(
                account = AccountRow(
                    accountId = accountId,
                    providerId = item.getString("providerID"),
                    credentialReference = reference,
                    sortIndex = item.optInt("sortIndex"),
                    // 这一端不认识的键留着，导出时原样吐回。
                    transferExtrasJson = unknownConnectionFields(item),
                ),
                credentialFields = fields.toString().takeIf { fields.length() > 0 },
                includeInGlobalRefresh = if (item.has("includeInGlobalRefresh") &&
                    !item.isNull("includeInGlobalRefresh")
                ) {
                    item.optBoolean("includeInGlobalRefresh")
                } else {
                    null
                },
            )
        }

        val subscriptions = payload.optJSONArray("subscriptions") ?: JSONArray()
        val parsedSubscriptions = (0 until subscriptions.length()).map { index ->
            val item = subscriptions.getJSONObject(index)
            SubscriptionRow(
                id = UUID.randomUUID().toString(),
                name = item.getString("name"),
                amountUsd = item.getString("amountUSD"),
                period = item.getString("period"),
                anchorYear = item.getInt("anchorYear"),
                anchorMonth = item.getInt("anchorMonth"),
                anchorDay = item.getInt("anchorDay"),
                endYear = if (item.has("endYear") && !item.isNull("endYear")) item.getInt("endYear") else null,
                endMonth = if (item.has("endMonth") && !item.isNull("endMonth")) item.getInt("endMonth") else null,
                endDay = if (item.has("endDay") && !item.isNull("endDay")) item.getInt("endDay") else null,
                providerId = item.optString("providerID").ifBlank { null },
                accountId = item.optString("accountID").ifBlank { null },
                quantity = item.optInt("quantity", 1),
            )
        }

        val manuals = payload.optJSONArray("manualUsages") ?: JSONArray()
        val parsedManuals = (0 until manuals.length()).map { index ->
            val item = manuals.getJSONObject(index)
            val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
            cal.set(item.getInt("periodYear"), item.getInt("periodMonth") - 1, 1, 0, 0, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val start = cal.timeInMillis
            cal.add(Calendar.MONTH, 1)
            SnapshotRow(
                providerId = item.getString("providerID"),
                accountId = item.getString("accountID"),
                kind = item.optString("kindRaw", "usage"),
                source = "manual",
                currentSpendUsd = item.getString("amountUSD"),
                periodStartMillis = start,
                periodEndMillis = cal.timeInMillis - 1,
                fetchedAtMillis = fromAppleRef(item.optDouble("enteredAt")),
            )
        }

        val mailbox = payload.optJSONObject("mailbox")?.let { item ->
            val name = item.optString("mailbox")
            val readKey = item.optString("readKey")
            if (name.isBlank() || readKey.isBlank()) null else name to readKey
        }

        return Parsed(
            memberships = parsedMemberships,
            connections = parsedConnections,
            subscriptions = parsedSubscriptions,
            manualUsages = parsedManuals,
            mailbox = mailbox,
            preferences = payload.optJSONObject("preferences"),
        )
    }

    /** 这一端管着的键之外的一切。留着才能原样送回下一台设备。 */
    private fun unknownConnectionFields(item: JSONObject): String? {
        val known = setOf(
            "accountID",
            "providerID",
            "sortIndex",
            "credentialReference",
            "includeInGlobalRefresh",
            "credentialFields",
        )
        val extras = JSONObject()
        item.keys().forEach { key ->
            if (key !in known && !item.isNull(key)) extras.put(key, item.get(key))
        }
        return extras.toString().takeIf { extras.length() > 0 }
    }

    private fun applyPreferences(prefs: JSONObject, preferences: PreferencesStore) {
        preferences.displayCurrency = prefs.optString("displayCurrency", preferences.displayCurrency)
        preferences.hidesCat = prefs.optBoolean("hidesCat", preferences.hidesCat)
        preferences.refreshOnActivate = prefs.optBoolean("refreshesUsageOnActivate", preferences.refreshOnActivate)
        preferences.reminderEnabled = prefs.optBoolean("isReminderEnabled", preferences.reminderEnabled)
        preferences.appearance = prefs.optString("appearanceRaw", preferences.appearance)
        prefs.optJSONObject("reminderSchedule")?.let { schedule ->
            preferences.reminderHour = schedule.optInt("hour", preferences.reminderHour)
            preferences.reminderMinute = schedule.optInt("minute", preferences.reminderMinute)
            preferences.reminderWeekday = schedule.optInt("weekday", preferences.reminderWeekday)
            preferences.reminderDayOfMonth = schedule.optInt("dayOfMonth", preferences.reminderDayOfMonth)
            if (schedule.has("frequency")) {
                preferences.reminderFrequency = schedule.optString("frequency", preferences.reminderFrequency)
            }
        }
        prefs.optString("lastSeenWhatsNewVersion").takeIf { it.isNotBlank() }?.let {
            preferences.lastSeenWhatsNewVersion = it
        }
        val layout = prefs.optJSONObject("dashboardLayout")
        if (layout == null) {
            preferences.resetModuleLayout()
            preferences.pinnedAccountIds = emptySet()
            preferences.monthlyBudgetUsd = ""
            return
        }
        // **顺序也搬**。只捡「开了哪几块」会把用户排好的版式在换机时抹平；
        // 不认识的 id 由 `normalized` 丢掉，旧包读到新模块也不会炸。
        val order = layout.optJSONArray("order")
        if (order == null) {
            preferences.resetModuleLayout()
        } else {
            preferences.setModuleOrder(
                (0 until order.length()).map { order.optString(it) }.filter { it.isNotBlank() },
            )
        }
        val pins = layout.optJSONArray("pinnedAccounts")
        preferences.pinnedAccountIds = if (pins == null) {
            emptySet()
        } else {
            (0 until pins.length()).map { pins.optString(it) }.filter { it.isNotBlank() }.toSet()
        }
        preferences.monthlyBudgetUsd = layout.optString("monthlyBudgetUSD")
    }

    private fun seal(plaintext: ByteArray, password: String, nowMillis: Long): Pair<ByteArray, Long> {
        val salt = ByteArray(SALT_LEN).also { SecureRandom().nextBytes(it) }
        val nonce = ByteArray(NONCE_LEN).also { SecureRandom().nextBytes(it) }
        val notAfter = nowMillis / 1000 + LIFETIME_MS / 1000
        val header = headerBytes(salt, ITERATIONS, nonce, notAfter)
        val key = derive(password, salt, ITERATIONS)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_LEN * 8, nonce))
        cipher.updateAAD(header)
        val sealed = cipher.doFinal(plaintext)
        val ciphertext = sealed.copyOfRange(0, sealed.size - TAG_LEN)
        val tag = sealed.copyOfRange(sealed.size - TAG_LEN, sealed.size)
        val out = ByteArrayOutputStream()
        out.write(header)
        out.write(ciphertext)
        out.write(tag)
        return out.toByteArray() to notAfter * 1000
    }

    private fun open(fileBytes: ByteArray, password: String, nowMillis: Long): ByteArray {
        if (fileBytes.size < HEADER_LEN + TAG_LEN) error("invalid")
        val header = fileBytes.copyOfRange(0, HEADER_LEN)
        if (String(header, 0, 4, Charsets.US_ASCII) != MAGIC) error("invalid")
        if (header[4] != VERSION) error("version")
        val salt = header.copyOfRange(5, 21)
        val iterations = readU32(header, 21)
        if (iterations < MIN_ITER || iterations > MAX_ITER) error("kdf")
        val nonce = header.copyOfRange(25, 37)
        val notAfter = readU64(header, 37)
        val tag = fileBytes.copyOfRange(fileBytes.size - TAG_LEN, fileBytes.size)
        val ciphertext = fileBytes.copyOfRange(HEADER_LEN, fileBytes.size - TAG_LEN)
        val key = derive(password, salt, iterations.toInt())
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_LEN * 8, nonce))
        cipher.updateAAD(header)
        val combined = ciphertext + tag
        val plain = runCatching { cipher.doFinal(combined) }.getOrElse { error("auth") }
        if (nowMillis / 1000 >= notAfter) error("expired")
        return plain
    }

    private fun headerBytes(salt: ByteArray, iterations: Int, nonce: ByteArray, notAfter: Long): ByteArray {
        val out = ByteArrayOutputStream(HEADER_LEN)
        out.write(MAGIC.toByteArray(Charsets.US_ASCII))
        out.write(byteArrayOf(VERSION))
        out.write(salt)
        out.write(u32(iterations.toLong()))
        out.write(nonce)
        out.write(u64(notAfter))
        return out.toByteArray()
    }

    private fun derive(password: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(password.toCharArray(), salt, iterations, KEY_LEN * 8)
        return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
    }

    private fun u32(value: Long): ByteArray {
        val v = value.toInt()
        return byteArrayOf(
            (v ushr 24).toByte(),
            (v ushr 16).toByte(),
            (v ushr 8).toByte(),
            v.toByte(),
        )
    }

    private fun u64(value: Long): ByteArray {
        return byteArrayOf(
            (value ushr 56).toByte(),
            (value ushr 48).toByte(),
            (value ushr 40).toByte(),
            (value ushr 32).toByte(),
            (value ushr 24).toByte(),
            (value ushr 16).toByte(),
            (value ushr 8).toByte(),
            value.toByte(),
        )
    }

    private fun readU32(data: ByteArray, offset: Int): Long {
        var v = 0L
        for (i in 0 until 4) v = (v shl 8) or (data[offset + i].toLong() and 0xff)
        return v
    }

    private fun readU64(data: ByteArray, offset: Int): Long {
        var v = 0L
        for (i in 0 until 8) v = (v shl 8) or (data[offset + i].toLong() and 0xff)
        return v
    }

    private fun appleRef(millis: Long): Double = millis / 1000.0 - APPLE_REF

    private fun fromAppleRef(value: Double): Long = ((value + APPLE_REF) * 1000).toLong()
}
