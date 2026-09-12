package com.zhechengqi.tollcat.services

import android.widget.NumberPicker
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.Switch
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import com.zhechengqi.tollcat.SubscriptionRow
import com.zhechengqi.tollcat.ui.OverflowButtonGroup
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.TollCatSheet
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.DateFormat
import java.text.DateFormatSymbols
import java.util.Calendar
import java.util.UUID
import java.util.Date
import java.util.Locale

/// 这一刻所在月的 1 号中午。结束月只认年月，落在中午避开夏令时和午夜边界。
private fun monthStart(millis: Long): Long {
    val calendar = Calendar.getInstance().apply { timeInMillis = millis }
    return Calendar.getInstance().apply {
        clear()
        set(calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), 1, 12, 0)
    }.timeInMillis
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ProviderSubscriptionSheet(
    providerId: String?,
    accountId: String?,
    editing: SubscriptionRow?,
    onDismiss: () -> Unit,
    onSave: (SubscriptionRow) -> Unit,
    /** 真删。**会改写历史**——只给「我根本录错了」用；不订了填结束月。 */
    onDelete: ((String) -> Unit)?,
) {
    var name by remember { mutableStateOf(editing?.name.orEmpty()) }
    var unitText by remember {
        mutableStateOf(editing?.let(::unitAmountText).orEmpty())
    }
    var period by remember { mutableStateOf(editing?.period ?: "monthly") }
    var quantity by remember {
        mutableIntStateOf(editing?.quantity?.coerceIn(1, 200) ?: 1)
    }
    val initialAnchor = remember {
        val calendar = Calendar.getInstance()
        if (editing != null) {
            calendar.set(editing.anchorYear, editing.anchorMonth - 1, editing.anchorDay)
        }
        calendar.timeInMillis
    }
    var anchorMillis by remember { mutableLongStateOf(initialAnchor) }
    var pickingAnchor by remember { mutableStateOf(false) }
    var pickingEnd by remember { mutableStateOf(false) }
    var confirmingDelete by remember { mutableStateOf(false) }
    // 退订那个月。null = 还在付。这是**字段**不是动作：1–3 月订过、5 月又订回来，
    // 那是两笔记录；把第一笔「恢复」会把没付钱的 4 月一起补上。
    var endMillis by remember {
        mutableStateOf(
            editing?.takeIf { it.hasEnd }?.let { row ->
                Calendar.getInstance().apply {
                    clear()
                    set(row.endYear!!, row.endMonth!! - 1, 1, 12, 0)
                }.timeInMillis
            },
        )
    }
    val nowCalendar = remember { Calendar.getInstance() }
    // 开始时间选不到未来的月份：那种订阅在账本上是纯 0，只会让人以为记错了。
    val anchorYearMax = nowCalendar.get(Calendar.YEAR)
    val anchorMonthIndexMax = nowCalendar.get(Calendar.MONTH)
    val subscriptionId = remember { editing?.id ?: UUID.randomUUID().toString() }
    val unit = parseMoney(unitText)
    val total = unit?.multiply(BigDecimal(quantity))
    val canSave = name.isNotBlank() && unit != null
    val isMonthly = period == "monthly"
    val locale = LocalConfiguration.current.locales[0]

    TollCatSheet(onDismiss = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp, vertical = 8.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = if (editing == null) {
                    stringResource(R.string.services_add_subscription)
                } else {
                    editing.name
                },
                style = MaterialTheme.typography.headlineSmall,
            )
            TextField(
                value = name,
                onValueChange = { name = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.services_name)) },
                singleLine = true,
            )
            TextField(
                value = unitText,
                onValueChange = { unitText = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.services_unit_price)) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                prefix = { Text("$") },
            )
            Text(stringResource(R.string.services_period), style = MaterialTheme.typography.titleSmall)
            val monthly = stringResource(R.string.services_subscription_monthly)
            val annual = stringResource(R.string.services_subscription_annual)
            OverflowButtonGroup(modifier = Modifier.fillMaxWidth()) {
                toggleableItem(
                    checked = period == "monthly",
                    label = monthly,
                    onCheckedChange = { checked -> if (checked) period = "monthly" },
                )
                toggleableItem(
                    checked = period == "annual",
                    label = annual,
                    onCheckedChange = { checked -> if (checked) period = "annual" },
                )
            }
            Text(
                text = stringResource(R.string.services_period_footer),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            OutlinedButton(onClick = { pickingAnchor = true }, modifier = Modifier.fillMaxWidth()) {
                val label = if (isMonthly) {
                    stringResource(R.string.services_start_time)
                } else {
                    stringResource(R.string.services_first_charge_date)
                }
                Text("$label · ${formatAnchor(anchorMillis, monthly = isMonthly, locale = locale)}")
            }
            // 结束月：填了就从下个月起不算。可以填在未来（这个月取消、用到 11 月底）。
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    stringResource(R.string.services_cancelled),
                    style = MaterialTheme.typography.titleSmall,
                )
                Switch(
                    checked = endMillis != null,
                    onCheckedChange = { on ->
                        endMillis = if (on) {
                            maxOf(monthStart(nowCalendar.timeInMillis), monthStart(anchorMillis))
                        } else {
                            null
                        }
                    },
                )
            }
            endMillis?.let { end ->
                OutlinedButton(onClick = { pickingEnd = true }, modifier = Modifier.fillMaxWidth()) {
                    Text(
                        stringResource(R.string.services_end_time) +
                            " · " + formatAnchor(end, monthly = true, locale = locale),
                    )
                }
            }
            Text(
                text = endFooter(endMillis, nowCalendar, locale),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Column {
                    Text(stringResource(R.string.services_quantity), style = MaterialTheme.typography.titleSmall)
                    Text(
                        stringResource(R.string.services_quantity_footer),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.fillMaxWidth(0.7f),
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = { if (quantity > 1) quantity -= 1 },
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(MaterialSymbol.Remove, contentDescription = null)
                    }
                    Text("×$quantity", style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"))
                    IconButton(
                        onClick = { if (quantity < 200) quantity += 1 },
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(MaterialSymbol.Add, contentDescription = null)
                    }
                }
            }
            if (total != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(stringResource(R.string.services_total), style = MaterialTheme.typography.titleMedium)
                    Text(
                        formatMoney(total.setScale(2, RoundingMode.HALF_UP).toPlainString()),
                        style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                    )
                }
            }
            PrimaryButton(
                onClick = {
                    val calendar = Calendar.getInstance().apply { timeInMillis = anchorMillis }
                    val amount = total ?: return@PrimaryButton
                    val end = endMillis?.let { millis ->
                        Calendar.getInstance().apply { timeInMillis = millis }
                    }
                    onSave(
                        SubscriptionRow(
                            id = subscriptionId,
                            name = name.trim(),
                            // 总额进 amountUsd（JNI 折算只看总额），份数单独落库给展示和再编辑。
                            amountUsd = amount.setScale(2, RoundingMode.HALF_UP).toPlainString(),
                            period = period,
                            anchorYear = calendar.get(Calendar.YEAR),
                            anchorMonth = calendar.get(Calendar.MONTH) + 1,
                            anchorDay = if (isMonthly) 1 else calendar.get(Calendar.DAY_OF_MONTH),
                            endYear = end?.get(Calendar.YEAR),
                            endMonth = end?.let { it.get(Calendar.MONTH) + 1 },
                            endDay = end?.let { 1 },
                            providerId = providerId,
                            accountId = accountId,
                            quantity = quantity,
                        ),
                    )
                },
                enabled = canSave,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.services_save))
            }
            if (editing != null && onDelete != null) {
                TextButton(
                    onClick = { confirmingDelete = true },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(
                        stringResource(R.string.services_delete_subscription),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
                Text(
                    text = stringResource(R.string.services_end_footer_set),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.height(12.dp))
        }
    }

    if (pickingAnchor) {
        if (isMonthly) {
            YearMonthPickerDialog(
                title = stringResource(R.string.services_start_time),
                initialMillis = anchorMillis,
                onConfirm = { millis ->
                    anchorMillis = millis
                    // 起点往后挪之后，结束月不能还留在开始之前。
                    endMillis?.let { end -> endMillis = maxOf(end, monthStart(millis)) }
                    pickingAnchor = false
                },
                onDismiss = { pickingAnchor = false },
                yearMax = anchorYearMax,
                monthIndexMaxInMaxYear = anchorMonthIndexMax,
            )
        } else {
            val picker = rememberDatePickerState(initialSelectedDateMillis = anchorMillis)
            DatePickerDialog(
                onDismissRequest = { pickingAnchor = false },
                confirmButton = {
                    TextButton(
                        onClick = {
                            picker.selectedDateMillis?.let { anchorMillis = it }
                            pickingAnchor = false
                        },
                    ) { Text(stringResource(R.string.services_ok)) }
                },
                dismissButton = {
                    TextButton(onClick = { pickingAnchor = false }) {
                        Text(stringResource(R.string.action_cancel))
                    }
                },
            ) {
                DatePicker(state = picker)
            }
        }
    }

    if (pickingEnd) {
        YearMonthPickerDialog(
            title = stringResource(R.string.services_end_time),
            initialMillis = endMillis ?: monthStart(anchorMillis),
            onConfirm = { millis ->
                // 结束月不能早于开始月——一段负长度的订阅没有意义。
                endMillis = maxOf(millis, monthStart(anchorMillis))
                pickingEnd = false
            },
            onDismiss = { pickingEnd = false },
            yearMin = Calendar.getInstance().apply { timeInMillis = anchorMillis }.get(Calendar.YEAR),
        )
    }

    if (confirmingDelete && editing != null && onDelete != null) {
        AlertDialog(
            onDismissRequest = { confirmingDelete = false },
            title = { Text(stringResource(R.string.services_delete_subscription_title)) },
            text = { Text(stringResource(R.string.services_delete_subscription_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete(editing.id)
                        confirmingDelete = false
                    },
                ) {
                    Text(
                        stringResource(R.string.services_delete_subscription),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmingDelete = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
}

/** 单价框展示用。落库的 amountUsd 是总额，编辑时除回来。 */
internal fun unitAmountText(row: SubscriptionRow): String {
    val total = row.amountUsd.toBigDecimalOrNull() ?: return row.amountUsd
    val qty = row.quantity.coerceAtLeast(1)
    val unit = if (qty == 1) {
        total
    } else {
        total.divide(BigDecimal(qty), 8, RoundingMode.HALF_UP)
    }
    return unit.stripTrailingZeros().toPlainString()
}

private fun parseMoney(raw: String): BigDecimal? {
    val numeric = raw.trim().replace(Regex("[^0-9.\\-]"), "")
    val value = numeric.toBigDecimalOrNull() ?: return null
    return value.takeIf { it.signum() > 0 }
}

@Composable
private fun endFooter(
    endMillis: Long?,
    now: Calendar,
    locale: Locale,
): String {
    if (endMillis == null) return stringResource(R.string.services_end_footer_open)
    val month = formatAnchor(endMillis, monthly = true, locale = locale)
    val ended = monthIndex(endMillis) < monthIndex(now.timeInMillis)
    return if (ended) {
        stringResource(R.string.services_end_footer_ended, month)
    } else {
        stringResource(R.string.services_end_footer_until, month)
    }
}

private fun monthIndex(millis: Long): Int {
    val calendar = Calendar.getInstance().apply { timeInMillis = millis }
    return calendar.get(Calendar.YEAR) * 12 + calendar.get(Calendar.MONTH)
}

private fun formatAnchor(millis: Long, monthly: Boolean, locale: Locale): String {
    val date = Date(millis)
    return if (monthly) {
        android.icu.text.DateFormat.getInstanceForSkeleton("yMMMM", locale).format(date)
    } else {
        DateFormat.getDateInstance(DateFormat.MEDIUM, locale).format(date)
    }
}

@Composable
internal fun YearMonthPickerDialog(
    title: String,
    initialMillis: Long,
    onConfirm: (Long) -> Unit,
    onDismiss: () -> Unit,
    yearMin: Int? = null,
    yearMax: Int? = null,
    /// 最大年份里最多能选到第几个月（0 起）。开始时间靠它挡住「今年剩下的月份」。
    monthIndexMaxInMaxYear: Int? = null,
) {
    val locale = LocalConfiguration.current.locales[0]
    val initial = remember(initialMillis) {
        Calendar.getInstance().apply { timeInMillis = initialMillis }
    }
    var year by remember { mutableIntStateOf(initial.get(Calendar.YEAR)) }
    var monthIndex by remember { mutableIntStateOf(initial.get(Calendar.MONTH)) }
    val months = remember(locale) {
        DateFormatSymbols.getInstance(locale).months.take(12).toTypedArray()
    }
    val resolvedYearMin = minOf(yearMin ?: (initial.get(Calendar.YEAR) - 20), initial.get(Calendar.YEAR))
    val resolvedYearMax = maxOf(yearMax ?: (initial.get(Calendar.YEAR) + 5), initial.get(Calendar.YEAR))
    val monthIndexMax = if (monthIndexMaxInMaxYear != null && year >= resolvedYearMax) {
        monthIndexMaxInMaxYear
    } else {
        11
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                AndroidView(
                    factory = { context ->
                        NumberPicker(context).apply {
                            wrapSelectorWheel = false
                            setOnValueChangedListener { _, _, newVal ->
                                year = newVal
                                // 换到上界那一年时，超出的月份要跟着收回来。
                                if (monthIndexMaxInMaxYear != null &&
                                    newVal >= resolvedYearMax &&
                                    monthIndex > monthIndexMaxInMaxYear
                                ) {
                                    monthIndex = monthIndexMaxInMaxYear
                                }
                            }
                        }
                    },
                    update = { picker ->
                        picker.minValue = resolvedYearMin
                        picker.maxValue = resolvedYearMax
                        picker.value = year
                    },
                    modifier = Modifier.weight(1f),
                )
                AndroidView(
                    factory = { context ->
                        NumberPicker(context).apply {
                            wrapSelectorWheel = false
                            setOnValueChangedListener { _, _, newVal -> monthIndex = newVal }
                        }
                    },
                    // 上界随年份变，所以只能在 update 里设——factory 只跑一次。
                    update = { picker ->
                        picker.displayedValues = null
                        picker.minValue = 0
                        picker.maxValue = monthIndexMax
                        picker.displayedValues = months.copyOfRange(0, monthIndexMax + 1)
                        picker.value = monthIndex.coerceAtMost(monthIndexMax)
                    },
                    modifier = Modifier.weight(1f),
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val calendar = Calendar.getInstance().apply {
                        clear()
                        set(year, monthIndex, 1, 12, 0, 0)
                    }
                    onConfirm(calendar.timeInMillis)
                },
            ) { Text(stringResource(R.string.services_ok)) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.action_cancel))
            }
        },
    )
}
