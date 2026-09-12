package com.zhechengqi.tollcat.setup

enum class SetupWizardStep {
    Guide,
    Credentials,
    ;

    val displayNumber: Int get() = ordinal + 1

    companion object {
        const val TOTAL = 2
    }
}
