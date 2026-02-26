package com.cyclecare.app.domain.model

import java.time.LocalTime

data class Reminder(
    val id: Long = 0,
    val type: ReminderType,
    val time: LocalTime,
    val enabled: Boolean = true,
    val daysBeforePeriod: Int = 3,
    val title: String = "",
    val message: String = ""
)

enum class ReminderType {
    PERIOD,
    OVULATION,
    FERTILE_WINDOW,
    DAILY_LOG,
    PILL,
    CUSTOM
}
