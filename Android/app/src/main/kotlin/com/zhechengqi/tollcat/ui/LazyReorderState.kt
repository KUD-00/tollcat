package com.zhechengqi.tollcat.ui

import androidx.compose.foundation.lazy.LazyListItemInfo
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue

/**
 * LazyColumn 里的拖动排序。Compose 和 M3 都没有现成的可排序列表（foundation 的
 * `draganddrop` 是跨应用拖放，material3 的 `DragHandle` 是拖分栏宽度的），不引第三方库，就自己写这一小块。
 *
 * 做法：被拖的那一行记住「开始时画在哪 + 手指挪了多少」，这就是它此刻该出现的位置；
 * 布局位置每换一次序就跳到新格子，[translationFor] 用两者的差把它钉在手指底下。
 * 它的中线越进另一行的范围就换序，其余行靠 `Modifier.animateItem()` 平滑让位。
 *
 * [canMoveTo]：哪些 key 能被换过去（定槽的、别的分区的不行）。
 * [onMove]：把 from 挪到 to 的位置。只改界面上的顺序；落手时再由调用方落盘。
 */
@Stable
class LazyReorderState internal constructor(
    private val listState: LazyListState,
    private val canMoveTo: (Any) -> Boolean,
    private val onMove: (from: Any, to: Any) -> Unit,
) {
    var draggingKey by mutableStateOf<Any?>(null)
        private set

    private var startTop = 0f
    private var travel by mutableFloatStateOf(0f)

    /** 刚换过序、布局还没跟上时，等它落到这个 index 再判下一次——不然同一帧会换回去。 */
    private var awaitingIndex: Int? = null

    fun start(key: Any): Boolean {
        val info = item(key) ?: return false
        draggingKey = key
        startTop = info.offset.toFloat()
        travel = 0f
        awaitingIndex = null
        return true
    }

    /** 挪了 [dy]；换了序返回 true（调用方据此轻震一下）。 */
    fun dragBy(dy: Float): Boolean {
        val key = draggingKey ?: return false
        travel += dy
        val info = item(key) ?: return false
        awaitingIndex?.let { expected ->
            if (info.index != expected) return false
            awaitingIndex = null
        }
        val center = startTop + travel + info.size / 2f
        val target = listState.layoutInfo.visibleItemsInfo.firstOrNull {
            it.key != key && canMoveTo(it.key) && center >= it.offset && center < it.offset + it.size
        } ?: return false
        awaitingIndex = target.index
        onMove(key, target.key)
        return true
    }

    fun end() {
        draggingKey = null
        travel = 0f
        awaitingIndex = null
    }

    /** 被拖那一行此刻相对自己布局位置的位移。别的行恒为 0。 */
    fun translationFor(key: Any): Float {
        if (key != draggingKey) return 0f
        val info = item(key) ?: return 0f
        return startTop + travel - info.offset
    }

    private fun item(key: Any): LazyListItemInfo? =
        listState.layoutInfo.visibleItemsInfo.firstOrNull { it.key == key }
}

@Composable
fun rememberLazyReorderState(
    listState: LazyListState,
    canMoveTo: (Any) -> Boolean,
    onMove: (from: Any, to: Any) -> Unit,
): LazyReorderState {
    val latestCanMove = rememberUpdatedState(canMoveTo)
    val latestOnMove = rememberUpdatedState(onMove)
    return remember(listState) {
        LazyReorderState(
            listState = listState,
            canMoveTo = { latestCanMove.value(it) },
            onMove = { from, to -> latestOnMove.value(from, to) },
        )
    }
}
