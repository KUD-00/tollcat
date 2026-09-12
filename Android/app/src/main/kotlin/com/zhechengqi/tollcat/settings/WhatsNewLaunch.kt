package com.zhechengqi.tollcat.settings

/**
 * 更新后第一次冷启动要不要弹弹出面、弹哪几条。
 *
 * 判据全部从参数进来：这里不读系统时间、不读 BuildConfig、不读 SharedPreferences。
 * 和 iOS 的 `WhatsNewLaunch` 是同一套规矩（首装不弹、跳版合并、安静的不弹、只前进），
 * 两边各写一份是有意的：这属于界面层，`MeterCore` 不认识抽屉。
 * 改了一边一定要改另一边——判据漂了，两个端就会对同一次更新给出不同答案。
 */
object WhatsNewLaunch {
    /** 待弹的条目，新的在上。空 = 不弹。 */
    fun pending(
        entries: List<WhatsNewEntry> = WhatsNewCatalog.entries,
        currentVersion: String,
        lastSeenVersion: String,
        platform: String = "android",
        hasCompletedOnboarding: Boolean,
        completedOnboardingThisLaunch: Boolean,
        skipSheet: Boolean,
    ): List<WhatsNewEntry> {
        if (!hasCompletedOnboarding || completedOnboardingThisLaunch || skipSheet) return emptyList()
        // 首装不弹：没用过的 App 谈不上「变化」。
        if (lastSeenVersion.isEmpty()) return emptyList()
        val current = ReleaseVersion.parse(currentVersion) ?: return emptyList()
        val lastSeen = ReleaseVersion.parse(lastSeenVersion) ?: return emptyList()
        if (lastSeen >= current) return emptyList()
        return entries.filter { entry ->
            if (!entry.showsDrawer || platform !in entry.platforms) return@filter false
            val version = ReleaseVersion.parse(entry.version) ?: return@filter false
            version > lastSeen && version <= current
        }
    }

    /**
     * 这一版的打断机会用掉了。**弹没弹都调**——否则连着几个安静的热修复会攒出
     * 一张多段面板，正好是最不该打断的那次。只前进。
     */
    fun advanced(lastSeenVersion: String, currentVersion: String): String {
        val current = ReleaseVersion.parse(currentVersion) ?: return lastSeenVersion
        val lastSeen = ReleaseVersion.parse(lastSeenVersion) ?: return currentVersion
        return if (lastSeen >= current) lastSeenVersion else currentVersion
    }

    /** 设置里的全量列表：这一端能看到的所有条目，不管弹没弹。 */
    fun history(
        entries: List<WhatsNewEntry> = WhatsNewCatalog.entries,
        platform: String = "android",
    ): List<WhatsNewEntry> = entries.filter { platform in it.platforms }
}

/** `X.Y.Z` 的可比大小。字符串比不行：`1.10.0` 会排在 `1.9.0` 前面。 */
data class ReleaseVersion(val major: Int, val minor: Int, val patch: Int) : Comparable<ReleaseVersion> {
    override fun compareTo(other: ReleaseVersion): Int =
        compareValuesBy(this, other, { it.major }, { it.minor }, { it.patch })

    companion object {
        /** 解不出来就是 null，调用方一律当「不知道」——宁可不弹，也不要放两遍。 */
        fun parse(raw: String): ReleaseVersion? {
            val parts = raw.split(".")
            if (parts.size != 3) return null
            val numbers = parts.map { it.toIntOrNull() ?: return null }
            if (numbers.any { it < 0 }) return null
            return ReleaseVersion(numbers[0], numbers[1], numbers[2])
        }
    }
}
