package com.debatefeedback.ui.auth

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.debatefeedback.LocalAppContainer
import com.debatefeedback.R
import com.debatefeedback.ui.rememberViewModel

@Composable
fun AuthScreen(onAuthenticated: () -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = rememberViewModel { AuthViewModel(container.authRepository) }
    val state by viewModel.state.collectAsState()

    LaunchedEffect(state.isAuthenticated) {
        if (state.isAuthenticated) onAuthenticated()
    }

    if (state.errorMessage != null) {
        AlertDialog(
            onDismissRequest = viewModel::dismissError,
            title = { Text("Error") },
            text = { Text(state.errorMessage ?: "") },
            confirmButton = {
                Button(onClick = viewModel::dismissError) {
                    Text("OK")
                }
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 24.dp, vertical = 32.dp),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Image(
                painter = painterResource(id = R.drawable.mascot),
                contentDescription = "Mascot",
                modifier = Modifier
                    .size(220.dp)
                    .clip(RoundedCornerShape(110.dp)),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.height(24.dp))
            Text("DebateMate", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Text("Intelligent feedback for modern debate", style = MaterialTheme.typography.bodyMedium)
        }

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            TextField(
                value = state.teacherName,
                onValueChange = viewModel::onNameChanged,
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Teacher Name") },
                singleLine = true,
                enabled = !state.isLoading
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = viewModel::loginAsTeacher,
                modifier = Modifier.fillMaxWidth(),
                enabled = state.teacherName.isNotBlank() && !state.isLoading
            ) {
                if (state.isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text("Login as Teacher")
            }
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedButton(
                onClick = viewModel::loginAsGuest,
                modifier = Modifier.fillMaxWidth(),
                enabled = !state.isLoading,
                colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.primary)
            ) {
                Text("Continue as Guest")
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text("Limited features, no history", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
        }

        Text("Capstone Debate ©", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
    }
}
