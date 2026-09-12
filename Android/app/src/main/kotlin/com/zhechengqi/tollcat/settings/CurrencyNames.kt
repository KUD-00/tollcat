package com.zhechengqi.tollcat.settings

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.R

@Composable
fun currencyLabel(code: String): String {
    val name = when (code) {
        "USD" -> stringResource(R.string.settings_currency_usd)
        "CNY" -> stringResource(R.string.settings_currency_cny)
        "EUR" -> stringResource(R.string.settings_currency_eur)
        "GBP" -> stringResource(R.string.settings_currency_gbp)
        "JPY" -> stringResource(R.string.settings_currency_jpy)
        "AUD" -> stringResource(R.string.settings_currency_aud)
        "CAD" -> stringResource(R.string.settings_currency_cad)
        "SGD" -> stringResource(R.string.settings_currency_sgd)
        "INR" -> stringResource(R.string.settings_currency_inr)
        "BRL" -> stringResource(R.string.settings_currency_brl)
        "KRW" -> stringResource(R.string.settings_currency_krw)
        "TWD" -> stringResource(R.string.settings_currency_twd)
        "HKD" -> stringResource(R.string.settings_currency_hkd)
        else -> null
    }
    return if (name == null) code else stringResource(R.string.settings_currency_label, name, code)
}
