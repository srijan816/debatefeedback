package com.debatefeedback.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.debatefeedback.LocalAppContainer
import com.debatefeedback.ui.auth.AuthScreen
import com.debatefeedback.ui.feedback.FeedbackDetailScreen
import com.debatefeedback.ui.feedback.FeedbackListScreen
import com.debatefeedback.ui.history.HistoryScreen
import com.debatefeedback.ui.setup.SetupScreen
import com.debatefeedback.ui.timer.TimerScreen

object Routes {
    const val AUTH = "auth"
    const val SETUP = "setup"
    const val TIMER = "timer/{sessionId}"
    const val FEEDBACK = "feedback/{sessionId}"
    const val FEEDBACK_DETAIL = "feedback/{sessionId}/{recordingId}"
    const val HISTORY = "history"
}

@Composable
fun DebateFeedbackApp() {
    val container = LocalAppContainer.current
    val navController = rememberNavController()
    val isGuest by container.sessionManager.isGuestMode.collectAsState()
    val token by container.sessionManager.authToken.collectAsState()

    LaunchedEffect(token, isGuest) {
        val startDestination = if (!token.isNullOrBlank() || isGuest) Routes.SETUP else Routes.AUTH
        if (navController.currentDestination?.route == null) {
            navController.navigate(startDestination) {
                popUpTo(0)
                launchSingleTop = true
            }
        }
    }

    NavHost(navController = navController, startDestination = Routes.AUTH) {
        composable(Routes.AUTH) {
            AuthScreen(
                onAuthenticated = {
                    navController.navigate(Routes.SETUP) {
                        popUpTo(Routes.AUTH) { inclusive = true }
                    }
                }
            )
        }
        composable(Routes.SETUP) {
            SetupScreen(
                onStartTimer = { sessionId ->
                    navController.navigate("timer/$sessionId")
                },
                onViewHistory = {
                    navController.navigate(Routes.HISTORY)
                },
                onLogout = {
                    navController.navigate(Routes.AUTH) {
                        popUpTo(Routes.AUTH) { inclusive = true }
                    }
                }
            )
        }
        composable(
            route = Routes.TIMER,
            arguments = listOf(navArgument("sessionId") { type = NavType.StringType })
        ) { backStackEntry ->
            val sessionId = backStackEntry.arguments?.getString("sessionId") ?: return@composable
            TimerScreen(
                sessionId = sessionId,
                onViewFeedback = { navController.navigate("feedback/$sessionId") },
                onBack = { navController.popBackStack() }
            )
        }
        composable(
            route = Routes.FEEDBACK,
            arguments = listOf(navArgument("sessionId") { type = NavType.StringType })
        ) { backStackEntry ->
            val sessionId = backStackEntry.arguments?.getString("sessionId") ?: return@composable
            FeedbackListScreen(
                sessionId = sessionId,
                onBack = { navController.popBackStack() },
                onOpenRecording = { recordingId ->
                    navController.navigate("feedback/$sessionId/$recordingId")
                },
                onDone = {
                    navController.navigate(Routes.SETUP) {
                        popUpTo(Routes.SETUP) { inclusive = false }
                    }
                }
            )
        }
        composable(
            route = Routes.FEEDBACK_DETAIL,
            arguments = listOf(
                navArgument("sessionId") { type = NavType.StringType },
                navArgument("recordingId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val sessionId = backStackEntry.arguments?.getString("sessionId") ?: return@composable
            val recordingId = backStackEntry.arguments?.getString("recordingId") ?: return@composable
            FeedbackDetailScreen(
                sessionId = sessionId,
                recordingId = recordingId,
                onBack = { navController.popBackStack() }
            )
        }
        composable(Routes.HISTORY) {
            HistoryScreen(onBack = { navController.popBackStack() })
        }
    }
}
