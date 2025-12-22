package com.debatefeedback

import android.content.Context
import com.debatefeedback.core.Constants
import com.debatefeedback.data.local.DebateFeedbackDatabase
import com.debatefeedback.data.preferences.PreferenceStore
import com.debatefeedback.data.remote.api.DebateFeedbackApi
import com.debatefeedback.network.AuthInterceptor
import com.debatefeedback.repository.AuthRepository
import com.debatefeedback.repository.DebateRepository
import com.debatefeedback.repository.UploadRepository
import com.debatefeedback.services.AudioPlaybackService
import com.debatefeedback.services.AudioRecordingService
import com.debatefeedback.services.TimerService
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit

class AppContainer(context: Context) {
    private val appContext = context.applicationContext
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private val preferenceStore = PreferenceStore(appContext)
    val sessionManager = SessionManager(preferenceStore)

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(Constants.API.REQUEST_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(Constants.API.UPLOAD_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(Constants.API.UPLOAD_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .addInterceptor(AuthInterceptor(sessionManager))
        .addInterceptor(loggingInterceptor)
        .build()

    private val retrofit: Retrofit = Retrofit.Builder()
        .baseUrl(Constants.API.BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()

    private val database = DebateFeedbackDatabase.build(appContext)
    private val api: DebateFeedbackApi = retrofit.create(DebateFeedbackApi::class.java)

    val authRepository = AuthRepository(api, database.debateDao(), sessionManager)
    val debateRepository = DebateRepository(api, database.debateDao(), sessionManager)
    val uploadRepository = UploadRepository(api, sessionManager)

    fun audioRecordingService(): AudioRecordingService = AudioRecordingService(appContext)
    fun audioPlaybackService(): AudioPlaybackService = AudioPlaybackService(appContext)
    fun timerService(durationSeconds: Int): TimerService = TimerService(durationSeconds)
}
