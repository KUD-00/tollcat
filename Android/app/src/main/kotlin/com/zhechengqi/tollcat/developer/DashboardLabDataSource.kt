package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.R

/** 实验室里模块吃哪份数。当前账本可能缺某一块；设计稿永远有。 */
enum class DashboardLabDataSource {
    Live,
    Fixture,
    ;

    val titleRes: Int
        get() = when (this) {
            Live -> R.string.dev_lab_live
            Fixture -> R.string.dev_lab_fixture
        }
}
