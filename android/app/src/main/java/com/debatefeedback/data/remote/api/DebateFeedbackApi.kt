package com.debatefeedback.data.remote.api

import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Multipart
import retrofit2.http.POST
import retrofit2.http.Part
import retrofit2.http.PartMap
import retrofit2.http.Path
import retrofit2.http.Query

interface DebateFeedbackApi {
    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): LoginResponse

    @GET("schedule/current")
    suspend fun getCurrentSchedule(
        @Query("teacher_id") teacherId: String,
        @Query("timestamp") timestamp: String,
        @Query("class_id") classId: String? = null
    ): ScheduleResponse

    @POST("debates/create")
    suspend fun createDebate(@Body request: CreateDebateRequest): CreateDebateResponse

    @Multipart
    @POST("debates/{debateId}/speeches")
    suspend fun uploadSpeech(
        @Path("debateId") debateId: String,
        @Part filePart: MultipartBody.Part,
        @PartMap metadata: Map<String, @JvmSuppressWildcards RequestBody>
    ): UploadResponse

    @GET("speeches/{speechId}/status")
    suspend fun getSpeechStatus(@Path("speechId") speechId: String): SpeechStatusResponse

    @GET("speeches/{speechId}/feedback")
    suspend fun getFeedbackContent(@Path("speechId") speechId: String): FeedbackContentResponse

    @GET("teachers/{teacherId}/debates")
    suspend fun getDebateHistory(
        @Path("teacherId") teacherId: String,
        @Query("limit") limit: Int = 25
    ): DebateHistoryResponse
}
