package com.zhechengqi.tollcat.setup

import com.zhechengqi.tollcat.GuideErrorCase

sealed class SetupVerifyOutcome {
    data class Success(val title: String, val detail: String?) : SetupVerifyOutcome()
    data object EmptyReading : SetupVerifyOutcome()
    data class Http(val errorCase: GuideErrorCase) : SetupVerifyOutcome()
    data object Network : SetupVerifyOutcome()
    data object Unknown : SetupVerifyOutcome()

    val isSuccess: Boolean get() = this is Success

    /** 401 / 403 / 空读数需要回教程改权限；断网只是等一会儿再试。 */
    val offersRevisePermissions: Boolean
        get() = when (this) {
            EmptyReading -> true
            is Http -> errorCase.httpStatus == 401 || errorCase.httpStatus == 403
            else -> false
        }
}
