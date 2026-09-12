package com.zhechengqi.tollcat

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class SqliteLedgerStore(
    context: Context,
    name: String = DB,
) : LedgerStore {
    private val db = Helper(context.applicationContext, name).writableDatabase

    override fun insertSnapshot(row: SnapshotRow) {
        db.insertOrThrow("snapshots", null, snapshotValues(row))
    }

    override fun replaceAccountSnapshots(accountId: String, row: SnapshotRow) {
        db.beginTransaction()
        try {
            db.delete("snapshots", "account_id = ?", arrayOf(accountId))
            db.insertOrThrow("snapshots", null, snapshotValues(row))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    override fun snapshots(): List<SnapshotRow> {
        val rows = mutableListOf<SnapshotRow>()
        db.query("snapshots", null, null, null, null, null, "fetched_at ASC").use { cursor ->
            while (cursor.moveToNext()) {
                rows.add(readSnapshot(cursor))
            }
        }
        return rows
    }

    override fun lastSnapshotFetchedAtMillis(): Long? {
        db.rawQuery("SELECT MAX(fetched_at) FROM snapshots", null).use { cursor ->
            if (!cursor.moveToFirst() || cursor.isNull(0)) return null
            return cursor.getLong(0).takeIf { it > 0L }
        }
    }

    override fun upsertMembership(row: MembershipRow) {
        val values = ContentValues().apply {
            put("provider_id", row.providerId)
            put("sort_index", row.sortIndex)
        }
        db.insertWithOnConflict("memberships", null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    override fun memberships(): List<MembershipRow> {
        val rows = mutableListOf<MembershipRow>()
        db.query("memberships", null, null, null, null, null, "sort_index ASC").use { cursor ->
            val provider = cursor.getColumnIndexOrThrow("provider_id")
            val sort = cursor.getColumnIndexOrThrow("sort_index")
            while (cursor.moveToNext()) {
                rows.add(MembershipRow(cursor.getString(provider), cursor.getInt(sort)))
            }
        }
        return rows
    }

    override fun deleteMembership(providerId: String) {
        db.beginTransaction()
        try {
            val accounts = accounts(providerId)
            for (account in accounts) {
                db.delete("snapshots", "account_id = ?", arrayOf(account.accountId))
                db.delete("accounts", "account_id = ?", arrayOf(account.accountId))
            }
            db.delete("subscriptions", "provider_id = ?", arrayOf(providerId))
            db.delete("memberships", "provider_id = ?", arrayOf(providerId))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    override fun upsertAccount(row: AccountRow) {
        val values = ContentValues().apply {
            put("account_id", row.accountId)
            put("provider_id", row.providerId)
            put("credential_reference", row.credentialReference)
            put("sort_index", row.sortIndex)
            put("transfer_extras", row.transferExtrasJson)
        }
        db.insertWithOnConflict("accounts", null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    override fun accounts(): List<AccountRow> {
        val rows = mutableListOf<AccountRow>()
        db.query("accounts", null, null, null, null, null, "sort_index ASC").use { cursor ->
            while (cursor.moveToNext()) {
                rows.add(readAccount(cursor))
            }
        }
        return rows
    }

    override fun accounts(providerId: String): List<AccountRow> {
        val rows = mutableListOf<AccountRow>()
        db.query(
            "accounts",
            null,
            "provider_id = ?",
            arrayOf(providerId),
            null,
            null,
            "sort_index ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                rows.add(readAccount(cursor))
            }
        }
        return rows
    }

    override fun deleteAccount(accountId: String) {
        db.beginTransaction()
        try {
            db.delete("snapshots", "account_id = ?", arrayOf(accountId))
            db.delete("subscriptions", "account_id = ?", arrayOf(accountId))
            db.delete("accounts", "account_id = ?", arrayOf(accountId))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    override fun upsertSubscription(row: SubscriptionRow) {
        val values = ContentValues().apply {
            put("id", row.id)
            put("name", row.name)
            put("amount_usd", row.amountUsd)
            put("period", row.period)
            put("anchor_year", row.anchorYear)
            put("anchor_month", row.anchorMonth)
            put("anchor_day", row.anchorDay)
            put("end_year", row.endYear)
            put("end_month", row.endMonth)
            put("end_day", row.endDay)
            put("provider_id", row.providerId)
            put("account_id", row.accountId)
            put("quantity", row.quantity)
        }
        db.insertWithOnConflict("subscriptions", null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    override fun deleteSubscription(id: String) {
        db.delete("subscriptions", "id = ?", arrayOf(id))
    }

    override fun subscriptions(): List<SubscriptionRow> {
        val rows = mutableListOf<SubscriptionRow>()
        db.query("subscriptions", null, null, null, null, null, "name ASC").use { cursor ->
            val id = cursor.getColumnIndexOrThrow("id")
            val name = cursor.getColumnIndexOrThrow("name")
            val amount = cursor.getColumnIndexOrThrow("amount_usd")
            val period = cursor.getColumnIndexOrThrow("period")
            val year = cursor.getColumnIndexOrThrow("anchor_year")
            val month = cursor.getColumnIndexOrThrow("anchor_month")
            val day = cursor.getColumnIndexOrThrow("anchor_day")
            val endYear = cursor.getColumnIndexOrThrow("end_year")
            val endMonth = cursor.getColumnIndexOrThrow("end_month")
            val endDay = cursor.getColumnIndexOrThrow("end_day")
            val provider = cursor.getColumnIndexOrThrow("provider_id")
            val account = cursor.getColumnIndexOrThrow("account_id")
            val quantity = cursor.getColumnIndexOrThrow("quantity")
            while (cursor.moveToNext()) {
                rows.add(
                    SubscriptionRow(
                        id = cursor.getString(id),
                        name = cursor.getString(name),
                        amountUsd = cursor.getString(amount),
                        period = cursor.getString(period),
                        anchorYear = cursor.getInt(year),
                        anchorMonth = cursor.getInt(month),
                        anchorDay = cursor.getInt(day),
                        endYear = cursor.optionalInt(endYear),
                        endMonth = cursor.optionalInt(endMonth),
                        endDay = cursor.optionalInt(endDay),
                        providerId = cursor.optionalString(provider),
                        accountId = cursor.optionalString(account),
                        quantity = cursor.getInt(quantity).coerceAtLeast(1),
                    ),
                )
            }
        }
        return rows
    }

    override fun clearAll() {
        db.beginTransaction()
        try {
            db.delete("snapshots", null, null)
            db.delete("accounts", null, null)
            db.delete("memberships", null, null)
            db.delete("subscriptions", null, null)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    private fun snapshotValues(row: SnapshotRow): ContentValues {
        return ContentValues().apply {
            put("provider_id", row.providerId)
            put("account_id", row.accountId)
            put("kind", row.kind)
            put("source", row.source)
            put("current_spend_usd", row.currentSpendUsd)
            put("balance_usd", row.balanceUsd)
            put("committed_monthly_usd", row.committedMonthlyUsd)
            put("charge_day", row.chargeDayOfMonth)
            put("free_quota_used_ratio", row.freeQuotaUsedRatio)
            put("daily_usd", row.dailyUsdJson)
            put("converted", row.convertedJson)
            put("wallets", row.walletsJson)
            put("spend_lines", row.spendLinesJson)
            put("period_start", row.periodStartMillis)
            put("period_end", row.periodEndMillis)
            put("fetched_at", row.fetchedAtMillis)
        }
    }

    private fun readSnapshot(cursor: Cursor): SnapshotRow {
        return SnapshotRow(
            providerId = cursor.getString(cursor.getColumnIndexOrThrow("provider_id")),
            accountId = cursor.getString(cursor.getColumnIndexOrThrow("account_id")),
            kind = cursor.getString(cursor.getColumnIndexOrThrow("kind")),
            source = cursor.optionalString(cursor.getColumnIndexOrThrow("source")) ?: "api",
            currentSpendUsd = cursor.optionalString(cursor.getColumnIndexOrThrow("current_spend_usd")),
            balanceUsd = cursor.optionalString(cursor.getColumnIndexOrThrow("balance_usd")),
            committedMonthlyUsd = cursor.optionalString(cursor.getColumnIndexOrThrow("committed_monthly_usd")),
            chargeDayOfMonth = cursor.optionalInt(cursor.getColumnIndexOrThrow("charge_day")),
            freeQuotaUsedRatio = cursor.optionalDouble(cursor.getColumnIndexOrThrow("free_quota_used_ratio")),
            dailyUsdJson = cursor.optionalString(cursor.getColumnIndexOrThrow("daily_usd")),
            convertedJson = cursor.optionalString(cursor.getColumnIndexOrThrow("converted")),
            walletsJson = cursor.optionalString(cursor.getColumnIndexOrThrow("wallets")),
            spendLinesJson = cursor.optionalString(cursor.getColumnIndexOrThrow("spend_lines")),
            periodStartMillis = cursor.optionalLong(cursor.getColumnIndexOrThrow("period_start")) ?: 0,
            periodEndMillis = cursor.optionalLong(cursor.getColumnIndexOrThrow("period_end")) ?: 0,
            fetchedAtMillis = cursor.getLong(cursor.getColumnIndexOrThrow("fetched_at")),
        )
    }

    private fun readAccount(cursor: Cursor): AccountRow {
        return AccountRow(
            accountId = cursor.getString(cursor.getColumnIndexOrThrow("account_id")),
            providerId = cursor.getString(cursor.getColumnIndexOrThrow("provider_id")),
            credentialReference = cursor.getString(cursor.getColumnIndexOrThrow("credential_reference")),
            sortIndex = cursor.getInt(cursor.getColumnIndexOrThrow("sort_index")),
            transferExtrasJson = cursor.optionalString(cursor.getColumnIndexOrThrow("transfer_extras")),
        )
    }

    private class Helper(
        context: Context,
        name: String,
    ) : SQLiteOpenHelper(context, name, null, VERSION) {
        override fun onCreate(db: SQLiteDatabase) {
            db.execSQL(
                """
                CREATE TABLE snapshots (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    provider_id TEXT NOT NULL,
                    account_id TEXT NOT NULL,
                    kind TEXT NOT NULL,
                    source TEXT NOT NULL DEFAULT 'api',
                    current_spend_usd TEXT,
                    balance_usd TEXT,
                    committed_monthly_usd TEXT,
                    charge_day INTEGER,
                    free_quota_used_ratio REAL,
                    daily_usd TEXT,
                    converted TEXT,
                    wallets TEXT,
                    spend_lines TEXT,
                    period_start INTEGER NOT NULL DEFAULT 0,
                    period_end INTEGER NOT NULL DEFAULT 0,
                    fetched_at INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            db.execSQL(
                """
                CREATE TABLE memberships (
                    provider_id TEXT PRIMARY KEY,
                    sort_index INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            db.execSQL(
                """
                CREATE TABLE accounts (
                    account_id TEXT PRIMARY KEY,
                    provider_id TEXT NOT NULL,
                    credential_reference TEXT NOT NULL,
                    sort_index INTEGER NOT NULL,
                    transfer_extras TEXT
                )
                """.trimIndent(),
            )
            db.execSQL(
                """
                CREATE TABLE subscriptions (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    amount_usd TEXT NOT NULL,
                    period TEXT NOT NULL,
                    anchor_year INTEGER NOT NULL,
                    anchor_month INTEGER NOT NULL,
                    anchor_day INTEGER NOT NULL,
                    end_year INTEGER,
                    end_month INTEGER,
                    end_day INTEGER,
                    provider_id TEXT,
                    account_id TEXT,
                    quantity INTEGER NOT NULL DEFAULT 1
                )
                """.trimIndent(),
            )
        }

        /**
         * **升级一律重建，不做迁移。**
         *
         * 这一端的库是「刷新一次就有」的缓存：读数、账号、订阅都能重新接一次拿回来，
         * 而 Android 还没上过 Play，没有需要照顾的旧版本。维护迁移台阶的代价不是
         * 写那几行 ALTER，是每加一个字段都要想清楚「三种旧形状分别会变成什么」——
         * 上一版就是在这里翻的车：按版本号加 ALTER，却没给 7 以前的形状留台阶，
         * 把 v4 的库改成了一张四不像的表，还盖上「已是最新」的章。
         *
         * 真要开始照顾旧库，是上架那天的事，那时再一次性把台阶补齐。
         */
        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            db.execSQL("DROP TABLE IF EXISTS snapshots")
            db.execSQL("DROP TABLE IF EXISTS memberships")
            db.execSQL("DROP TABLE IF EXISTS accounts")
            db.execSQL("DROP TABLE IF EXISTS subscriptions")
            onCreate(db)
        }

        /** 降级同理：装回旧版也重建，不留半新半旧的表。 */
        override fun onDowngrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            onUpgrade(db, oldVersion, newVersion)
        }
    }

    private companion object {
        const val DB = "tollcat-ledger.db"

        const val VERSION = 9
    }
}

// 只判「这一格是不是 NULL」。**不判「这一列在不在」**——建表只有一份，
// 升级一律重建，列缺了就该当场吵，而不是静静读成 null 少算一笔钱。

private fun Cursor.optionalString(index: Int): String? {
    if (isNull(index)) return null
    return getString(index)
}

private fun Cursor.optionalInt(index: Int): Int? {
    if (isNull(index)) return null
    return getInt(index)
}

private fun Cursor.optionalLong(index: Int): Long? {
    if (isNull(index)) return null
    return getLong(index)
}

private fun Cursor.optionalDouble(index: Int): Double? {
    if (isNull(index)) return null
    return getDouble(index)
}
