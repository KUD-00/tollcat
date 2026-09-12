package com.zhechengqi.tollcat.ui

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

@Stable
class OnboardingPreferences(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(
        AppearancePreferences.PREFS,
        Context.MODE_PRIVATE,
    )

    var completed: Boolean by mutableStateOf(read())
        private set

    private val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == null || key == KEY) {
            completed = read()
        }
    }

    init {
        prefs.registerOnSharedPreferenceChangeListener(listener)
    }

    fun complete() {
        if (completed) return
        completed = true
        prefs.edit().putBoolean(KEY, true).apply()
    }

    fun reset() {
        completed = false
        prefs.edit().putBoolean(KEY, false).apply()
    }

    fun dispose() {
        prefs.unregisterOnSharedPreferenceChangeListener(listener)
    }

    private fun read(): Boolean = prefs.getBoolean(KEY, false)

    companion object {
        const val KEY = "has_completed_onboarding"
    }
}
