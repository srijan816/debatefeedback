package com.debatefeedback.ui.timer

import android.Manifest
import android.content.pm.PackageManager
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import com.debatefeedback.LocalAppContainer
import com.debatefeedback.ui.rememberViewModel

@Composable
fun TimerScreen(
    sessionId: String,
    onViewFeedback: () -> Unit,
    onBack: () -> Unit
) {
    val container = LocalAppContainer.current
    val viewModel = rememberViewModel {
        TimerViewModel(
            sessionId = sessionId,
            debateRepository = container.debateRepository,
            uploadRepository = container.uploadRepository,
            recordingService = container.audioRecordingService(),
            timerServiceFactory = { duration -> container.timerService(duration) }
        )
    }
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            viewModel.startRecording()
        }
    }
    val hasPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    state.errorMessage?.let {
        AlertDialog(
            onDismissRequest = viewModel::dismissError,
            title = { Text("Error") },
            text = { Text(it) },
            confirmButton = {
                TextButton(onClick = viewModel::dismissError) { Text("OK") }
            }
        )
    }

    if (state.isLoading) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(16.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Text("Back") }
            Spacer(modifier = Modifier.width(8.dp))
            Text(state.session?.motion ?: "", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }

        Spacer(modifier = Modifier.height(24.dp))

        state.speakers.getOrNull(state.currentSpeakerIndex)?.let { speaker ->
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Current Speaker", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                    Text(speaker.speakerName, style = MaterialTheme.typography.headlineSmall)
                    Text(speaker.position, style = MaterialTheme.typography.bodyMedium)
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = formatTime(state.elapsedMillis),
            style = MaterialTheme.typography.displayMedium,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            Button(onClick = viewModel::previousSpeaker) { Text("Prev") }
            Button(onClick = {
                if (state.isRecording) {
                    viewModel.stopRecording()
                } else {
                    if (hasPermission) {
                        viewModel.startRecording()
                    } else {
                        permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                    }
                }
            }) {
                Text(if (state.isRecording) "Stop" else "Record")
            }
            Button(onClick = viewModel::nextSpeaker) { Text("Next") }
        }

        Spacer(modifier = Modifier.height(24.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text("Recordings", style = MaterialTheme.typography.titleMedium)
            TextButton(onClick = onViewFeedback) { Text("View Feedback") }
        }

        LazyColumn(modifier = Modifier.fillMaxWidth()) {
            items(state.recordings, key = { it.id }) { recording ->
                Card(modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp)) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(recording.speakerName, fontWeight = FontWeight.Bold)
                        Text(recording.speakerPosition, color = Color.Gray)
                        Text("Duration: ${recording.durationSeconds}s", style = MaterialTheme.typography.bodySmall)
                        Text("Status: ${recording.uploadStatus.name}", style = MaterialTheme.typography.bodySmall)
                        state.uploadProgress[recording.id]?.let { progress ->
                            Text("Uploading ${(progress * 100).toInt()}%", style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
        }
    }
}

private fun formatTime(millis: Long): String {
    val seconds = (millis / 1000).toInt()
    val minutes = seconds / 60
    val remaining = seconds % 60
    return String.format("%02d:%02d", minutes, remaining)
}
