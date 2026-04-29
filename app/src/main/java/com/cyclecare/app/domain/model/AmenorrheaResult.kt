package com.cyclecare.app.domain.model

import java.time.LocalDate

data class AmenorrheaResult(
    val severity: AmenorrheaSeverity,
    val daysSinceLastPeriod: Int,
    val lastPeriodDate: LocalDate?,
    val contributingFactors: List<String>,
    val recommendations: List<String>,
    val dismissed: Boolean = false
)

enum class AmenorrheaSeverity(
    val displayName: String,
    val description: String,
    val thresholdDays: Int
) {
    NONE(
        displayName = "Normal",
        description = "Your cycle is within normal range",
        thresholdDays = 0
    ),
    MILD(
        displayName = "Slightly Delayed",
        description = "Your period is a few days late",
        thresholdDays = 35
    ),
    MODERATE(
        displayName = "Delayed",
        description = "Your period is significantly delayed",
        thresholdDays = 60
    ),
    SEVERE(
        displayName = "Missed Period",
        description = "You have missed multiple cycles",
        thresholdDays = 90
    );
    
    companion object {
        fun fromDays(days: Int): AmenorrheaSeverity {
            return when {
                days >= SEVERE.thresholdDays -> SEVERE
                days >= MODERATE.thresholdDays -> MODERATE
                days >= MILD.thresholdDays -> MILD
                else -> NONE
            }
        }
    }
}
