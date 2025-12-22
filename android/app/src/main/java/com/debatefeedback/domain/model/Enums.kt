package com.debatefeedback.domain.model

enum class StudentLevel(val displayName: String) {
    PRIMARY("Primary"),
    SECONDARY("Secondary");

    companion object {
        fun fromRaw(raw: String?): StudentLevel = entries.firstOrNull { it.name.equals(raw, true) }
            ?: SECONDARY
    }
}

enum class DebateFormat(val displayName: String) {
    WSDC("WSDC"),
    MODIFIED_WSDC("Modified WSDC"),
    BP("BP"),
    AP("AP"),
    AUSTRALS("Australs");

    val defaultSpeechTime: Int
        get() = when (this) {
            WSDC -> 480
            MODIFIED_WSDC -> 240
            BP -> 420
            AP -> 360
            AUSTRALS -> 480
        }

    val hasReplySpeeches: Boolean
        get() = when (this) {
            BP, AP -> false
            else -> true
        }

    val defaultReplyTime: Int?
        get() = when (this) {
            WSDC -> 240
            MODIFIED_WSDC -> 120
            AUSTRALS -> 180
            else -> null
        }

    val teamStructure: TeamStructure
        get() = when (this) {
            WSDC, MODIFIED_WSDC, AUSTRALS -> TeamStructure.PropOpp
            BP -> TeamStructure.BritishParliamentary
            AP -> TeamStructure.AsianParliamentary
        }

    companion object {
        fun fromRaw(raw: String?): DebateFormat = entries.firstOrNull { it.displayName.equals(raw, true) || it.name.equals(raw, true) }
            ?: WSDC
    }
}

enum class TeamStructure {
    PropOpp,
    BritishParliamentary,
    AsianParliamentary
}
