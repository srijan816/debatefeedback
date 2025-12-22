package com.debatefeedback.data.preferences

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.debatefeedback.core.Constants
import com.debatefeedback.core.Constants.ThemeOption
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.util.UUID

private val Context.dataStore by preferencesDataStore(name = "debate_prefs")

class PreferenceStore(private val context: Context) {

    private object Keys {
        val deviceId = stringPreferencesKey(Constants.UserPrefs.DEVICE_ID)
        val authToken = stringPreferencesKey(Constants.UserPrefs.AUTH_TOKEN)
        val teacherId = stringPreferencesKey(Constants.UserPrefs.CURRENT_TEACHER_ID)
        val isGuest = booleanPreferencesKey(Constants.UserPrefs.IS_GUEST)
        val theme = stringPreferencesKey(Constants.UserPrefs.THEME)
    }

    val authToken: Flow<String?> = context.dataStore.data.map { it[Keys.authToken] }

    val teacherId: Flow<String?> = context.dataStore.data.map { it[Keys.teacherId] }

    val isGuestMode: Flow<Boolean> = context.dataStore.data.map { it[Keys.isGuest] ?: false }

    val theme: Flow<ThemeOption> = context.dataStore.data.map { prefs ->
        ThemeOption.fromRaw(prefs[Keys.theme])
    }

    suspend fun setAuthToken(token: String?) {
        context.dataStore.edit { prefs ->
            if (token == null) prefs.remove(Keys.authToken) else prefs[Keys.authToken] = token
        }
    }

    suspend fun setTeacherId(id: String?) {
        context.dataStore.edit { prefs ->
            if (id == null) prefs.remove(Keys.teacherId) else prefs[Keys.teacherId] = id
        }
    }

    suspend fun setGuestMode(isGuest: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[Keys.isGuest] = isGuest
        }
    }

    suspend fun setTheme(theme: ThemeOption) {
        context.dataStore.edit { prefs ->
            prefs[Keys.theme] = theme.name
        }
    }

    suspend fun getOrCreateDeviceId(): String {
        val existing = context.dataStore.data.map { it[Keys.deviceId] }.first()
        if (existing != null) return existing
        val generated = UUID.randomUUID().toString()
        context.dataStore.edit { prefs ->
            prefs[Keys.deviceId] = generated
        }
        return generated
    }

    suspend fun clearAuth() {
        context.dataStore.edit { prefs ->
            prefs.remove(Keys.authToken)
            prefs.remove(Keys.teacherId)
            prefs.remove(Keys.isGuest)
        }
    }
}
