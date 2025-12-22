package com.debatefeedback

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import com.debatefeedback.ui.DebateFeedbackApp
import com.debatefeedback.ui.theme.DebateFeedbackTheme

val LocalAppContainer = androidx.compose.runtime.staticCompositionLocalOf<AppContainer> {
    error("AppContainer not provided")
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val container = (application as DebateFeedbackApplication).container
        setContent {
            CompositionLocalProvider(LocalAppContainer provides container) {
                DebateFeedbackTheme {
                    DebateFeedbackApp()
                }
            }
        }
    }
}
