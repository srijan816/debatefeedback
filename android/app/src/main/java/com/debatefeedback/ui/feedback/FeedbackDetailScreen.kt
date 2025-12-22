package com.debatefeedback.ui.feedback

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.debatefeedback.LocalAppContainer
import com.debatefeedback.ui.rememberViewModel

@Composable
fun FeedbackDetailScreen(
    sessionId: String,
    recordingId: String,
    onBack: () -> Unit
) {
    val container = LocalAppContainer.current
    val viewModel = rememberViewModel { FeedbackDetailViewModel(sessionId, recordingId, container.debateRepository) }
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current

    state.errorMessage?.let {
        AlertDialog(
            onDismissRequest = viewModel::dismissError,
            title = { Text("Error") },
            text = { Text(it) },
            confirmButton = { TextButton(onClick = viewModel::dismissError) { Text("OK") } }
        )
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        TextButton(onClick = onBack) { Text("Back") }
        Spacer(modifier = Modifier.height(8.dp))

        val recording = state.recording
        if (recording == null) {
            CircularProgressIndicator()
            return@Column
        }

        Text(recording.speakerName, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(recording.speakerPosition, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.secondary)
        Spacer(modifier = Modifier.height(16.dp))

        recording.feedbackUrl?.let { url ->
            Button(onClick = {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                context.startActivity(intent)
            }) { Text("Open Google Doc") }
            Spacer(modifier = Modifier.height(16.dp))
        }

        Text("Highlights", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))
        if (state.feedbackContent != null) {
            Text(state.feedbackContent!!, modifier = Modifier.fillMaxWidth())
        } else {
            Text("Feedback is still processing. Please check back soon.")
        }
    }
}
