package com.zhechengqi.tollcat.dashboard

/** 仪表盘上点一家：优先落到那份账号，没有账号 id 才落到厂商页。 */
internal fun dashboardAttentionTarget(accountId: String, providerId: String): String? {
    return accountId.ifBlank { providerId }.takeIf { it.isNotBlank() }
}

internal fun dashboardOpenAction(
    accountId: String,
    providerId: String,
    onOpen: (String) -> Unit,
): (() -> Unit)? {
    val target = dashboardAttentionTarget(accountId, providerId) ?: return null
    return { onOpen(target) }
}
