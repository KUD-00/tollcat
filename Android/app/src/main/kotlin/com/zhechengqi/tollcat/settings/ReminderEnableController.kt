package com.zhechengqi.tollcat.settings

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.zhechengqi.tollcat.PreferencesStore

class ReminderEnableController(
    private val context: Context,
    private val preferences: PreferencesStore,
    private val requestPermission: () -> Unit,
) {
    var enabled by mutableStateOf(false)
        private set
    var presentingOptIn by mutableStateOf(false)
        private set
    var showsDenied by mutableStateOf(false)
        private set

    init {
        refresh()
    }

    fun refresh() {
        val status = ReminderAuthorization.status(context, preferences)
        showsDenied = status == ReminderAuthorization.Denied
        enabled = preferences.reminderEnabled && status.isAuthorized
        ReminderAlarmScheduler.sync(context)
    }

    fun onToggle(want: Boolean) {
        if (!want) {
            disable()
            return
        }
        val status = ReminderAuthorization.status(context, preferences)
        if (status == ReminderAuthorization.Denied) {
            enabled = false
            showsDenied = true
            return
        }
        if (status == ReminderAuthorization.NotDetermined || !preferences.reminderOptInCompleted) {
            presentingOptIn = true
            return
        }
        enableAfterGrant(granted = ReminderAuthorization.canPostNotifications(context))
    }

    fun confirmOptIn() {
        presentingOptIn = false
        preferences.reminderOptInCompleted = true
        if (Build.VERSION.SDK_INT >= 33 && !ReminderAuthorization.canPostNotifications(context)) {
            requestPermission()
            return
        }
        enableAfterGrant(granted = ReminderAuthorization.canPostNotifications(context))
    }

    fun declineOptIn() {
        presentingOptIn = false
    }

    fun onPermissionResult(granted: Boolean) {
        enableAfterGrant(granted)
    }

    fun reschedule() {
        ReminderAlarmScheduler.sync(context)
    }

    fun openSystemNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun enableAfterGrant(granted: Boolean) {
        if (!granted) {
            preferences.reminderEnabled = false
            enabled = false
            showsDenied = true
            ReminderAlarmScheduler.cancel(context)
            return
        }
        preferences.reminderEnabled = true
        enabled = true
        showsDenied = false
        ReminderAlarmScheduler.ensureChannel(context)
        ReminderAlarmScheduler.sync(context)
    }

    private fun disable() {
        preferences.reminderEnabled = false
        enabled = false
        ReminderAlarmScheduler.cancel(context)
    }
}

@Composable
fun rememberReminderEnableController(
    preferences: PreferencesStore,
): ReminderEnableController {
    val context = LocalContext.current.applicationContext
    val launchHolder = remember { PermissionLaunchHolder() }
    val controller = remember(preferences) {
        ReminderEnableController(
            context = context,
            preferences = preferences,
            requestPermission = { launchHolder.launch() },
        )
    }
    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        controller.onPermissionResult(granted)
    }
    launchHolder.launch = {
        if (Build.VERSION.SDK_INT >= 33) {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            controller.onPermissionResult(ReminderAuthorization.canPostNotifications(context))
        }
    }
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner, controller) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) controller.refresh()
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    return controller
}

private class PermissionLaunchHolder {
    var launch: () -> Unit = {}
}
