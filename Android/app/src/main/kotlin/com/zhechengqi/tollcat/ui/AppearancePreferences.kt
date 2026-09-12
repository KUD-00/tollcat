package com.zhechengqi.tollcat.ui

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import com.zhechengqi.tollcat.settings.ColorSourcePreference

val LocalAppearancePreferences = staticCompositionLocalOf<AppearancePreferences> {
    error("LocalAppearancePreferences not provided")
}

@Stable
class AppearancePreferences(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @set:JvmName("writeMode")
    var mode: AppearanceMode by mutableStateOf(read())
        private set

    @set:JvmName("writeColorSource")
    var colorSource: String by mutableStateOf(readColorSource())
        private set

    private val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == null || key == KEY) {
            mode = read()
        }
        if (key == null || key == COLOR_SOURCE) {
            colorSource = readColorSource()
        }
    }

    init {
        prefs.registerOnSharedPreferenceChangeListener(listener)
    }

    fun setMode(value: AppearanceMode) {
        mode = value
        prefs.edit().putString(KEY, value.storageValue).apply()
    }

    fun dispose() {
        prefs.unregisterOnSharedPreferenceChangeListener(listener)
    }

    private fun read(): AppearanceMode = AppearanceMode.fromStorage(prefs.getString(KEY, null))

    private fun readColorSource(): String =
        ColorSourcePreference.normalize(prefs.getString(COLOR_SOURCE, null))

    companion object {
        const val PREFS = "tollcat.preferences"
        const val KEY = "appearance"
        const val COLOR_SOURCE = "color_source"
    }
}
