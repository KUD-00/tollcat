package com.zhechengqi.tollcat.developer

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.developer.gallery.GalleryAmountStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryAttentionStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryCatStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryChartStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryComparisonStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryCompositionStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryCredentialFieldsView
import com.zhechengqi.tollcat.developer.gallery.GalleryEmptyStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryErrorStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryGlyphStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryMonthRangeView
import com.zhechengqi.tollcat.developer.gallery.GalleryOverflowStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryRefreshView
import com.zhechengqi.tollcat.developer.gallery.GalleryRowStatesView
import com.zhechengqi.tollcat.developer.gallery.GallerySetupGuidesView
import com.zhechengqi.tollcat.developer.gallery.GalleryTipStatesView
import com.zhechengqi.tollcat.developer.gallery.GalleryUsageGuidesView
import com.zhechengqi.tollcat.developer.gallery.GalleryVerifyConnectionView

@Composable
fun GalleryItemDestination(
    id: String,
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    when (GalleryItemID.fromRaw(id)) {
        GalleryItemID.Empty -> GalleryEmptyStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Errors -> GalleryErrorStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Amounts -> GalleryAmountStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Composition -> GalleryCompositionStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Charts -> GalleryChartStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Attention -> GalleryAttentionStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Overflow -> GalleryOverflowStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Glyphs -> GalleryGlyphStatesView(
            session = session,
            onBack = onBack,
            modifier = modifier,
        )
        GalleryItemID.Rows -> GalleryRowStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Cats -> GalleryCatStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.SetupGuides -> GallerySetupGuidesView(
            session = session,
            onBack = onBack,
            modifier = modifier,
        )
        GalleryItemID.UsageGuides -> GalleryUsageGuidesView(
            preferences = session.preferences,
            onBack = onBack,
            modifier = modifier,
        )
        GalleryItemID.VerifyConnection -> GalleryVerifyConnectionView(onBack = onBack, modifier = modifier)
        GalleryItemID.CredentialFields -> GalleryCredentialFieldsView(onBack = onBack, modifier = modifier)
        GalleryItemID.Comparison -> GalleryComparisonStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.Refresh -> GalleryRefreshView(onBack = onBack, modifier = modifier)
        GalleryItemID.Tips -> GalleryTipStatesView(onBack = onBack, modifier = modifier)
        GalleryItemID.MonthRange -> GalleryMonthRangeView(onBack = onBack, modifier = modifier)
        null -> GalleryEmptyStatesView(onBack = onBack, modifier = modifier)
    }
}
