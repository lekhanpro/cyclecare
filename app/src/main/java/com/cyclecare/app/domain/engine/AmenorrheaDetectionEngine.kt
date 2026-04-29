package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.AmenorrheaResult
import com.cyclecare.app.domain.model.AmenorrheaSeverity
import com.cyclecare.app.domain.model.DailyLog
import com.cyclecare.app.domain.model.Period
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AmenorrheaDetectionEngine @Inject constructor() {

    fun detectAmenorrhea(
        periods: List<Period>,
        recentLogs: List<DailyLog>,
        isPregnant: Boolean = false,
        isBreastfeeding: Boolean = false,
        isMenopause: Boolean = false
    ): AmenorrheaResult? {
        // Don't alert if in pregnancy, breastfeeding, or menopause mode
        if (isPregnant || isBreastfeeding || isMenopause) {
            return null
        }
        
        val lastPeriod = periods.maxByOrNull { it.startDate } ?: return null
        val daysSinceLastPeriod = ChronoUnit.DAYS.between(lastPeriod.startDate, LocalDate.now()).toInt()
        
        val severity = AmenorrheaSeverity.fromDays(daysSinceLastPeriod)
        
        if (severity == AmenorrheaSeverity.NONE) {
            return null
        }
        
        val contributingFactors = analyzeContributingFactors(recentLogs, daysSinceLastPeriod)
        val recommendations = generateRecommendations(severity, contributingFactors)
        
        return AmenorrheaResult(
            severity = severity,
            daysSinceLastPeriod = daysSinceLastPeriod,
            lastPeriodDate = lastPeriod.startDate,
            contributingFactors = contributingFactors,
            recommendations = recommendations
        )
    }
    
    private fun analyzeContributingFactors(logs: List<DailyLog>, daysSince: Int): List<String> {
        val factors = mutableListOf<String>()
        
        // Analyze stress levels from mood logs
        val stressfulMoods = logs.count { 
            it.mood?.lowercase() in listOf("stressed", "anxious", "overwhelmed")
        }
        if (stressfulMoods > logs.size * 0.3) {
            factors.add("High stress levels detected")
        }
        
        // Analyze weight changes
        val weights = logs.mapNotNull { it.weightKg }
        if (weights.size >= 2) {
            val weightChange = weights.last() - weights.first()
            val percentChange = (weightChange / weights.first()) * 100
            if (percentChange > 10) {
                factors.add("Significant weight gain detected")
            } else if (percentChange < -10) {
                factors.add("Significant weight loss detected")
            }
        }
        
        // Analyze exercise patterns
        val highExerciseDays = logs.count { it.exerciseMinutes > 90 }
        if (highExerciseDays > logs.size * 0.5) {
            factors.add("Intense exercise routine")
        }
        
        // Check for PCOS-related symptoms
        val pcosSymptoms = logs.flatMap { it.symptoms }.count { symptom ->
            symptom.lowercase() in listOf("acne", "hair growth", "weight gain")
        }
        if (pcosSymptoms > 5) {
            factors.add("PCOS-related symptoms present")
        }
        
        return factors
    }
    
    private fun generateRecommendations(
        severity: AmenorrheaSeverity,
        factors: List<String>
    ): List<String> {
        val recommendations = mutableListOf<String>()
        
        when (severity) {
            AmenorrheaSeverity.MILD -> {
                recommendations.add("Monitor for a few more days")
                recommendations.add("Consider taking a pregnancy test if sexually active")
                recommendations.add("Track any unusual symptoms")
            }
            AmenorrheaSeverity.MODERATE -> {
                recommendations.add("Take a pregnancy test if sexually active")
                recommendations.add("Schedule a consultation with your healthcare provider")
                recommendations.add("Continue tracking symptoms and patterns")
            }
            AmenorrheaSeverity.SEVERE -> {
                recommendations.add("Consult a healthcare provider as soon as possible")
                recommendations.add("Take a pregnancy test if you haven't already")
                recommendations.add("Bring your cycle tracking data to your appointment")
            }
            AmenorrheaSeverity.NONE -> {
                // No recommendations needed
            }
        }
        
        // Add factor-specific recommendations
        if (factors.any { it.contains("stress", ignoreCase = true) }) {
            recommendations.add("Practice stress management techniques")
        }
        if (factors.any { it.contains("weight", ignoreCase = true) }) {
            recommendations.add("Discuss weight changes with your doctor")
        }
        if (factors.any { it.contains("exercise", ignoreCase = true) }) {
            recommendations.add("Consider moderating exercise intensity")
        }
        if (factors.any { it.contains("PCOS", ignoreCase = true) }) {
            recommendations.add("Discuss PCOS screening with your healthcare provider")
        }
        
        return recommendations
    }
}
