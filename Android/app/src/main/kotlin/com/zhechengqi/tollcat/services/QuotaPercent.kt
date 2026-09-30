package com.zhechengqi.tollcat.services

import kotlin.math.roundToInt

/**
 * 免费额度用掉的比例 → 整数百分比。四舍五入，和 iOS `ServiceRowBuilder`、桥上仪表盘的
 * 免费额度模块同一种取整：截断的话 34.9% 在服务页是 34，到了仪表盘就成了 35。
 */
internal fun quotaUsedPercent(ratio: Double): Int = (ratio * 100).roundToInt()
