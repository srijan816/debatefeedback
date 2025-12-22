package com.debatefeedback

import com.debatefeedback.core.Constants
import com.debatefeedback.core.Constants.ThemeOption
import com.debatefeedback.data.preferences.PreferenceStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class SessionManager(private val preferenceStore: PreferenceStore) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    val authToken: StateFlow<String?> = preferenceStore.authToken.stateIn(
        scope,
        SharingStarted.Eagerly,
        null
    )

    val teacherId: StateFlow<String?> = preferenceStore.teacherId.stateIn(
        scope,
        SharingStarted.Eagerly,
        null
    )

    val isGuestMode: StateFlow<Boolean> = preferenceStore.isGuestMode.stateIn(
        scope,
        SharingStarted.Eagerly,
        false
    )

    val theme: StateFlow<ThemeOption> = preferenceStore.theme.stateIn(
        scope,
        SharingStarted.Eagerly,
        ThemeOption.SYSTEM
    )

    suspend fun ensureDeviceId(): String = preferenceStore.getOrCreateDeviceId()

    suspend fun updateAuth(token: String?, teacherId: String?, guestMode: Boolean) {
        preferenceStore.setAuthToken(token)
        preferenceStore.setTeacherId(teacherId)
        preferenceStore.setGuestMode(guestMode)
    }

    suspend fun clearAuth() {
        preferenceStore.clearAuth()
    }

    suspend fun setTheme(theme: ThemeOption) {
        preferenceStore.setTheme(theme)
    }

    suspend fun currentDeviceId(): String = preferenceStore.getOrCreateDeviceId()

    suspend fun currentToken(): String? = authToken.first()
}
