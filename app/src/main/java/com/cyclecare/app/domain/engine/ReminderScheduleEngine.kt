package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.PredictionResult
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ReminderType
import java.time.ZoneId
import java.time.ZonedDateTime
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReminderScheduleEngine @Inject constructor() {

    fun nextTrigger(
        reminder: Reminder,
        prediction: PredictionResult?,
        now: ZonedDateTime = ZonedDateTime.now(),
        zoneId: ZoneId = now.zone
    ): ZonedDateTime? {
        if (!reminder.enabled) return null

        val baseDate = when (reminder.type) {
            ReminderType.PERIOD -> prediction?.nextPeriodStart?.minusDays(reminder.daysBeforePeriod.toLong())
            ReminderType.OVULATION -> prediction?.ovulationDate
            ReminderType.FERTILE_WINDOW -> prediction?.fertileWindowStart
            else -> now.toLocalDate()
        } ?: now.toLocalDate()

        var scheduled = ZonedDateTime.of(baseDate, reminder.time, zoneId)
        if (!scheduled.isAfter(now)) {
            scheduled = scheduled.plusDays(1)
        }

        while (isInQuietHours(scheduled, reminder)) {
            scheduled = scheduled.plusMinutes(30)
        }

        return scheduled
    }

    private fun isInQuietHours(time: ZonedDateTime, reminder: Reminder): Boolean {
        if (!reminder.quietHoursEnabled) return false
        val quietStart = reminder.quietHoursStart
        val quietEnd = reminder.quietHoursEnd
        val localTime = time.toLocalTime()

        if (quietStart == quietEnd) return false
        return if (quietStart < quietEnd) {
            localTime >= quietStart && localTime < quietEnd
        } else {
            localTime >= quietStart || localTime < quietEnd
        }
    }

    fun initialDelayMillis(
        now: ZonedDateTime,
        target: ZonedDateTime
    ): Long {
        return (target.toInstant().toEpochMilli() - now.toInstant().toEpochMilli()).coerceAtLeast(0)
    }

    fun oneDayFrom(now: ZonedDateTime): ZonedDateTime {
        return now.plusDays(1)
    }
}
