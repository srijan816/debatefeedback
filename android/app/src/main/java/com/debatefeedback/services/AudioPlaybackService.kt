package com.debatefeedback.services

import android.content.Context
import android.media.MediaPlayer
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.File

class AudioPlaybackService(private val context: Context) {
    private var mediaPlayer: MediaPlayer? = null
    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying

    private val _currentPosition = MutableStateFlow(0)
    val currentPosition: StateFlow<Int> = _currentPosition

    private val _duration = MutableStateFlow(0)
    val duration: StateFlow<Int> = _duration

    fun play(file: File, startPosition: Int = 0) {
        stop()
        mediaPlayer = MediaPlayer().apply {
            setDataSource(file.absolutePath)
            setOnPreparedListener {
                _duration.value = it.duration
                seekTo(startPosition)
                start()
                _isPlaying.value = true
                monitorProgress()
            }
            setOnCompletionListener {
                _isPlaying.value = false
                _currentPosition.value = 0
            }
            prepareAsync()
        }
    }

    fun pause() {
        mediaPlayer?.takeIf { it.isPlaying }?.pause()
        _isPlaying.value = false
    }

    fun resume() {
        mediaPlayer?.start()
        _isPlaying.value = true
        monitorProgress()
    }

    fun stop() {
        mediaPlayer?.release()
        mediaPlayer = null
        _isPlaying.value = false
        _currentPosition.value = 0
        _duration.value = 0
    }

    fun seekTo(position: Int) {
        mediaPlayer?.seekTo(position)
        _currentPosition.value = position
    }

    private fun monitorProgress() {
        val player = mediaPlayer ?: return
        context.mainExecutor.execute {
            if (player.isPlaying) {
                _currentPosition.value = player.currentPosition
                monitorProgress()
            }
        }
    }
}
