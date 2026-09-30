package com.zhechengqi.tollcat.ui

import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetValue
import androidx.compose.material3.rememberBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId

/**
 * 系统 ModalBottomSheet。弹簧走主题里的 [androidx.compose.material3.MotionScheme]。
 * 从 Hidden 弹到 Expanded，不要自己再包一层 slide，会叠两次。
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class, ExperimentalComposeUiApi::class)
@Composable
fun TollCatSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    // 不要半展开那一档：内容够高时系统默认有它，返回键落在那一档上什么也不做，
    // 要按第二下才关。我们总是直接弹到全展开，半截只会是手指拖出来的，留着只添乱。
    val state = rememberBottomSheetState(SheetValue.Hidden, setOf(SheetValue.Hidden, SheetValue.Expanded))
    LaunchedEffect(Unit) { state.expand() }
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        // 弹出面是另一个窗口、另一棵 Compose 树，TollCatApp 根上开的
        // testTagsAsResourceId 到不了这里；不开的话面板里的 testTag 对 Maestro 不可见。
        modifier = modifier.semantics { testTagsAsResourceId = true },
        sheetState = state,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        content = content,
    )
}
