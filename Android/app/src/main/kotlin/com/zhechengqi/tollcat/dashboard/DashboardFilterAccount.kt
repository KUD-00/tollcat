package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.TollCatSession

/** 筛选抽屉里可排除的一个账号。同厂商多账号时 siblingIndex 用来区分。 */
data class DashboardFilterAccount(
    val accountId: String,
    val providerId: String,
    val displayName: String,
    val colorKey: String,
    val siblingIndex: Int,
    val siblingCount: Int,
) {
    companion object {
        fun from(session: TollCatSession): List<DashboardFilterAccount> {
            return session.liveMemberships().flatMap { membership ->
                val provider = session.catalog.provider(membership.providerId)
                val accounts = session.liveAccounts(membership.providerId)
                accounts.mapIndexed { index, account ->
                    DashboardFilterAccount(
                        accountId = account.accountId,
                        providerId = membership.providerId,
                        displayName = AccountExtras.displayName(
                            account,
                            provider?.displayName ?: membership.providerId,
                        ),
                        colorKey = provider?.colorKey?.ifBlank { membership.providerId }
                            ?: membership.providerId,
                        siblingIndex = index,
                        siblingCount = accounts.size,
                    )
                }
            }
        }
    }
}
