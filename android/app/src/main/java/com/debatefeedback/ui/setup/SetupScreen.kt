package com.debatefeedback.ui.setup

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.debatefeedback.LocalAppContainer
import com.debatefeedback.core.Constants
import com.debatefeedback.domain.model.DebateFormat
import com.debatefeedback.domain.model.StudentLevel
import com.debatefeedback.ui.rememberViewModel
import kotlinx.coroutines.launch

@Composable
fun SetupScreen(
    onStartTimer: (String) -> Unit,
    onViewHistory: () -> Unit,
    onLogout: () -> Unit
) {
    val container = LocalAppContainer.current
    val viewModel = rememberViewModel { SetupViewModel(container.debateRepository) }
    val state by viewModel.state.collectAsState()
    val scope = rememberCoroutineScope()

    state.errorMessage?.let { message ->
        AlertDialog(
            onDismissRequest = viewModel::dismissError,
            title = { Text("Error") },
            text = { Text(message) },
            confirmButton = {
                TextButton(onClick = viewModel::dismissError) { Text("OK") }
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(20.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = {
                scope.launch {
                    container.authRepository.logout()
                    onLogout()
                }
            }) {
                Text("Logout")
            }
            Text("Setup Debate", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            TextButton(onClick = onViewHistory) {
                Text("History")
            }
        }

        StepIndicator(currentStep = state.currentStep)

        Spacer(modifier = Modifier.height(16.dp))

        when (state.currentStep) {
            SetupStep.BASIC_INFO -> BasicInfoStep(state, viewModel)
            SetupStep.STUDENTS -> StudentsStep(state, viewModel)
            SetupStep.TEAMS -> TeamAssignmentStep(state, viewModel)
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            if (state.currentStep != SetupStep.BASIC_INFO) {
                OutlinedButton(onClick = { viewModel.navigateTo(previousStep(state.currentStep)) }) {
                    Text("Back")
                }
            } else {
                Spacer(modifier = Modifier)
            }

            Button(
                onClick = {
                    if (state.currentStep != SetupStep.TEAMS) {
                        viewModel.navigateTo(nextStep(state.currentStep))
                    } else {
                        viewModel.createDebate(onStartTimer)
                    }
                },
                enabled = !state.isCreating
            ) {
                Text(if (state.currentStep == SetupStep.TEAMS) "Start Timer" else "Next")
            }
        }
    }
}

private fun previousStep(step: SetupStep): SetupStep = when (step) {
    SetupStep.BASIC_INFO -> SetupStep.BASIC_INFO
    SetupStep.STUDENTS -> SetupStep.BASIC_INFO
    SetupStep.TEAMS -> SetupStep.STUDENTS
}

private fun nextStep(step: SetupStep): SetupStep = when (step) {
    SetupStep.BASIC_INFO -> SetupStep.STUDENTS
    SetupStep.STUDENTS -> SetupStep.TEAMS
    SetupStep.TEAMS -> SetupStep.TEAMS
}

@Composable
private fun StepIndicator(currentStep: SetupStep) {
    val steps = listOf("Basics" to SetupStep.BASIC_INFO, "Students" to SetupStep.STUDENTS, "Teams" to SetupStep.TEAMS)
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
        steps.forEach { (label, step) ->
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                val isActive = currentStep == step
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .background(
                            color = if (isActive) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text((steps.indexOfFirst { it.second == step } + 1).toString(), color = if (isActive) Color.White else MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(label, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun BasicInfoStep(state: SetupUiState, viewModel: SetupViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        OutlinedTextField(
            value = state.motion,
            onValueChange = viewModel::updateMotion,
            label = { Text("Motion") },
            modifier = Modifier.fillMaxWidth(),
            supportingText = { Text("${state.motion.length}/${Constants.Validation.MOTION_MAX}") }
        )

        Text("Format", style = MaterialTheme.typography.titleMedium)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            DebateFormat.entries.forEach { format ->
                FilterChip(
                    selected = state.format == format,
                    onClick = { viewModel.selectFormat(format) },
                    label = { Text(format.displayName) }
                )
            }
        }

        Text("Student Level", style = MaterialTheme.typography.titleMedium)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            StudentLevel.entries.forEach { level ->
                FilterChip(
                    selected = state.studentLevel == level,
                    onClick = { viewModel.selectLevel(level) },
                    label = { Text(level.displayName) }
                )
            }
        }

        OutlinedTextField(
            value = state.speechTimeSeconds.toString(),
            onValueChange = { value -> value.toIntOrNull()?.let(viewModel::updateSpeechTime) },
            label = { Text("Speech Time (seconds)") },
            modifier = Modifier.fillMaxWidth()
        )

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = state.includeReplySpeeches,
                onClick = { viewModel.updateReplyEnabled(!state.includeReplySpeeches) },
                label = { Text("Include reply speeches") }
            )
            if (state.includeReplySpeeches) {
                OutlinedTextField(
                    value = state.replyTimeSeconds?.toString() ?: "",
                    onValueChange = { value -> value.toIntOrNull()?.let(viewModel::updateReplyTime) },
                    label = { Text("Reply Time (seconds)") },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun StudentsStep(state: SetupUiState, viewModel: SetupViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        OutlinedTextField(
            value = state.newStudentName,
            onValueChange = viewModel::updateNewStudentName,
            placeholder = { Text("Add student name") },
            modifier = Modifier.fillMaxWidth()
        )
        Button(
            onClick = { viewModel.addStudent(state.newStudentName) },
            enabled = state.newStudentName.length >= Constants.Validation.SPEAKER_MIN
        ) {
            Text("Add Student")
        }

        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(state.studentEntries, key = { it.student.id }) { entry ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(entry.student.name, fontWeight = FontWeight.SemiBold)
                            Text(entry.group?.displayName ?: "Unassigned", style = MaterialTheme.typography.bodySmall)
                        }
                        TextButton(onClick = { viewModel.removeStudent(entry.student.id) }) {
                            Text("Remove")
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TeamAssignmentStep(state: SetupUiState, viewModel: SetupViewModel) {
    val options = TeamGroup.optionsFor(state.format)
    LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        items(state.studentEntries, key = { it.student.id }) { entry ->
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(entry.student.name, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        options.forEach { option ->
                            FilterChip(
                                selected = entry.group == option,
                                onClick = { viewModel.assignStudent(entry.student.id, if (entry.group == option) null else option) },
                                label = { Text(option.displayName) }
                            )
                        }
                    }
                }
            }
        }
    }
}
