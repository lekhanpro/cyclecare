package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(tableName = "daily_logs")
data class DailyLogEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val date: LocalDate,
    val mood: String?,
    val symptoms: List<String>,
    val temperature: Float?,
    val cervicalMucus: String?,
    val sexualActivity: Boolean,
    val waterIntake: Int,
    val sleepHours: Float?,
    val exerciseMinutes: Int,
    val notes: String
)
