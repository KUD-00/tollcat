package com.zhechengqi.tollcat.ui

/**
 * 状态条的语气。颜色走 M3 角色，不自造橙 / 警告色——
 * tertiary 在这套品牌里是青，拿去当警告会和品牌撞车。
 */
enum class StatusTone {
    /** 凭据错了、保存失败、测不通。 */
    Error,

    /** 权限不够、空读数、数据陈旧。能接着处理，不是当场废了。 */
    Caution,

    /** 网络、环境提示。不是凭据的问题。 */
    Neutral,

    /** 测连接成功。 */
    Success,
}
