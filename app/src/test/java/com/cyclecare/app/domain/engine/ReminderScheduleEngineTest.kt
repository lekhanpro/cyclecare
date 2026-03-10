package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.PredictionResult
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ReminderType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

class ReminderScheduleEngineTest {

    private val engine = ReminderScheduleEngine()

    @Test
    fun `schedules period reminder using prediction date`() {
        val now = ZonedDateTime.of(2026, 3, 10, 8, 0, 0, 0, ZoneId.of("UTC"))
        val reminder = Reminder(
            type = ReminderType.PERIOD,
            time = LocalTime.of(9, 0),
            daysBeforePeriod = 2
        )
        val prediction = PredictionResult(
            nextPeriodStart = LocalDate.of(2026, 3, 20),
            nextPeriodEnd = LocalDate.of(2026, 3, 24),
            ovulationDate = LocalDate.of(2026, 3, 6),
            fertileWindowStart = LocalDate.of(2026, 3, 1),
            fertileWindowEnd = LocalDate.of(2026, 3, 7),
            averageCycleLength = 28,
            averagePeriodLength = 5,
            variabilityScore = 0.8f,
            confidenceScore = 0.8f,
            isIrregular = false,
            cycleLengthStdDeviation = 2.1f
        )

        val trigger = engine.nextTrigger(reminder, prediction, now)

        assertNotNull(trigger)
        assertEquals(LocalDate.of(2026, 3, 18), trigger!!.toLocalDate())
    }

    @Test
    fun `respects quiet hours by shifting forward`() {
        val now = ZonedDateTime.of(2026, 3, 10, 20, 0, 0, 0, ZoneId.of("UTC"))
        val reminder = Reminder(
            type = ReminderType.DAILY_LOG,
            time = LocalTime.of(22, 30),
            quietHoursEnabled = true,
            quietHoursStart = LocalTime.of(22, 0),
            quietHoursEnd = LocalTime.of(7, 0)
        )

        val trigger = engine.nextTrigger(reminder, prediction = null, now = now)

        assertNotNull(trigger)
        assertEquals(7, trigger!!.hour)
    }
}
