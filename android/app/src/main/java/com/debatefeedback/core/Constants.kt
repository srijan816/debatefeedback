package com.debatefeedback.core

import androidx.compose.ui.graphics.Color

/**
 * Mirrors the shared constants from the iOS implementation so behaviour stays aligned.
 */
object Constants {

    object API {
        // Retrofit requires trailing slash to join relative paths safely.
        const val BASE_URL = "http://45.128.222.229.22:3000/api/"
        const val REQUEST_TIMEOUT_SECONDS = 30L
        const val UPLOAD_TIMEOUT_SECONDS = 120L
        const val MAX_RETRY = 3
        const val FEEDBACK_POLL_SECONDS = 5L
        var useMockData: Boolean = false
    }

    object Audio {
        const val FILE_EXTENSION = "m4a"
        const val SAMPLE_RATE = 44_100
        const val BIT_RATE = 128_000
        const val CHANNELS = 1
        const val FIRST_BELL = 60.0
        const val OVERTIME_BELL_INTERVAL = 15.0
        const val MINIMUM_RECORDING_SECONDS = 1
    }

    object Timer {
        const val DISPLAY_REFRESH_FPS = 60
        const val ACCURACY_TOLERANCE = 0.1
    }

    object UserPrefs {
        const val DEVICE_ID = "com.debatefeedback.deviceId"
        const val AUTH_TOKEN = "com.debatefeedback.authToken"
        const val CURRENT_TEACHER_ID = "com.debatefeedback.teacherId"
        const val IS_GUEST = "com.debatefeedback.isGuestMode"
        const val THEME = "com.debatefeedback.themePreference"
    }

    object Files {
        const val AUDIO_DIRECTORY = "recordings"
        const val MAX_LOCAL_DAYS = 7
    }

    object Validation {
        const val MOTION_MIN = 5
        const val MOTION_MAX = 200
        const val SPEAKER_MIN = 2
        const val SPEAKER_MAX = 50
        const val SPEECH_TIME_MIN = 60
        const val SPEECH_TIME_MAX = 900
    }

    object ErrorMessages {
        const val NETWORK_UNAVAILABLE = "No internet connection. Please check your network settings."
        const val UPLOAD_FAILED = "Failed to upload recording. Tap to retry."
        const val MICROPHONE_DENIED = "Microphone access is required. Please enable it in Settings."
        const val RECORDING_FAILED = "Failed to start recording. Please try again."
        const val INVALID_MOTION = "Please enter a valid motion (5-200 characters)."
        const val NO_STUDENTS = "Please add at least one student to each team."
        const val INCOMPLETE_TEAMS = "Please assign all students to teams."
    }

    enum class ThemeOption(val displayName: String) {
        LIGHT("Light"),
        DARK("Dark"),
        SYSTEM("System");

        companion object {
            fun fromRaw(raw: String?): ThemeOption = entries.firstOrNull { it.name == raw }
                ?: SYSTEM
        }
    }

    object Palette {
        // Light mode
        val LightBackgroundPrimary = Color(0xFFFFFFFF)
        val LightBackgroundSecondary = Color(0xFFFAFAFE)
        val LightBackgroundTertiary = Color(0xFFF2F4F9)
        val LightCardBackground = Color(0xFFFFFFFF)

        // Dark mode
        val DarkBackgroundPrimary = Color(0xFF1C1C1F)
        val DarkBackgroundSecondary = Color(0xFF28282E)
        val DarkBackgroundTertiary = Color(0xFF333338)
        val DarkCardBackground = Color(0xFF28282E)

        // Mascot palette
        val MascotNavy = Color(0xFF1E3A5F)
        val MascotPink = Color(0xFFF72585)
        val MascotLightBlue = Color(0xFFDCEAFF)
        val SoftMint = Color(0xFF80E6BF)
        val SoftCyan = Color(0xFF73CCF2)
        val SoftPurple = Color(0xFFBFA6F2)
        val PrimaryBlue = Color(0xFF3385F2)
        val PrimaryBlueDark = Color(0xFF2668E0)
    }
}
