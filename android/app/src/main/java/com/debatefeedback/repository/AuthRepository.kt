package com.debatefeedback.repository

import com.debatefeedback.SessionManager
import com.debatefeedback.core.Constants
import com.debatefeedback.data.local.DebateFeedbackDao
import com.debatefeedback.data.remote.api.DebateFeedbackApi
import com.debatefeedback.data.remote.api.LoginRequest
import com.debatefeedback.domain.model.Teacher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.UUID

class AuthRepository(
    private val api: DebateFeedbackApi,
    private val dao: DebateFeedbackDao,
    private val sessionManager: SessionManager
) {

    suspend fun loginTeacher(name: String): Teacher = withContext(Dispatchers.IO) {
        val deviceId = sessionManager.ensureDeviceId()
        val response = api.login(LoginRequest(teacherId = name, deviceId = deviceId))
        val teacher = Teacher(
            id = response.teacher.id.ifBlank { UUID.randomUUID().toString() },
            name = response.teacher.name,
            deviceId = deviceId,
            authToken = response.token,
            isAdmin = response.teacher.isAdmin
        )
        dao.upsertTeacher(teacher)
        sessionManager.updateAuth(response.token, teacher.id, false)
        teacher
    }

    suspend fun loginGuest() = withContext(Dispatchers.IO) {
        sessionManager.updateAuth(token = null, teacherId = null, guestMode = true)
    }

    suspend fun logout() = withContext(Dispatchers.IO) {
        sessionManager.clearAuth()
        dao.clearTeachers()
    }

    suspend fun currentTeacher(): Teacher? = sessionManager.teacherId.value?.let { dao.getTeacher(it) }

    suspend fun ensureDeviceId(): String = sessionManager.ensureDeviceId()
}
