package com.debatefeedback.services

import com.debatefeedback.core.Constants
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class TimerService(private val speechDurationSeconds: Int) {
    enum class State { Idle, Running, Paused, Stopped }

    private val scope = CoroutineScope(Dispatchers.Main.immediate)
    private var tickerJob: Job? = null
    private var startTimeMillis: Long? = null
    private var pausedOffsetMillis: Long = 0
    private val bells = mutableListOf<Double>()
    private val firedBells = mutableSetOf<Int>()
    private var bellListener: ((Int) -> Unit)? = null

    private val _state = MutableStateFlow(State.Idle)
    val state: StateFlow<State> = _state

    private val _elapsedMillis = MutableStateFlow(0L)
    val elapsedMillis: StateFlow<Long> = _elapsedMillis

    init {
        scheduleBells()
    }

    fun onBell(listener: (Int) -> Unit) {
        bellListener = listener
    }

    fun start() {
        if (_state.value == State.Running) return
        firedBells.clear()
        startTimeMillis = System.currentTimeMillis() - pausedOffsetMillis
        tickerJob?.cancel()
        tickerJob = scope.launch {
            _state.value = State.Running
            while (isActive && _state.value == State.Running) {
                val elapsed = ((System.currentTimeMillis() - (startTimeMillis ?: System.currentTimeMillis())).coerceAtLeast(0))
                _elapsedMillis.value = elapsed
                checkBells()
                delay(1000L / Constants.Timer.DISPLAY_REFRESH_FPS)
            }
        }
    }

    fun pause() {
        if (_state.value != State.Running) return
        pausedOffsetMillis = _elapsedMillis.value
        tickerJob?.cancel()
        _state.value = State.Paused
    }

    fun resume() {
        if (_state.value != State.Paused) return
        start()
    }

    fun stop() {
        tickerJob?.cancel()
        _state.value = State.Stopped
    }

    fun reset() {
        tickerJob?.cancel()
        _state.value = State.Idle
        _elapsedMillis.value = 0
        startTimeMillis = null
        pausedOffsetMillis = 0
        firedBells.clear()
    }

    fun ringBellManually() {
        bellListener?.invoke(1)
    }

    val durationSeconds: Int get() = speechDurationSeconds

    private fun scheduleBells() {
        bells.clear()
        if (speechDurationSeconds >= 60) bells += Constants.Audio.FIRST_BELL
        if (speechDurationSeconds >= 120) bells += (speechDurationSeconds - 60).toDouble()
        bells += speechDurationSeconds.toDouble()
        var overtime = speechDurationSeconds + Constants.Audio.OVERTIME_BELL_INTERVAL
        repeat(20) {
            bells += overtime.toDouble()
            overtime += Constants.Audio.OVERTIME_BELL_INTERVAL
        }
    }

    private fun checkBells() {
        val elapsedSeconds = _elapsedMillis.value / 1000.0
        bells.forEachIndexed { index, bellTime ->
            if (elapsedSeconds >= bellTime && firedBells.add(index)) {
                val count = when {
                    bellTime == Constants.Audio.FIRST_BELL || bellTime == speechDurationSeconds - 60.0 -> 1
                    bellTime == speechDurationSeconds.toDouble() -> 2
                    bellTime > speechDurationSeconds -> 3
                    else -> 1
                }
                bellListener?.invoke(count)
            }
        }
    }

    fun formattedTime(): String {
        val totalSeconds = (_elapsedMillis.value / 1000).toInt()
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d", minutes, seconds)
    }

    val isOvertime: Boolean get() = _elapsedMillis.value / 1000 > speechDurationSeconds

    val progress: Double get() = (_elapsedMillis.value / 1000.0) / speechDurationSeconds.toDouble()
}
