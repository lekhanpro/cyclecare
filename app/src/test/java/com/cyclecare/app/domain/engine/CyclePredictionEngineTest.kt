package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.Period
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class CyclePredictionEngineTest {

    private val engine = CyclePredictionEngine()

    @Test
    fun `predicts next period for regular cycles`() {
        val periods = listOf(
            Period(startDate = LocalDate.of(2026, 3, 1), endDate = LocalDate.of(2026, 3, 5)),
            Period(startDate = LocalDate.of(2026, 2, 1), endDate = LocalDate.of(2026, 2, 5)),
            Period(startDate = LocalDate.of(2026, 1, 4), endDate = LocalDate.of(2026, 1, 8)),
            Period(startDate = LocalDate.of(2025, 12, 8), endDate = LocalDate.of(2025, 12, 12))
        )

        val prediction = engine.buildPrediction(periods, referenceDate = LocalDate.of(2026, 3, 10))

        assertNotNull(prediction)
        assertTrue(prediction!!.averageCycleLength in 27..29)
        assertTrue(prediction.confidenceScore > 0.7f)
        assertFalse(prediction.isIrregular)
    }

    @Test
    fun `handles irregular cycles with lower confidence`() {
        val periods = listOf(
            Period(startDate = LocalDate.of(2026, 3, 1), endDate = LocalDate.of(2026, 3, 6)),
            Period(startDate = LocalDate.of(2026, 1, 20), endDate = LocalDate.of(2026, 1, 24)),
            Period(startDate = LocalDate.of(2025, 12, 15), endDate = LocalDate.of(2025, 12, 19)),
            Period(startDate = LocalDate.of(2025, 11, 30), endDate = LocalDate.of(2025, 12, 4))
        )

        val prediction = engine.buildPrediction(periods, referenceDate = LocalDate.of(2026, 3, 10))

        assertNotNull(prediction)
        assertTrue(prediction!!.confidenceScore < 0.8f)
        assertTrue(prediction.variabilityScore < 0.8f)
    }
}
