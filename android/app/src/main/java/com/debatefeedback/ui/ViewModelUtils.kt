package com.debatefeedback.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.compose.LocalViewModelStoreOwner

@Composable
inline fun <reified VM : ViewModel> rememberViewModel(noinline factory: () -> VM): VM {
    val owner = LocalViewModelStoreOwner.current ?: error("No ViewModelStoreOwner provided")
    val providerFactory = remember(factory) {
        object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return factory.invoke() as T
            }
        }
    }
    return viewModel(owner, factory = providerFactory)
}
