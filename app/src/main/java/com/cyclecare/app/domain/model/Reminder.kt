package com.cyclecare.app.domain.model

import java.time.LocalTime

data class Reminder(
    val id: Long = 0,
    val type: ReminderType,
    val time: LocalTime,
    val enabled: Boolean = true,
    val daysBeforePeriod: Int = 3,
    val quietHoursEnabled: Boolean = false,
    val quietHoursStart: LocalTime = LocalTime.of(22, 0),
    val quietHoursEnd: LocalTime = LocalTime.of(7, 0),
    val title: String = "",
    val message: String = ""
)

enum class ReminderType {
    PERIOD,
    OVULATION,
    FERTILE_WINDOW,
    DAILY_LOG,
    PILL,
    MEDICATION,
    HYDRATION,
    WEIGHT,
    TEMPERATURE,
    BODY_METRICS,
    PREGNANCY_TEST,
    OVULATION_TEST,
    CUSTOM
}
