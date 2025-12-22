package com.debatefeedback.domain.model

import kotlinx.serialization.Serializable

@Serializable
data class TeamComposition(
    val prop: List<String>? = null,
    val opp: List<String>? = null,
    val og: List<String>? = null,
    val oo: List<String>? = null,
    val cg: List<String>? = null,
    val co: List<String>? = null
) {
    fun speakerOrder(format: DebateFormat): List<SpeakerSlot> = when (format) {
        DebateFormat.WSDC, DebateFormat.MODIFIED_WSDC, DebateFormat.AUSTRALS -> {
            val speakers = mutableListOf<SpeakerSlot>()
            val propSpeakers = prop.orEmpty()
            val oppSpeakers = opp.orEmpty()
            val max = maxOf(propSpeakers.size, oppSpeakers.size)
            for (index in 0 until max) {
                if (index < propSpeakers.size) {
                    speakers += SpeakerSlot(propSpeakers[index], "Prop ${index + 1}")
                }
                if (index < oppSpeakers.size) {
                    speakers += SpeakerSlot(oppSpeakers[index], "Opp ${index + 1}")
                }
            }
            speakers
        }
        DebateFormat.BP -> buildList {
            og.orEmpty().forEachIndexed { index, id -> add(SpeakerSlot(id, "OG ${index + 1}")) }
            oo.orEmpty().forEachIndexed { index, id -> add(SpeakerSlot(id, "OO ${index + 1}")) }
            cg.orEmpty().forEachIndexed { index, id -> add(SpeakerSlot(id, "CG ${index + 1}")) }
            co.orEmpty().forEachIndexed { index, id -> add(SpeakerSlot(id, "CO ${index + 1}")) }
        }
        DebateFormat.AP -> {
            val result = mutableListOf<SpeakerSlot>()
            val govSpeakers = prop.orEmpty()
            val oppSpeakers = opp.orEmpty()
            val max = maxOf(govSpeakers.size, oppSpeakers.size)
            for (index in 0 until max) {
                if (index < govSpeakers.size) result += SpeakerSlot(govSpeakers[index], "Gov ${index + 1}")
                if (index < oppSpeakers.size) result += SpeakerSlot(oppSpeakers[index], "Opp ${index + 1}")
            }
            result
        }
    }
}

data class SpeakerSlot(
    val studentId: String,
    val position: String
)
