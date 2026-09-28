package com.zhechengqi.tollcat.developer

enum class GalleryItemID(val raw: String) {
    DashboardPage("dashboardPage"),
    Amounts("amounts"),
    Attention("attention"),
    Composition("composition"),
    Comparison("comparison"),
    Modules("modules"),
    Chrome("chrome"),
    Empty("empty"),
    Errors("errors"),
    Charts("charts"),
    Overflow("overflow"),
    Glyphs("glyphs"),
    Rows("rows"),
    Cats("cats"),
    SetupGuides("setupGuides"),
    UsageGuides("usageGuides"),
    VerifyConnection("verifyConnection"),
    CredentialFields("credentialFields"),
    Refresh("refresh"),
    Tips("tips"),
    MonthRange("monthRange"),
    ;

    companion object {
        fun fromRaw(raw: String): GalleryItemID? = entries.firstOrNull { it.raw == raw }
    }
}

enum class GallerySection {
    NewDashboard,
    Empty,
    Errors,
    Boundaries,
    Components,
    ;

    val items: List<GalleryItemID>
        get() = GalleryItemID.entries.filter { it.section == this }
}

val GalleryItemID.section: GallerySection
    get() = when (this) {
        GalleryItemID.DashboardPage,
        GalleryItemID.Amounts,
        GalleryItemID.Attention,
        GalleryItemID.Composition,
        GalleryItemID.Comparison,
        GalleryItemID.Modules,
        GalleryItemID.Chrome,
        -> GallerySection.NewDashboard
        GalleryItemID.Empty -> GallerySection.Empty
        GalleryItemID.Errors -> GallerySection.Errors
        GalleryItemID.Charts,
        GalleryItemID.Overflow,
        -> GallerySection.Boundaries
        GalleryItemID.Glyphs,
        GalleryItemID.Rows,
        GalleryItemID.Cats,
        GalleryItemID.SetupGuides,
        GalleryItemID.UsageGuides,
        GalleryItemID.VerifyConnection,
        GalleryItemID.CredentialFields,
        GalleryItemID.Refresh,
        GalleryItemID.Tips,
        GalleryItemID.MonthRange,
        -> GallerySection.Components
    }

val GalleryItemID.titleRes: Int
    get() = when (this) {
        GalleryItemID.DashboardPage -> com.zhechengqi.tollcat.R.string.dev_gallery_page
        GalleryItemID.Chrome -> com.zhechengqi.tollcat.R.string.dev_gallery_chrome
        GalleryItemID.Modules -> com.zhechengqi.tollcat.R.string.dev_gallery_modules
        GalleryItemID.Empty -> com.zhechengqi.tollcat.R.string.dev_gallery_empty
        GalleryItemID.Errors -> com.zhechengqi.tollcat.R.string.dev_gallery_errors
        GalleryItemID.Amounts -> com.zhechengqi.tollcat.R.string.dev_gallery_hero
        GalleryItemID.Composition -> com.zhechengqi.tollcat.R.string.module_composition
        GalleryItemID.Charts -> com.zhechengqi.tollcat.R.string.dev_gallery_charts
        GalleryItemID.Attention -> com.zhechengqi.tollcat.R.string.dashboard_attention
        GalleryItemID.Overflow -> com.zhechengqi.tollcat.R.string.dev_gallery_overflow
        GalleryItemID.Glyphs -> com.zhechengqi.tollcat.R.string.dev_gallery_glyphs
        GalleryItemID.Rows -> com.zhechengqi.tollcat.R.string.dev_gallery_rows
        GalleryItemID.Cats -> com.zhechengqi.tollcat.R.string.dev_gallery_cats
        GalleryItemID.SetupGuides -> com.zhechengqi.tollcat.R.string.dev_gallery_setup
        GalleryItemID.UsageGuides -> com.zhechengqi.tollcat.R.string.settings_usage_guides
        GalleryItemID.VerifyConnection -> com.zhechengqi.tollcat.R.string.dev_gallery_verify
        GalleryItemID.CredentialFields -> com.zhechengqi.tollcat.R.string.dev_gallery_fields
        GalleryItemID.Comparison -> com.zhechengqi.tollcat.R.string.module_comparison
        GalleryItemID.Refresh -> com.zhechengqi.tollcat.R.string.action_refresh
        GalleryItemID.Tips -> com.zhechengqi.tollcat.R.string.settings_tip
        GalleryItemID.MonthRange -> com.zhechengqi.tollcat.R.string.dashboard_filter_time
    }

val GallerySection.titleRes: Int
    get() = when (this) {
        GallerySection.NewDashboard -> com.zhechengqi.tollcat.R.string.dev_gallery_new_dashboard
        GallerySection.Empty -> com.zhechengqi.tollcat.R.string.dev_gallery_empty
        GallerySection.Errors -> com.zhechengqi.tollcat.R.string.dev_gallery_errors
        GallerySection.Boundaries -> com.zhechengqi.tollcat.R.string.dev_gallery_boundaries
        GallerySection.Components -> com.zhechengqi.tollcat.R.string.dev_gallery_components
    }
