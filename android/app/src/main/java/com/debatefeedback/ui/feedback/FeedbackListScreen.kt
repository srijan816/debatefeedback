package com.debatefeedback.ui.feedback

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.debatefeedback.LocalAppContainer
import com.debatefeedback.ui.rememberViewModel

@Composable
fun FeedbackListScreen(
    sessionId: String,
    onBack: () -> Unit,
    onOpenRecording: (String) -> Unit,
    onDone: () -> Unit
) {
    val container = LocalAppContainer.current
    val viewModel = rememberViewModel { FeedbackListViewModel(sessionId, container.debateRepository) }
    val state by viewModel.state.collectAsState()

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Text("Back") }
            Text("Feedback", style = MaterialTheme.typography.titleLarge)
            TextButton(onClick = onDone) { Text("Done") }
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (state.isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
            return@Column
        }

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(state.recordings, key = { it.id }) { recording ->
                Card(modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(recording.speakerName, fontWeight = FontWeight.Bold)
                        Text(recording.speakerPosition, color = MaterialTheme.colorScheme.secondary)
                        Text("Status: ${recording.feedbackStatus.name}")
                        Spacer(modifier = Modifier.height(8.dp))
                        Button(onClick = { onOpenRecording(recording.id) }, enabled = recording.feedbackStatus == com.debatefeedback.domain.model.ProcessingStatus.COMPLETE) {
                            Text(if (recording.feedbackStatus == com.debatefeedback.domain.model.ProcessingStatus.COMPLETE) "View Feedback" else "Processing")
                        }
                    }
                }
            }
        }
    }
}
